# Jenkins + Terraform AWS Provisioning

This repository contains a Jenkins pipeline and Terraform configuration that provisions a small AWS environment, including:

- a VPC
- a public subnet
- an internet gateway and route table
- a security group
- one EC2 instance running Apache HTTPD

## Repository Layout

- `Jenkinsfile` - Jenkins declarative pipeline
- `terraform/` - Terraform configuration for AWS resources

## Prerequisites

- Jenkins with the Terraform CLI available on the agent
- Jenkins credential with ID `aws-credentials` using AWS access key and secret key
- Terraform 1.5 or newer
- AWS permissions to create VPC, subnet, route table, security group, and EC2 resources

## Jenkins Pipeline

The pipeline runs these stages:

1. Checkout
2. Terraform Init
3. Terraform Format (fmt)
4. Terraform Validate
5. Terraform Plan
6. Terraform Apply (if `ACTION=apply`)
7. Terraform Destroy (if `ACTION=destroy`)

## How to Use

1. Configure the Jenkins AWS credential with ID `aws-credentials`.
2. Create a pipeline job pointing to this repository and the `Jenkinsfile`.
3. Run the pipeline with parameters:
   - `ACTION`: choose `plan`, `apply`, or `destroy`
   - `AWS_REGION`: AWS region (default: `us-east-1`)
   - `INSTANCE_TYPE`: EC2 instance type (default: `t3.micro`)
4. Review the plan output before approving apply or destroy.

## Notes

- The configuration uses the latest Amazon Linux 2023 AMI in the selected region.
- If you need remote state, add an S3 backend before using this in production.
- Restrict `SSH_ALLOWED_CIDR` to your IP instead of leaving it open.
