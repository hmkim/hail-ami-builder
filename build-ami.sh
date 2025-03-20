#!/bin/bash

set -e

echo "Building new Amazon Linux 2023 AMI with Packer..."
packer build -on-error=ask aws-amazonlinux2023.pkr.hcl | tee packer_output.log

# AMI ID 추출
AMI_ID=$(grep -oP 'ami-\w+' packer_output.log | tail -1)

if [[ -z "$AMI_ID" ]]; then
    echo "Error: AMI ID not found!"
    exit 1
fi

echo "New AMI ID: $AMI_ID"
echo $AMI_ID > ami_id.txt

