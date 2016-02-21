#!/usr/bin/env bash
# This script checks if all the prerequisites
# for the Cluster Lab are present and working.

# Parameter 1 is return value
# Parameter 2 is message
function evaluate_result(){
  if [ "$1" -eq 0 ]; then
    echo -e "\e[32m  [PASS] ${2}\e[0m"
  else 
    echo -e "\e[31m  [FAIL] ${2}\e[0m"
  fi
}

function check_networking() {
  echo -e "\nNetworking"

  ip link show | grep -q eth0
  evaluate_result $? "  eth0 exists"

  ping -W 1 -c 2 8.8.8.8 > /dev/null 2>&1
  evaluate_result $? "  Internet is reachable"

  timeout 1 ping -c 1 google.com > /dev/null 2>&1
  evaluate_result $? "  DNS works"
}

function check_processes() {
  echo -e "\nProcesses"

  processes='avahi docker dnsmasq'
  for process in $processes; do
    pgrep "$process" > /dev/null 2>&1
    evaluate_result $? "  ${process} is running"
  done
}

function check_os_packages(){
  echo -e "\nOS Packages"
 
  # instead of checking different package name variants
  # we check for the existence of the docker cli command 
  command -v docker > /dev/null 2>&1
  evaluate_result $? "  docker is installed"

  packages='vlan avahi-utils dnsmasq'
  for pkg in $packages; do
    dpkg -l | grep -q -E "^ii\s*${pkg}"
    evaluate_result $? "  ${pkg} is installed"
  done
}

function check_docker_images(){
  echo -e "\nDocker Images"
  
  # from docker version 1.10.0 we can simplify by
  # docker images --format "{{.Repository}}:{{.Tag}}" | cut -d ':' -f1
 
  result=$(docker images)
  images='swarm consul'

  for image in $images; do
    echo "$result" | grep -q "$image"
    evaluate_result $? "  ${image} exists"
  done
}

check_networking
check_os_packages
check_processes
check_docker_images