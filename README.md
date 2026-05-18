# Jenkins + Terraform AWS Provisioning

This repository contains a Jenkins pipeline and Terraform configuration that provisions:

- a security group (SSH access on port 22)
- an SSH key pair (Terraform-generated)
- one EC2 instance (Amazon Linux 2023) bootstrapped with Kubernetes tooling

The instance is deployed to the default AWS VPC.

## Repository Layout

- `Jenkinsfile` - Jenkins declarative pipeline
- `terraform/` - Terraform configuration for AWS resources

## Prerequisites

- Jenkins with the Terraform CLI available on the agent
- Jenkins credential with ID `aws-credentials` using AWS access key and secret key
- Terraform 1.5 or newer
- AWS permissions to create security groups and EC2 instances

## Jenkins Pipeline

The pipeline runs these stages:

1. Checkout
2. Terraform Init
3. Terraform Format (fmt)
4. Terraform Validate
5. Terraform Plan
6. Terraform Apply (if `ACTION=apply`)
7. Verify Kubernetes Installation (if `ACTION=apply`)
8. Terraform Destroy (if `ACTION=destroy`)

## How to Use

1. Configure the Jenkins AWS credential with ID `aws-credentials`.
2. Create a pipeline job pointing to this repository and the `Jenkinsfile`.
3. Run the pipeline with parameters:
   - `ACTION`: choose `plan`, `apply`, or `destroy`
   - `AWS_REGION`: AWS region (default: `us-east-1`)
   - `INSTANCE_TYPE`: EC2 instance type (default: `t3.micro`)
4. Review the plan output before approving apply or destroy.

After apply, you can also SSH into the instance using the generated private key output from Terraform.

## SSH Access

1. Run `terraform output -raw ssh_private_key_pem > ec2-key.pem` from the Terraform directory after `apply` completes.
2. Connect to the instance with `ssh -i ec2-key.pem ec2-user@<public-ip>`.
3. The default SSH username for Amazon Linux 2023 is `ec2-user`.
4. The security group allows SSH from `allowed_ssh_cidr`, which defaults to `0.0.0.0/0`. Tighten that value to your public IP before using this in production.

## Kubernetes Checks

Once connected over SSH, run:

```bash
kubectl version --client
kubeadm version
kubelet --version
systemctl status kubelet
systemctl status containerd
```

## Notes

- The EC2 bootstrap installs containerd, kubelet, kubeadm, and kubectl on Amazon Linux 2023.
- The instance runs in the default AWS VPC with a public IP automatically assigned.
- SSH access requires the private key exported from Terraform (see SSH Access section).
- For production use, consider restricting `allowed_ssh_cidr` to your public IP instead of `0.0.0.0/0`.
- If you need remote state, add an S3 backend before using this in production.
