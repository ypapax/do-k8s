#!/usr/bin/env bash
set -ex
# Initialize variables
# Run 'doctl compute region list' for a list of available regions
REGION=ams3
SSH_KEY_NAME="mac" # should already exist at digital ocean
