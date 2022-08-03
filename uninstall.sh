#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
#export TF_LOG="debug"

export ENV="test"
export TF_VAR_ssh_pub="raphael:$(cat '/home/raphael/.ssh/id_rsa.pub')"

echo "*start: $(date)"

echo '*Terraform Validate'
if ! terraform validate -no-color; then
    exit 1
fi
echo '*OK (Terraform Validate)'

echo '*Terraform Plan'
if ! terraform plan -destroy -no-color -var-file=./environments/$ENV.tfvars -out plan.out; then
    exit 1
fi
echo '*OK (Terraform Plan)'

echo '*Terraform Apply'
if ! terraform apply -no-color plan.out; then
    exit 1
fi
echo '*OK (Terraform Apply)'

echo "*end: $(date)"