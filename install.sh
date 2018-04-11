#!/usr/bin/env bash

# Download DigitalOcean CLI
curl -OL https://github.com/digitalocean/doctl/releases/download/v1.6.0/doctl-1.6.0-darwin-10.6-amd64.tar.gz
tar xf ./doctl-1.6.0-darwin-10.6-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin

# Download Kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
