#!/usr/bin/env bash
set -ex
source ./consts.sh

# Delete Tags
doctl compute tag delete k8s-master -f
doctl compute tag delete k8s-node -f


# Delete Droplets
doctl compute droplet delete master -f
doctl compute droplet delete node1 -f
doctl compute droplet delete node2 -f


# Delete Load Balancer
LB_ID=`doctl compute load-balancer list | grep "k8slb" | cut -d' ' -f1`
doctl compute load-balancer delete $LB_ID -f

