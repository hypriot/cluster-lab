#!/usr/bin/env bash
# This script checks if after starting the
# Cluster Lab everything works

# TODO

# config variables
VLAN_ID=200
VLAN_LEADER_IP="192.168.200.1"

# Parameter 1 is return value
# Parameter 2 is message
function evaluate_result(){
  if [ "$1" -eq 0 ]; then
    echo -e "\e[32m  [PASS] ${2}\e[0m"
  else 
    echo -e "\e[31m  [FAIL] ${2}\e[0m"
  fi
}

# helper functions
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

# check functions
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

  network=$(echo "${VLAN_LEADER_IP}" | cut -d'.' -f1-3)
  regex="$(echo ${network} | sed -e 's/\./\\\./g')\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
  [[ "$(ip_of_interface eth0.${VLAN_ID})" =~ $regex ]] 
  evaluate_result $? "  eth0.${VLAN_ID} has correct IP from vlan network"

  ping -W 1 -c 2 "${VLAN_LEADER_IP}" > /dev/null 2>&1
  evaluate_result $? "  Cluster leader is reachable"

  number_of_ips=$(ip addr show dev eth0.${VLAN_ID} | grep "inet\s" | wc -l)
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
  
  docker_info_result=$(docker info | grep -E "Cluster\s(store|advertise):")
  echo "$docker_info_result" | grep -q -E 'Cluster\sstore:\sconsul:\/\/192\.168\.200\.1:8500'
  evaluate_result $? "  docker is configured to use consul as key-value store"
  
  echo "$docker_info_result" | grep -q -E 'Cluster\sadvertise:\s192\.168\.200\.1:2375'
  evaluate_result $? "  docker is configured to listen via tcp at port 2375"
  
  netstat --numeric --listening --programs --tcp --inet | grep 'docker' | grep -q -E '192\.168\.200\.1:2375'
  evaluate_result $? "  docker listens on 192.168.200.1 via tcp at port 2375 (Docker-Engine)"

  netstat --numeric --listening --programs --tcp --inet | grep 'docker' | grep -q -E '192\.168\.200\.1:7946'
  evaluate_result $? "  docker listens on 192.168.200.1 via tcp at port 7946 (Serf)"
}

function check_consul(){
  echo -e "\nConsul"

# check running container
# check listening ports -> netstat tulpen
# consul members
# consul info

}

check_networking
check_docker
