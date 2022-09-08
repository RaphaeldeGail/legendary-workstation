#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
#export TF_LOG="debug"

export TF_VAR_user="{ name=\"$USER\", key=\"$(cat /home/$USER/.ssh/id_rsa.pub)\", ip=\"$(curl -s ifconfig.me)\" }"

echo "*start: $(date)"

# Uncomment below to clean code before verifications
terraform fmt -recursive .
terraform-docs .

echo '*Terraform Format'
if ! terraform fmt -check -recursive -list=false .; then
    terraform fmt -check -diff -recursive .
    exit 1
fi
echo '*OK (Terraform Format)'

echo '*Terraform Documentation'
if ! terraform-docs --output-check .; then
    exit 1
fi
echo '*OK (Terraform Documentation)'

echo '*Terraform Init'
if ! terraform init -reconfigure -no-color -backend-config='.secrets/config.bucket.tfbackend'; then
    exit 1
fi
echo '*OK (Terraform Init)'

echo '*Terraform Validate'
if ! terraform validate -no-color; then
    exit 1
fi
echo '*OK (Terraform Validate)'

echo '*Terraform Plan'
if ! terraform plan -json -no-color -out plan.out | jq -r '. | select(.type == "diagnostic" or .type == "change_summary" or .type == "planned_change")["@message"]'; then
    exit 1
fi
echo '*OK (Terraform Plan)'

echo '*Terraform Apply'
if ! terraform apply -json -no-color plan.out | jq -r '. | select(.type == "diagnostic" or .type == "change_summary" or .type == "apply_complete")["@message"]'; then
    exit 1
fi
echo '*OK (Terraform Apply)'

echo "*end: $(date)"
exit 0