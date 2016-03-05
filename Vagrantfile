# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.network "private_network", type: "dhcp"

  config.vm.define "leader" do |leader|
    leader.vm.box = "ubuntu/wily64"
    leader.vm.hostname = 'leader'
  end

  config.vm.define "follower1" do |follower1|
    follower1.vm.box = "ubuntu/wily64"
    follower1.vm.hostname = 'follower1'
  end

  config.vm.define "follower2" do |follower2|
    follower2.vm.box = "ubuntu/wily64"
    follower2.vm.hostname = 'follower2'
  end

  config.vm.synced_folder ".", "/cluster-lab-src"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    # install Docker
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y linux-image-extra-$(uname -r)
    apt-get install -y docker-engine

    # install Cluster Lab dependencies
    apt-get install -y avahi-daemon vlan avahi-utils dnsmasq

    # build Cluster Lab debian package from current repository
    cd /cluster-lab-src && ./build.sh

    # install Cluster Lab debian package
    dpkg -i ./hypriot-cluster-lab-src_0.1.1-1.deb
  SHELL
end
