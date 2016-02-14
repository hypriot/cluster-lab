#!/bin/bash

cleanupdocker() {
echo "cleanup docker container"
if [ -f "/usr/local/bin/cluster.yml" ];then
docker-compose -f /usr/local/bin/cluster.yml kill
docker-compose -f /usr/local/bin/cluster.yml rm -f
rm -f ./usr/local/bin/cluster.yml
fi

echo "reset docker config"
if [ -f "/etc/default/docker_bak" ]; then
rm -f /etc/default/docker
mv /etc/default/docker_bak /etc/default/docker
fi
}

cleanupdhcp () {
echo "cleanup dnsmasq dhcp server"
if [ -f "/etc/dnsmasq.conf_bak" ];then
systemctl stop dnsmasq.service
rm -f /etc/dnsmasq.conf
mv /etc/dnsmasq.conf_bak /etc/dnsmasq.conf
fi
}

cleanupavahi () {
echo "reset avahi daemon"
if [ -f "/etc/avahi/services/cluster-master.service" ];then
rm /etc/avahi/services/cluster-master.service
sed -i -e 's/deny-interfaces=eth1,eth0,wlan0,docker0/#deny-interfaces=eth1/' /etc/avahi/avahi-daemon.conf
sed -i -e 's/allow-interfaces=eth0.200/#allow-interfaces=eth0/' /etc/avahi/avahi-daemon.conf
sed -i -e 's/use-ipv6=no/use-ipv6=yes/' /etc/avahi/avahi-daemon.conf
   
echo "restart avahi with old config"
systemctl restart avahi-daemon.service   
fi
}

cleanupvlan () {
echo "deleting existing vlan interface"
ip link delete dev eth0.200 type vlan
}

###################################
#                                 #
#     M A I N   P R O G R A M     #
#                                 #
###################################

# Run this script as sudo!

cleanupdocker
cleanupdhcp
cleanupavahi
cleanupvlan

