# Hypriot Cluster Lab

The Hypriot Cluster Lab allows to create a Docker Swarm Cluster very easily.

The Cluster Lab can be used to
  - run distributed applications in a *real* or *virtual* cluster
  - work, learn and experiment with Docker and Docker Swarm Clustering
  - learn about networking, load balancing and high availability
  - ... and much more!

The Cluster Lab is made with love(tm), lots of glue code and technologies such as Docker-Engine, Docker-Compose, Docker-Swarm and Consul.

__Note: Beware that the Cluster Lab is still beta quality.__

## Key features

__Cluster Lab is self-configuring__  
Cluster-Lab nodes are configured to form a cluster fully automatically.
No configuration by the user is necessary.

__Cluster Lab is fast to set up__  
On ARM a fully working cluster can be set up in minutes.

__Cluster Lab is multi-arch__  
There are Cluster Lab packages for ARM and X86_64.

## Getting started
A node in a Cluster Lab can either be a __leader__ or a __follower__.__
The role of a node is determined by the start order of the cluster nodes. The first node autmatically becomes the __leader__ node.
All nodes that start after the __leader__ automatically become __follower__ nodes.

### Vagrant
To get started with the Cluster Lab based on [Vagrant](https://www.vagrantup.com/) is really easy.
Vagrant allows to run the Cluster Lab based on virtual machines.

First ensure that you a have recent version of Vagrant installed and test if it is working:

```
$ vagrant version
Installed Version: 1.8.1
Latest Version: 1.8.1

You're running an up-to-date version of Vagrant!
```

Then clone this repository with:

```
git clone https://github.com/hypriot/cluster-lab.git
```

Afterwards change into the `vagrant` subdirectory:

```
cd cluster-lab/vagrant
```

To finally start up the Cluster Lab execute the following final command:

```
vagrant up --no-color
```

This should by default create a cluster wth 3 nodes called __leader__, __follower1__ and __follower2__.
On each node all the necessary dependencies are installed, configured and started.
This can take quite some time. Please be patient.

To log into one of the nodes - for instance - the leader node run the following Vagrant command:

```
vagrant ssh leader
```

Replace the last argument with the name of the node you wanna log into.

Then you can check that your Docker Swarm Cluster is working:

```
$ sudo su
$ docker -H tcp://192.168.200.1:2378 info
Containers: 9
 Running: 9
 Paused: 0
 Stopped: 0
Images: 6
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 3
 follower1: 192.168.200.30:2375
  └ Status: Healthy
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, hypriot.arch=x86_64, hypriot.hierarchy=follower, kernelversion=4.2.0-30-generic, operatingsystem=Ubuntu 15.10, storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-09T22:56:05Z
 follower2: 192.168.200.45:2375
  └ Status: Healthy
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, hypriot.arch=x86_64, hypriot.hierarchy=follower, kernelversion=4.2.0-30-generic, operatingsystem=Ubuntu 15.10, storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-09T22:56:18Z
 leader: 192.168.200.1:2375
  └ Status: Healthy
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, hypriot.arch=x86_64, hypriot.hierarchy=leader, kernelversion=4.2.0-30-generic, operatingsystem=Ubuntu 15.10, storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-09T22:56:24Z
Plugins:
 Volume:
 Network:
Kernel Version: 4.2.0-30-generic
Operating System: linux
Architecture: amd64
CPUs: 3
Total Memory: 3.054 GiB
Name: 0a2ac29fe31b
```

As you can see we now have working Swarm Cluster with 3 nodes.


### Raspberry Pi / ARM
To get started with the Cluster Lab on a Raspberry Pi you will need the following:
-  At least two Raspberry Pi's 1 or 2 and for each a __power supply_, a __MicroSD card__ and a __network cable__.
-  A network switch that is connected to the Internet

Note that the network switch must not filter IEEE 802.1Q VLAN flags out of network packets.

#### Option 1: Flash SD card image and boot each nodes from it
  - [Download our SD card image here](http://blog.hypriot.com/downloads/#hypriot-cluster-lab:2a4af035d9e12b64c084b5e7cfb2c420)
  - Flash the image on one SD card for each Raspberry Pi ([this script makes flashing easy for you](https://github.com/hypriot/flash))
  - Plug the SD cards in each node and power **only one** node on. This node will be the __leader__ of the cluster
  - Get the IP address of this node and open your browser at **http://{IP of the leader node}:8500**. You should see the Consul web interface listing one node. Proceed with the next step only if you see the web interface. Grant the node about 2 minutes to boot up.
  - Power on all other nodes. After about 2 minutes you should see all of them being listed in the Consul web interface.

#### Option 2: Install the Cluster Lab as Debian Package
  - Boot one node on the [latest HypriotOS](http://blog.hypriot.com/downloads/) (you need "Version 0.5 Will" or above. Other OSes have just not been tested yet.
  - Get the IP of this node and connect to it via SSH (See our [getting-started guide](http://blog.hypriot.com/getting-started-with-docker-on-your-arm-device/) with HypriotOS if you need help here!

   `ssh pi@<IP of the node>`

  - Install the Cluster Lab package by executing

   `sudo apt-get update && sudo apt-get install hypriot-cluster-lab && sudo systemctl start cluster-lab`

  - On any device in the same network, open a browser at **http://{IP of the node}:8500**. You should see the Consul web interface listing one node. Proceed with the next step only if you see the web interface. Grant the node about 2 minutes to boot up.
  - Install the Cluster Lab package on all other nodes with the same command as above. About 2 minutes after each install, you should see the nodes being listed in the Consul web interface.


## Troubleshooting
For both the __Vagrant__ and the __Raspberry Pi__ variant of the Cluster Lab the Cluster Lab is managed as a systemd service.
This means that the Cluster Lab is started on each node when the node is booting.

The Cluster Lab can be started and stopped on each cluster node like this:

```
# start Cluster Lab
$ cluster-lab start

# stop Cluster Lab
$ cluster-lab stop
```

In case of problems the verbosity level of the start and stop commands can be increased to show more information about potential problems.

```
$ VERBOSE=true cluster-lab start

Internet Connection
  [PASS]   eth1 exists
  [PASS]   eth1 has an ip address
  [PASS]   Internet is reachable
  [PASS]   DNS works

Networking
  [PASS]   eth1 exists
  [PASS]   vlan os package exists
  [PASS]   Avahi os package exists
  [PASS]   Avahi-utils os package exists
  [PASS]   Avahi process exists
  [PASS]   Avahi cluster-leader.service file is absent

Configure basic networking

Networking
  [PASS]   eth1.200 exists
  [PASS]   eth1.200 has correct IP from vlan network
  [PASS]   Cluster leader is reachable
  [PASS]   eth1.200 has exactly one IP
  [PASS]   eth1.200 has no local link address
  [PASS]   Avahi process exists
  [PASS]   Avahi is using eth1.200
  [PASS]   Avahi cluster-leader.service file exists

This node is Leader

DHCP is enabled

DNSmasq
  [PASS]   dnsmasq os package exists
  [PASS]   dnsmasq process exists
  [PASS]   /etc/dnsmasq.conf backup file is absent

Configure DNSmasq

DNSmasq
  [PASS]   dnsmasq process exists
  [PASS]   /etc/dnsmasq.conf backup file exists

Docker
  [PASS]   docker is installed
  [PASS]   Docker process exists
  [PASS]   /etc/default/docker backup file is absent

Configure Docker

Docker
  [PASS]   Docker is running
  [PASS]   Docker is configured to use Consul as key-value store
  [PASS]   Docker is configured to listen via tcp at port 2375
  [PASS]   Docker listens on 192.168.200.30 via tcp at port 2375 (Docker-Engine)

Consul
  [PASS]   Consul Docker image exists
  [PASS]   Consul Docker container is running
  [PASS]   Consul is listening on port 8300
  [PASS]   Consul is listening on port 8301
  [PASS]   Consul is listening on port 8302
  [PASS]   Consul is listening on port 8400
  [PASS]   Consul is listening on port 8500
  [PASS]   Consul is listening on port 8600
  [PASS]   Consul API works
  [PASS]   Cluster-Node is pingable with IP 192.168.200.30
  [PASS]   Cluster-Node is pingable with IP 192.168.200.45
  [PASS]   Cluster-Node is pingable with IP 192.168.200.1
  [PASS]   No Cluster-Node is in status 'failed'
  [PASS]   Consul is able to talk to Docker-Engine on port 7946 (Serf)

Swarm
  [PASS]   Swarm-Join Docker container is running
  [PASS]   Swarm-Manage Docker container is running
  [PASS]   Number of Swarm and Consul nodes is equal which means our cluster is healthy
```

If everything works there should only be [PASS]ing tests.

There are also two more command that help troubeshoot problems.

After the Cluster Lab is started with `cluster-lab start` one can verify the health of the cluster on each node with

```
$ cluster-lab health
```

This should output the results of various self tests and all should [PASS].

If there are problems/failing tests a good strategy is to stop the Cluster Lab with

```
$ cluster-lab stop
```

This should reset the node into the original state it had before the start of the Cluster Lab.

Afterwards we can check if everything is ready for starting the Cluster Lab:

```
$ cluster-lab dependencies
```

Here we should also see only [PASS]ing tests.

## Community & Help
Get in touch with us and the community in our [Gitter chat](https://gitter.im/hypriot/talk).

## Related projects

  - http://blog.arungupta.me/docker-swarm-cluster-using-consul/
  - https://github.com/luxas/kubernetes-on-arm
  - http://besn0847.blogspot.de/2015/11/building-internet-wide-container.html
  - http://matthewkwilliams.com/index.php/2015/04/03/swarming-raspberry-pi-docker-swarm-discovery-options/
  - http://blog.scottlowe.org/2015/03/06/running-own-docker-swarm-cluster/
  - https://github.com/dduportal/rpi-utils/blob/master/documentation/docker-swarm.md

## Maintainer

  - Andreas Eiermann @firecyberice
  - Mathias Renner @MathiasRenner
  - Govinda Fichtner @Govinda-Fichtner
