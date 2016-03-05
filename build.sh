#!/bin/bash
DESCRIPTION="HyprIoT Cluster Lab"
DEPENDENCIES="avahi-utils, vlan, dnsmasq"
BUILD_DIR=.

VERSION="$(cat VERSION)"
PACKAGE_VERSION=${VERSION}-${1:-"1"}

REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
PROJECT_NAME=hypriot-${REPO_NAME}
PACKAGE_NAME="${PROJECT_NAME}_${PACKAGE_VERSION}"
TIMESTAMP="$(date +"%Y-%m-%d_%H%M")"
COMMIT="$(git rev-parse --short HEAD)"

rm -f ${BUILD_DIR}/${PACKAGE_NAME}.deb

mkdir -p ${BUILD_DIR}/${PACKAGE_NAME}
cp -r package/* ${BUILD_DIR}/${PACKAGE_NAME}/
sed -i'' "s/<VERSION>/${PACKAGE_VERSION}/g" ${BUILD_DIR}/${PACKAGE_NAME}/DEBIAN/control
sed -i'' "s/<NAME>/${PROJECT_NAME}/g" ${BUILD_DIR}/${PACKAGE_NAME}/DEBIAN/control
sed -i'' "s/<SIZE>/60/g" ${BUILD_DIR} /${PACKAGE_NAME}/DEBIAN/control
sed -i'' "s/<DESCRIPTION>/${DESCRIPTION}/g" ${BUILD_DIR}/${PACKAGE_NAME}/DEBIAN/control
sed -i'' "s/<DEPENDS>/${DEPENDENCIES}/g" ${BUILD_DIR}/${PACKAGE_NAME}/DEBIAN/control

cd ${BUILD_DIR} && dpkg-deb --build ${PACKAGE_NAME}
cd -
rm -rf ${BUILD_DIR}/${PACKAGE_NAME}
