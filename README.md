# cluster-lab

### ROADDMAP for the HyprIoT Cluster Lab

- [ ] fix node reboot issue
- [ ] add hostname as label to the docker daemon
- [ ] small demo with one webserver showing the NEW docker overlay network
- [ ] example of the docker-cluster-demo repo (registrator + consul-template + haproxy)
- [ ] install dnsmasq direct into the image
- [ ] add dockerui-image on firstboot (like swarm)
- [ ] create debian package of this setup
- [ ] kubernetes
- [ ] crate.io
- [ ] improve corner cases
- [ ] add registrator, consul-template, haproxy, busybox-htttpd on firstboot (like swarm)


### Hardware requirements

- several Raspberry PI B 2s 
- power supply for these PIs
- microSD cards for these PIs
- network cables for these PIs
- switch that does not filter IEEE 802.1Q vlan flags
- internet uplink

### Usage

- first plug in one PI with our clusterlab image
    This pi will be the cluster master running a dnsmasq dhcp server
    The consul webUI is reachable via port `http://<IP of the masterPI>:8500/`

- afterwards plugin all other PIs
    They should boot up and join the consul cluster which is created by the master node.
    They should also join a docker sswarm which is manages via consul.
    The swarm management interface is running on the master node:
       default: tcp://192.168.200.1:2378


- list all swarm nodes:
    `ssh pi@<IP of the masterPI>`

    `docker -H tcp://192.168.200.1:2378 info`

- start dockerui

    `docker run -d -p 9000:9000 --name dockerui hypriot/rpi-dockerui -e http://192.168.200.1:2378`


