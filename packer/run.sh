#!/bin/bash
# export TF_IN_AUTOMATION="true"
# export TF_INPUT=0
#export TF_LOG="debug"

export ENV="test"
export PKR_VAR_rsa_key=$(cat ../.secrets/rsa.key)
export PKR_VAR_rsa_pub=$(cat ../.secrets/rsa.pub)

echo "*start: $(date)"

# Uncomment below to clean code before verifications
packer fmt .

echo '*Packer Format'
if ! packer fmt -check .; then
    packer fmt -check -diff .
    exit 1
fi
echo '*OK (Packer Format)'

echo '*Packer Validate'
if ! packer validate .; then
    exit 1
fi
echo '*OK (Packer Validate)'

echo '*Packer Build'
if ! packer build -color=false .; then
    exit 1
fi
echo '*OK (Packer Build)'


echo "*end: $(date)"