#!/usr/bin/env bash

# install Docker and dependencies
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y linux-image-extra-"$(uname -r)"
apt-get install -y docker-engine

# install Docker-Compose
apt-get install -y docker-compose

# create systemd configuration
systemctl stop docker
cp -f /cluster-lab-src/vagrant/docker.service /lib/systemd/system/

# configure Docker to use overlay filesystem
echo "DOCKER_OPTS='-s overlay'" >> /etc/default/docker

systemctl daemon-reload
systemctl start docker

# install Cluster Lab dependencies
apt-get install -y avahi-daemon vlan avahi-utils dnsmasq

# build Cluster Lab debian package from current repository
cd /cluster-lab-src/vagrant && ./build.sh

# install Cluster Lab debian package

# stop cluster-lab if it exists
command -v cluster-lab >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
  cluster-lab stop
fi
dpkg --force-confnew -i ./hypriot-cluster-lab-src_0.1.1-1.deb

# start Cluster Lab
cluster-lab start
