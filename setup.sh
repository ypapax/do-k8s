#!/usr/bin/env bash
set -ex


source ./consts.sh

SSH_ID=`doctl compute ssh-key list | grep "$SSH_KEY_NAME" | cut -d' ' -f1`
SSH_KEY=`doctl compute ssh-key get $SSH_ID --format FingerPrint --no-header`

# Create Tags
doctl compute tag create k8s-master
doctl compute tag create k8s-node

# Generate token and insert into the script files
TOKEN=`python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))'`
sed -i.bak "s/^TOKEN=.*/TOKEN=${TOKEN}/" ./master.sh
sed -i.bak "s/^TOKEN=.*/TOKEN=${TOKEN}/" ./node.sh

# Create Master
doctl compute droplet create master \
	--region $REGION \
	--image ubuntu-16-04-x64 \
	--size 2gb \
	--tag-name k8s-master \
	--ssh-keys $SSH_KEY \
	--user-data-file  ./master.sh \
	--wait

# Retrieve IP address of Master
MASTER_ID=`doctl compute droplet list | grep "master" |cut -d' ' -f1`
MASTER_IP=`doctl compute droplet get $MASTER_ID --format PublicIPv4 --no-header`


set +e
while true; do
	ssh -o StrictHostKeyChecking=no root@$MASTER_IP kubectl get nodes | grep master
	if [ $? -eq 0 ]; then
		break
	fi

	echo Wait till Kubernetes Master is up and running
	sleep 15
done
set -e
scp root@$MASTER_IP:/etc/kubernetes/admin.conf .

# Update Script with MASTER_IP
sed -i.bak "s/^MASTER_IP=.*/MASTER_IP=${MASTER_IP}/" ./node.sh

# Join Nodes
doctl compute droplet create node1 node2 \
	--region $REGION \
	--image ubuntu-16-04-x64 \
	--size 2gb \
	--tag-name k8s-node \
	--ssh-keys $SSH_KEY \
	--user-data-file  ./node.sh \
	--wait

# Confirm the creation of Nodes
kubectl --kubeconfig ./admin.conf get nodes

# Deploy an App
kubectl --kubeconfig ./admin.conf create  -f todo-all-in-one.yaml

# Get the NodePort
NODEPORT=`kubectl --kubeconfig ./admin.conf get svc -o go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}'`

# Create a Load Balancer
doctl compute load-balancer create \
	--name k8slb \
	--tag-name k8s-node \
	--region $REGION \
	--health-check protocol:http,port:$NODEPORT,path:/,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 \
	--forwarding-rules entry_protocol:TCP,entry_port:80,target_protocol:TCP,target_port:$NODEPORT \
	--wait

while true; do
	LB_ID=`doctl compute load-balancer list | grep "k8slb" | cut -d' ' -f1`
	LB_IP=`doctl compute load-balancer get $LB_ID | awk '{ print $2; }' | tail -n +2`
	if ping ${LB_IP} -c 1; then
		break
	fi
	echo "waiting for load balancer IP"
	sleep 30
done
# Open the Web App in Browser
open http://$LB_IP