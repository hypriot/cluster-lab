#!/bin/bash

checkconnectivity(){
# Do not proceed until ping to 8.8.8.8 is successful
while ! ping -c 1 8.8.8.8 &> /dev/null
do
  echo Ping to IP address 8.8.8.8 was not successful. Retrying...
  sleep 3
done

echo Ping to IP address 8.8.8.8 was successful.

echo Updating time not that I am online...
ntpdate -u pool.ntp.org

}

prepare () {

echo "update package lists"
currenttime=$(date +"%s")
updatetime=$(stat -c %Y /var/cache/apt/)

delta=`expr $currenttime - $updatetime`
timeout=`expr 60 \* 60`

if [ $delta > $timeout ]; then
apt-get update -qq
fi

echo "install required packages"
apt-get install -yqq vlan avahi-utils
}

createvlan () {
echo "create vlan with tag 200 on eth0"
ip link add link eth0 name eth0.200 type vlan id 200
ip link set dev eth0.200 up
}

setip () {
if [ -n "${1}" ]; then
IP=${1}
else
IP=${DEFAULTMASTERIP}
fi

echo "set ip address on vlan 200"
ip addr add ${IP}/24 dev eth0.200
ip link set dev eth0.200 up
}

getip () {
echo "get ip address from DHCP"
ip link set dev eth0.200 up
dhclient -v eth0.200
}

configavahi () {
echo "configure avahi only on eth0.200 \(vlan with id 200\)"
sed -i -e 's/#deny-interfaces=eth1/deny-interfaces=eth1,eth0,wlan0,docker0/' /etc/avahi/avahi-daemon.conf
sed -i -e 's/#allow-interfaces=eth0/allow-interfaces=eth0.200/' /etc/avahi/avahi-daemon.conf
sed -i -e 's/use-ipv6=yes/use-ipv6=no/' /etc/avahi/avahi-daemon.conf
}

createavahiclusterservice () {
echo "create avahi cluster-master"
cat << EOM > /etc/avahi/services/cluster-master.service
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Cluster-Master=%h</name>
  <service>
    <type>_cluster._tcp</type>
    <port>22</port>
    <txt-record>os-release=hypriot</txt-record>
  </service>
</service-group>
EOM
}

configdhcp () {
echo "setup dnsmasq dhcp server"

# check if dnsmasq is installed
dnsmasq=$(dpkg -l dnsmasq &> /dev/null)
exit_dnsmasq=$?
if [ "$exit_dnsmasq" == "1" ]; then
apt-get install -yqq --force-yes dnsmasq
fi


# if file backup exists do not override!
if [ ! -f "/etc/dnsmasq.conf_bak" ]; then
cp /etc/dnsmasq.conf /etc/dnsmasq.conf_bak
fi
cat << EOM > /etc/dnsmasq.conf

# set domain name
domain=hypriot.cluster

interface=eth0.200

# general DHCP stuff (see RFC 2132)
#
# 1:  subnet masq
# 3:  default router
# 6:  DNS server
# 12: hostname
# 15: DNS domain (unneeded with option 'domain')
# 28: broadcast address
# 42: time server
#

dhcp-authoritative
dhcp-leasefile=/var/lib/misc/dnsmasq.leases
dhcp-option=1,255.255.255.0
dhcp-option=28,192.168.200.255

# dynamic DHCP range with a 2 hour lease
#
dhcp-range=192.168.200.101,192.168.200.200,2h

EOM

echo "restart dnsmasq with new config"
systemctl restart dnsmasq.service
}

configdocker () {
echo "make backup of /etc/default docker"
# if file backup exists do not override!
if [ ! -f "/etc/default/docker_bak" ]; then
cp /etc/default/docker /etc/default/docker_bak
fi

echo "change config with new options for libnetwork introduced in docker 1.9"
cat << EOM > /etc/default/docker
DOCKER_OPTS="--storage-driver=overlay -D -H tcp://${SELFIP}:2375 --cluster-advertise ${SELFIP}:2375 --cluster-store consul://${SELFIP}:8500"
EOM

echo "restart docker with new config"
systemctl restart docker.service
}


composeyml () {
echo "create docker compose for consul"
cat << EOM > /usr/local/bin/cluster.yml
swarm:
  image: hypriot/rpi-swarm
  command: join --advertise ${SELFIP}:2375 consul://${SELFIP}:8500/dc1

consul:
  image: hypriot/rpi-consul:0.6.0
  restart: always
  ports:
    - ${SELFIP}:8400:8400
    - ${SELFIP}:8500:8500
    - ${SELFIP}:8600:8600
    - ${SELFIP}:8301:8301
    - ${SELFIP}:8302:8302
  net: host
EOM

if [ "$MASTERorSLAVE" == "master" ]; then
cat << EOM >> /usr/local/bin/cluster.yml
  command: agent -server -rejoin -data-dir /data -ui-dir /ui -bind ${SELFIP} -client 0.0.0.0 -bootstrap-expect 1

swarmmanage:
  image: hypriot/rpi-swarm
  ports:
    - 2378:2375
  command: manage consul://${SELFIP}:8500/dc1
EOM

elif [ "$MASTERorSLAVE" == "slave" ]; then
cat << EOM >> /usr/local/bin/cluster.yml
  command: agent -server -rejoin -data-dir /data -ui-dir /ui -bind ${SELFIP} -client 0.0.0.0 -join ${CLUSTERMASTERIP}:8301
EOM
fi

echo "start consul and swarm container"
docker-compose -f /usr/local/bin/cluster.yml up -d
}

fixrouting () {
# update routes
if [ -n "$(ip route | grep default | grep '192.168.200')" ]; then
ip route del default dev eth0.200
dhclient eth0
fi
}


###################################
#                                 #
#     M A I N   P R O G R A M     #
#                                 #
###################################

# Run this script as sudo!

# variables
DEFAULTMASTERIP=192.168.200.1
# TODO
:<< EOM
vlan tag
netmask cidr
dhcp
	broadcast
	netmask
	range
		from
		to

INTERFACE=eth0.${VLANID}
EOM


fixrouting
echo -e "#---------\n# prepare cluster lab\n#---------"
checkconnectivity
prepare
createvlan
configavahi

echo -e "#-----------------\n# check if leader\n#-----------------"

setip 192.168.200.5
CLUSTERMASTERIP=$(avahi-browse _cluster._tcp -t -r -p | grep 'os-release=hypriot' | grep '^=' | grep ';Cluster-Master' |  grep 'eth0\.' | grep IPv4 | awk -F ';' 'BEGIN { format="%s\n" }{ printf(format,$8) }')
ip addr flush dev eth0.200

echo "if CLUSTERMASTERIP is empty then this machine is the leader"
if [ -z "$CLUSTERMASTERIP" ]; then

cat << EOM
#####################
#                   #
# configure node as #
#                   #
#  cluster master   #
#                   #
#####################
EOM

setip

echo -e "#-------\n# avahi\n#-------"
createavahiclusterservice

echo -e "#---------\n# dnsmasq\n#---------"
configdhcp

MASTERorSLAVE="master"

#elseif CLUSTERMASTERIP not empty, then this machine is not leader and thus slave
else

cat << EOM
#####################
#                   #
# configure node as #
#                   #
#  cluster slave    #
#                   #
#####################
EOM

getip
fixrouting

MASTERorSLAVE="slave"

fi

echo get "self ip"
SELFIP=$(ip addr s dev eth0.200 | grep -v inet6 | grep inet | awk '{print $2 }' | cut -d'/'  -f 1)

echo -e "#--------\n# docker \n#--------"
configdocker

echo -e "#------------------\n# consul and swarm\n#------------------"
fixrouting
composeyml


cat << EOM
#-----------
# debugging
#-----------
EOM

echo "list interface parameters including vlan id"
ip -d link show eth0.200

echo "list ip addresses"
ip addr show eth0.200

echo "list routes"
ip route show
