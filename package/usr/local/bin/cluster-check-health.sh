#!/usr/bin/env bash
# This script checks if after starting the
# Cluster Lab everything works

# TODO
# - test that Docker Swarm is working

# config variables
VLAN_ID="200"
VLAN_LEADER_IP="192.168.200.1"

VLAN_SUBNET=$(echo "${VLAN_LEADER_IP}" | cut -d'.' -f1-3)
VLAN_INTERFACE="eth0.${VLAN_ID}"

###  helper functions

# Parameter 1 is return value
# Parameter 2 is message
function evaluate_result(){
  if [ "$1" -eq 0 ]; then
    echo -e "\e[32m  [PASS] ${2}\e[0m"
  else 
    echo -e "\e[31m  [FAIL] ${2}\e[0m"
  fi
}

function ip_of_interface(){
  local interface=$1
  local all_ip_addresses=$(hostname -I)
  local interface_ip=$(ip a s "$interface")
  for ip_address in $all_ip_addresses; do
      if [[ "$interface_ip" == *"$ip_address"* ]]; then
        echo "$ip_address"
      fi
  done
}

function escape_ip_for_regex(){
  echo "${1//\./\\\.}"
}

function docker_images(){
  if [[ -z "$DOCKER_IMAGES" ]]; then
    DOCKER_IMAGES=$(docker images)
  fi
  echo "$DOCKER_IMAGES"
}

function docker_container(){
  if [[ -z "$DOCKER_CONTAINER" ]]; then
    DOCKER_CONTAINER=$(docker ps)
  fi
  echo "$DOCKER_CONTAINER"
}

function docker_info(){
  if [[ -z "$DOCKER_INFO" ]]; then
    DOCKER_INFO=$(docker info)
  fi
  echo "$DOCKER_INFO"
}

function consul_members(){
  if [[ -z "$CONSUL_MEMBERS" ]]; then
    CONSUL_MEMBERS=$(docker exec -it bin_consul_1 /consul members)
  fi
  echo "$CONSUL_MEMBERS"
}

function consul_nodes_from_kv(){
  if [[ -z "$CONSUL_NODES_FROM_KV" ]]; then
    CONSUL_NODES_FROM_KV="$(curl --silent http://"${VLAN_NODE_IP}":8500/v1/catalog/nodes)"
  fi
  echo "$CONSUL_NODES_FROM_KV"
}

###  check functions

function check_networking(){
  echo -e "\nNetworking"

  ip link show | grep -q eth0
  evaluate_result $? "  eth0 exists"

  ping -W 1 -c 2 8.8.8.8 > /dev/null 2>&1
  evaluate_result $? "  Internet is reachable"

  timeout 1 ping -c 1 google.com > /dev/null 2>&1
  evaluate_result $? "  DNS works"

  ip link show | grep -q eth0.${VLAN_ID}
  evaluate_result $? "  eth0.${VLAN_ID} exists"

  # check if the vlan 192.168.200 subnet exists
  regex="$(escape_ip_for_regex "${VLAN_SUBNET}")\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
  [[ "$(ip_of_interface eth0.${VLAN_ID})" =~ $regex ]] 
  evaluate_result $? "  eth0.${VLAN_ID} has correct IP from vlan network"

  ping -W 1 -c 2 "${VLAN_LEADER_IP}" > /dev/null 2>&1
  evaluate_result $? "  Cluster leader is reachable"

  number_of_ips=$(ip addr show dev eth0.${VLAN_ID} | grep -c "inet\s")
  [[ "$number_of_ips" -eq 1 ]] 
  evaluate_result $? "  eth0.${VLAN_ID} has exactly one IP"

  regex="169\.254\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
  [[ ! "$(ip_of_interface eth0.${VLAN_ID})" =~ $regex ]] 
  evaluate_result $? "  eth0.${VLAN_ID} has no local link address"
}

function check_docker(){
  echo -e "\nDocker"
  
  pgrep docker > /dev/null 2>&1
  evaluate_result $? "  docker is running"

  docker_info | grep -q -E "Cluster\sstore:\sconsul:\/\/${ESCAPED_VLAN_NODE_IP}:8500"
  evaluate_result $? "  docker is configured to use consul as key-value store"
  
  docker_info | grep -q -E "Cluster\sadvertise:\s${ESCAPED_VLAN_NODE_IP}:2375"
  evaluate_result $? "  docker is configured to listen via tcp at port 2375"
  
  netstat --numeric --listening --programs --tcp --inet | grep 'docker' | grep -q -E "${ESCAPED_VLAN_NODE_IP}:2375"
  evaluate_result $? "  docker listens on ${VLAN_NODE_IP} via tcp at port 2375 (Docker-Engine)"

  netstat --numeric --listening --programs --tcp --inet | grep 'docker' | grep -q -E "${ESCAPED_VLAN_NODE_IP}:7946"
  evaluate_result $? "  docker listens on ${VLAN_NODE_IP} via tcp at port 7946 (Serf)"
}

function check_consul(){
  echo -e "\nConsul"
  
  docker_images | grep -q 'consul'
  evaluate_result $? "  Consul Docker image exists"

  docker_container | grep -q 'consul agent -serve'
  evaluate_result $? "  Consul Docker container is running"

  listening_consul_ports=$(netstat -tlpen | grep consul)
  expected_consul_ports="8300 8301 8302 8400 8500 8600"
  for port in $expected_consul_ports; do
    echo "${listening_consul_ports}" | grep -q "${port}"
    evaluate_result $? "  Consul is listening on port ${port}"
  done

  consul_nodes_from_kv | grep -q "Address" 
  evaluate_result $? "  Consul API works" 

  # extract IPs of all consul nodes from json returned from API
  # ping all IPs
  regex="((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))"
  while read ip_address_snippet ; do
    local ip=$(echo "$ip_address_snippet" | grep -oP "${regex}")
    ping -W 1 -c 2 ${ip} > /dev/null 2>&1
    evaluate_result $? "  Cluster-Node is pingable with IP ${ip}" 
  done < <( consul_nodes_from_kv | grep -oP "\"Address\":\"${regex}\"" ) 

  number_of_failed_consul_nodes=$(docker exec -it bin_consul_1 /consul members | grep -c 'failed')
  [[ number_of_failed_consul_nodes -eq 0 ]]
  evaluate_result $? "  No Cluster-Node is in status 'failed'" 
}

# Variables that use some helper functions
VLAN_NODE_IP="$(ip_of_interface "${VLAN_INTERFACE}")"
ESCAPED_VLAN_NODE_IP=$(escape_ip_for_regex "${VLAN_NODE_IP}")

check_networking
check_docker
check_consul
