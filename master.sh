#!/bin/bash
set -ex
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): } $HOSTNAME $ '
echo log is here: /var/log/cloud-init-output.log
export DEBIAN_FRONTEND=noninteractive

# Replace this with the token 
TOKEN=xxxxxx.yyyyyyyyyyyyyyyy

apt-get update && apt-get upgrade -y 

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y

apt-get install -y docker.io
apt-get install -y --allow-unauthenticated kubelet kubeadm kubectl kubernetes-cni

export MASTER_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
kubeadm init --pod-network-cidr=10.244.0.0/16  --apiserver-advertise-address $MASTER_IP --token $TOKEN

HOME=/root
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

cp /etc/kubernetes/admin.conf $HOME/
chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf

set +e
kubectl create -f https://github.com/coreos/flannel/blob/master/Documentation/k8s-manifests/kube-flannel-rbac.yml --namespace=kube-system
kubectl create -f https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml --namespace=kube-system
kubectl create -f https://github.com/kubernetes/dashboard/blob/master/src/deploy/recommended/kubernetes-dashboard.yaml --namespace=kube-system
set -e

# Install DigitalOcean monitoring agent
curl -sSL https://agent.digitalocean.com/install.sh | sh