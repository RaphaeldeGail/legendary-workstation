#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
#export TF_LOG="debug"

export ENV="test"
export TF_VAR_rsa_key=$(cat .secrets/rsa.key)
export TF_VAR_rsa_pub=$(cat .secrets/rsa.pub)
export TF_VAR_dsa_key=$(cat .secrets/dsa.key)
export TF_VAR_dsa_pub=$(cat .secrets/dsa.pub)
export TF_VAR_ssh_pub="raphael:$(cat '/home/raphael/.ssh/id_rsa.pub')"

echo "*start: $(date)"

# Uncomment below to clean code before verifications
terraform fmt
terraform-docs .

echo '*Terraform Format'
if ! terraform fmt -check -list=false; then
    terraform fmt -check -diff
    exit 1
fi
echo '*OK (Terraform Format)'

echo '*Terraform Documentation'
if ! terraform-docs --output-check .; then
    exit 1
fi
echo '*OK (Terraform Documentation)'

echo '*Terraform Init'
if ! terraform init -reconfigure -no-color -backend-config="bucket=master-bucket-0hw3q17w6a1y30jo"; then
    exit 1
fi
echo '*OK (Terraform Init)'

echo '*Terraform Validate'
if ! terraform validate -no-color; then
    exit 1
fi
echo '*OK (Terraform Validate)'

echo '*Terraform Plan'
if ! terraform plan -no-color -var-file=./environments/$ENV.tfvars -out plan.out; then
    exit 1
fi
echo '*OK (Terraform Plan)'

apply=0
for action in $(terraform show -json plan.out | jq .resource_changes[].change.actions[])
do
    if [ $action != '"no-op"' ];
    then
        apply=1
    fi
done

if [ $apply == 0 ];
then
    echo '*WARNING: no infrastructure modifications are scheduled in this plan!'
else
    echo '*Terraform Apply'
    if ! terraform apply -no-color plan.out; then
        exit 1
    fi
    echo '*OK (Terraform Apply)'
fi

echo "*end: $(date)"