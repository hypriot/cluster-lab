# repo name
OUTPUT_NAME ?= $(shell basename `git rev-parse --show-toplevel`)

DATE := $(shell date +"%Y-%m-%d_%H%M")
COMMIT_HASH := $(shell git rev-parse --short HEAD)

VERSION :=$(shell cat VERSION)

# cuts of the first char (here e.g. v0.4 -> 0.4)
STRIP_VERSION :=$(shell cat VERSION | cut -c 2-)

PACKAGE_RELEASE_VERSION = $(DRONE_BUILD_NUMBER)
PACKAGE_RELEASE_VERSION ?= 1

PACKAGE_VERSION=$(STRIP_VERSION)-$(PACKAGE_RELEASE_VERSION)

PACKAGE_NAME="$(OUTPUT_NAME)_$(PACKAGE_VERSION)"

DESCRIPTION :=$(shell cat DESCRIPTION)

# url/s3 path to download from
DOWNLOADPATH := $(shell cat DOWNLOADPATH)
# folder to locally save the results
BUILD_DIR := $(BUILD_RESULTS)/$(OUTPUT_NAME)/$(DATE)_$(COMMIT_HASH)

# example for creating a Docker image
#default: download_from_S3 download_from_http extract dockerbuild dockersave dockerpush 
# example for creating a binary 
#default: compile copy_binary_to_upload_folder build_debian_package upload_to_packagecloud

download_from_S3:
	aws s3 cp s3://$(AWS_BUCKET)/$(DOWNLOADPATH) ./binary.tar.gz

download_from_http:
	curl -L $(DOWNLOADPATH) > ./binary.tar.gz

# extract downloaded tar archives to content/
extract:
	mkdir content/
	tar xzf binary.tar.gz -C content/
	ls -la content/

# build a docker image
dockerbuild:
	mkdir -p $(BUILD_RESULTS)
	docker rmi -f $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME) || true
	docker build -t $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME) .

# push the docker image to a docker registry
dockerpush:
	# push VERSION
	docker tag -f $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(VERSION)
	docker push $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(VERSION)

	# push DATE COMMIT_HASH
	docker tag -f $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(DATE)_$(COMMIT_HASH)
	docker push $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(DATE)_$(COMMIT_HASH)
	
	# push latest
	docker tag -f $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest
	docker push $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest

	# remove tags
	docker rmi $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(VERSION) || true
	docker rmi $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):$(DATE)_$(COMMIT_HASH) || true
	docker rmi $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest || true

# save the image as tar
dockersave:
	mkdir -p $(BUILD_DIR)/
	docker save --output="$(BUILD_DIR)/$(OUTPUT_NAME).tar" $(REGISTRY_NAMESPACE)/$(OUTPUT_NAME):latest

# upload the created debian package to packagecloud
upload_to_packagecloud:
	echo "upload debian package to package cloud"
	# see documentation for this api call at https://packagecloud.io/docs/api#resource_packages_method_create
	curl -X POST https://$(PACKAGECLOUD_API_TOKEN):@packagecloud.io/api/v1/repos/$(PACKAGECLOUD_USER_REPO)/packages.json \
	-F "package[distro_version_id]=24" -F "package[package_file]=@$(BUILD_DIR)/package/$(PACKAGE_NAME).deb"

copy_binary_to_upload_folder:
	mkdir -p $(BUILD_DIR)/binary/
	cp $(OUTPUT_NAME) $(BUILD_DIR)/binary/
	cd $(BUILD_DIR)/binary/ && shasum -a 256 $(OUTPUT_NAME) > $(OUTPUT_NAME).sha256
	BINARY_SIZE = $(shell stat -c %s $(BUILD_DIR)/binary/$(OUTPUT_NAME))

copy_deb_to upload_folder:
	pwd && ls -la .
	cp -r builds/* $(BUILD_DIR)/package/

create_sha256_checksums:
	echo create checksums
	find_files = $(notdir $(wildcard $(BUILD_DIR)/package/*))
	echo $(foreach dir,$(find_files),$(shell cd $(BUILD_DIR)/package && shasum -a 256 $(dir) >> $(dir).sha256))

build_debian_package:
	echo "build debian package"
	mkdir -p $(BUILD_DIR)/package/$(PACKAGE_NAME)/DEBIAN $(BUILD_DIR)/package/$(PACKAGE_NAME)/usr/local/bin

	# copy package control template and replace version info
	echo -e "Package: <NAME>\nVersion: <VERSION>\nSection: admin\nPriority: optional\nArchitecture: armhf\nEssential: no\nInstalled-Size: <SIZE>\nMaintainer: blog.hypriot.com\nDescription: <DESCRIPTION>" > $(BUILD_DIR)/package/$(PACKAGE_NAME)/DEBIAN/control
	sed -i'' "s/<VERSION>/$(PACKAGE_VERSION)/g" $(BUILD_DIR)/package/$(PACKAGE_NAME/DEBIAN/control
	sed -i'' "s/<NAME>/$(OUTPUT_NAME)/g" $(BUILD_DIR)/package/$(PACKAGE_NAME/DEBIAN/control
	sed -i'' "s/<SIZE>/$(BINARY_SIZE)/g" $(BUILD_DIR)/package/$(PACKAGE_NAME/DEBIAN/control
	sed -i'' "s/<DESCRIPTION>/$(DESCRIPTION)/g" $(BUILD_DIR)/package/$(PACKAGE_NAME/DEBIAN/control

	# copy consul binary to destination
	cp $(BUILD_DIR)/binary/$(OUTPUT_NAME) $(BUILD_DIR)/package/$(PACKAGE_NAME)/usr/local/bin

	# actually create package with dpkg-deb
	cd $(BUILD_DIR)/package && 	dpkg-deb --build $(PACKAGE_NAME)

	# remove temporary folder with source package artifacts as they should not be uploaded to AWS S3
	rm -R $(BUILD_DIR)/package/$(PACKAGE_NAME)

