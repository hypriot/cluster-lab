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

function ip_of_interface() {
  local interface=$1
  local all_ip_addresses=$(hostname -I)
  local interface_ip=$(ip a s "$interface")
  for ip_address in $all_ip_addresses; do
      if [[ "$interface_ip" == *"$ip_address"* ]]; then
        echo "$ip_address"
      fi
  done
}

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

  # TODO
  # - no two ips on eth0.200
  # - no linklocal address on eth0.200
}

function check_docker(){
 
# TODO
# 
# docker info
# cluster store: consul://192.168.200.1:8500
# Cluster advertise: 192.168.200.1:2375
# eventually number running containers

# check listening ports -> netstat -tulpen
}


function check_consul(){

# check running container
# check listening ports -> netstat tulpen
# consul members
# consul info

}

check_networking
