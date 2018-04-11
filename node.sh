#!/bin/bash
set -ex
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): } $HOSTNAME $ '
export DEBIAN_FRONTEND=noninteractive

# Replace this with the token
TOKEN=xxxxxx.yyyyyyyyyyyyyyyy

MASTER_IP=xxx.xxx.xxx.xxx

apt-get update && apt-get upgrade -y

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y

apt-get install -y docker.io
apt-get install -y --allow-unauthenticated kubelet kubeadm kubectl kubernetes-cni

kubeadm join --token $TOKEN $MASTER_IP:6443 --discovery-token-unsafe-skip-ca-verification

# Install DigitalOcean monitoring agent
curl -sSL https://agent.digitalocean.com/install.sh | sh
