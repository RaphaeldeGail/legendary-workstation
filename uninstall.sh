#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
#export TF_LOG="debug"

export TF_VAR_user="{ name=\"$USER\", public_key=\"$(cat /home/$USER/.ssh/id_rsa.pub)\", desktop_ip=\"$(curl ifconfig.me)/32\" }"

echo "*start: $(date)"

echo '*Terraform Validate'
if ! terraform validate -no-color; then
    exit 1
fi
echo '*OK (Terraform Validate)'

echo '*Terraform Plan'
if ! terraform plan -destroy -no-color -out plan.out; then
    exit 1
fi
echo '*OK (Terraform Plan)'

echo '*Terraform Apply'
if ! terraform apply -no-color plan.out; then
    exit 1
fi
echo '*OK (Terraform Apply)'

echo "*end: $(date)"
exit 0