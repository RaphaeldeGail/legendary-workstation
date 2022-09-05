#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_INPUT=0
#export TF_LOG="debug"

export TF_VAR_user="{ name=\"aaa\", key=\"\", ip=\"1.1.1.1\" }"

echo "*start: $(date)"

echo '*Terraform Validate'
if ! terraform validate -no-color; then
    exit 1
fi
echo '*OK (Terraform Validate)'

echo '*Terraform Plan'
if ! terraform plan -json -destroy -no-color -out plan.out | jq -r '. | select(.type == "diagnostic" or .type == "change_summary" or .type == "planned_change")["@message"]'; then
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