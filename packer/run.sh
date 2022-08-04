#!/bin/bash

export ENV="test"
export PKR_VAR_rsa_key=$(cat ../.secrets/rsa.key)
export PKR_VAR_rsa_pub=$(cat ../.secrets/rsa.pub)
export PKR_VAR_server_key=$(cat ../.secrets/server.key)
export PKR_VAR_server_cert=$(cat ../.secrets/server.pem)

# Set here the packer file to build
file='envoy.pkr.hcl'

echo "*start: $(date)"

# Uncomment below to clean code before verifications
packer fmt $file

echo '*Packer Format'
if ! packer fmt -check $file; then
    packer fmt -check -diff $file
    exit 1
fi
echo '*OK (Packer Format)'

echo '*Packer Validate'
if ! packer validate $file; then
    exit 1
fi
echo '*OK (Packer Validate)'

echo '*Packer Build'
if ! packer build -color=false $file; then
    exit 1
fi
echo '*OK (Packer Build)'


echo "*end: $(date)"