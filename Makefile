default: build

build:
	docker build -t deb-builder .

deb: build
	docker run --rm --privileged -v $(shell pwd):/workspace -e TRAVIS_TAG -e VERSION deb-builder

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace -e TRAVIS_TAG -e VERSION deb-builder bash

shellcheck: build
	VERSION=dirty docker run --rm -ti -v $(shell pwd):/workspace deb-builder bash -c 'shellcheck /workspace/package/usr/local/lib/cluster-lab/*_lib /workspace/package/usr/local/bin/cluster-lab'

vagrant:
	cd ./vagrant/ ; \
	vagrant up ; \
	cd -

docker-machine: vagrant
	cd ./vagrant/ ; \
	docker-machine create -d generic \
	  --generic-ssh-user $(shell vagrant ssh-config | grep ' User ' | cut -d ' ' -f 4) \
	  --generic-ssh-key $(shell vagrant ssh-config | grep IdentityFile | cut -d ' ' -f 4) \
	  --generic-ip-address $(shell vagrant ssh-config | grep HostName | cut -d ' ' -f 4) \
	  --generic-ssh-port $(shell vagrant ssh-config | grep Port | cut -d ' ' -f 4) \
	  deb-builder ; \
	cd -

tag:
	git tag ${TAG}
	git push origin ${TAG}

.PHONY: vagrant
