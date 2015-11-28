# cluster-lab

[![Build Status](http://armbuilder2.hypriot.com/api/badge/github.com/hypriot/cluster-lab/status.svg?branch=master)](http://armbuilder2.hypriot.com/github.com/hypriot/cluster-lab)

The Hypriot Cluster Lab is a piece of software that can be installed on nodes within a network, and will then automatically setup a cluster of 
 out-of-the-box and self-configuring set of nodes in a network, which will configure themselves. There is a huge range of possibilities to run distributed applications on top or to learn about networking.
Technologies used include the Docker stack (Docker-Compose, Swarm), Consul, and standardized features of computer networks, such as VLANs. 


## How to run

### Hardware requirements

- At least two Raspberry PI B 2 and for each
  - Power supply
  - MicroSD card
  - Network cable
- A network switch that does not filter IEEE 802.1Q vlan flags from network packets. NB! This features is often also provided by low costs switches. If
- Internet uplink


## Option 1: Flash SD card image and boot each nodes from it
  - Download SD card image from <URL>
  - Flash the image to SD cards (this script makes flashing easy for you)
  - Plug the SD cards in each node and power __one__ node on. This node will be the Master of the cluster.
  - Get the IP of this node and open your browser at `http://<IP of the node>:8500`. You should see the Consul webinterface showing one node. Proceed with the next step only you see the webinterface. Give the node about 2 minutes of create it. 
  - Power on all other nodes. After about 2 minutes, you should see all of them be listed in the Consul webinterface.

### Option 2: Install clusterlab as debian package
  - Boot one node on HypriotOS (other OSes have not been tested yet)
  - Get the IP of this node and connect to it via SSH (See our getting-started guide with HypriotOS if you need help here!)
   `ssh pi@<IP of the node>`
  - Install the cluster lab software by executing 
   `sudo apt-get update && apt-get install cluster-lab && systemctl start cluster-start`
  - On any devices in the same LAN network, open a browser at `http://<IP of the node>:8500`. You should see the Consul webinterface showing one node. Proceed with the next step only if you see the webinterface. Give the node about 2 minutes of create it.
  - Install the cluster lab software on on all other nodes with the command given above. After about 2 minutes after each install, you should see the being listed in the Consul webinterface.


## Troubleshooting
  - Check if the service providing the cluster functionality is running. Execute 
    `systemctl status cluster-start.service`
    You should see TBA
  - Start the cluster service manually by
    `systemctl start cluster-start`
  - A reboot often helps :-)


## Some techie background
  - The node that runs the cluster lab software first is the *cluster cleader*. The leader node runs a DHCP server using DNSMasq providing all other nodes, called *slaves*, with dynamic IP addresses. 
  - When booting up the slaves, they  

- afterwards plugin all other PIs
    They should boot up and join the consul cluster which is created by the master node.
    They should also join a docker sswarm which is manages via consul.
    The swarm management interface is running on the master node:
       default: tcp://192.168.200.1:2378


### Test it and play with it
  - You can use **Docker Swarm** by only providing one additional parameter in your Docker commands. For instance, when starting a container, Docker Swarm will distribute it on the cluster nodes according to a specific algorithm.
List all containers in the cluster by logging in into the cluster leader and execute
    `docker -H tcp://192.168.200.1:2378 info` on any node of the cluster.    
  - List all consul members:
    `docker run -ti --rm hypriot/rpi-consul members -rpc-addr=192.168.200.1:8400`
  - Check if `eth0` is member of the virtual network
  - Start the Dockerui to see all containers on a neat website:
    `docker run -d -p 9000:9000 --name dockerui hypriot/rpi-dockerui -e http://192.168.200.1:2378`


### Known Bugs
- cluster does not fully recover if one node leaves and reensters the cluster (e.g. through detaching of the network or on reboot)


### Roadmap

# Features
- instead of installing additional packages in the cluster-start.bash, add these add. packages as *dependency* to deb package
- in rpi-image-builder: Install deb package instead of copying cluster-lab files, and install dnsmasq direct into the image
- add use case: mall demo with one webserver showing the NEW docker overlay network
- example of the docker-cluster-demo repo (registrator + consul-template + haproxy)
- test with other hardware, such as Raspberry Pi Zero
- test with Raspbian and other OSes

## Ideas of use cases:
- dockerui-image on firstboot (like swarm)
- kubernetes
- crate.io
- add registrator, consul-template, haproxy, busybox-htttpd on firstboot (like swarm)


### Maintainers and core developers
Git does not reflect all involved contributors when doing pair programming. The core developers of this software are 

Andreas Eiermann @firecyberice
Mathias Renner @MathiasRenner
Govinda Fichtner @Govinda-Fichtner

from the Hypriot Team.

