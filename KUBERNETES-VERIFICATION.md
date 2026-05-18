# Kubernetes Installation Verification Guide

This guide walks through deploying the infrastructure via Jenkins and verifying Kubernetes installation on the EC2 instance.

---

## **Step 1: Run Jenkins Pipeline**

### Prerequisites
- Jenkins server is running
- AWS credentials are configured in Jenkins
- Terraform is installed on Jenkins agent

### Execute Pipeline

1. Open Jenkins dashboard
2. Navigate to the **IaC** pipeline job
3. Click **Build with Parameters**
4. Configure parameters:
   - **ACTION**: `apply`
   - **AWS_REGION**: `us-east-1` (or your preferred region)
   - **INSTANCE_TYPE**: `t3.micro`
5. Click **Build**
6. Monitor the build progress in **Console Output**
7. Wait for all 7 stages to complete successfully:
   - ✅ Checkout
   - ✅ Initialize
   - ✅ Format
   - ✅ Validate
   - ✅ Plan
   - ✅ Manual Approval
   - ✅ Apply

---

## **Step 2: Copy Terraform State File**

After the pipeline completes successfully, copy the updated state file from Jenkins workspace to your local Desktop.

```bash
cp /c/ProgramData/Jenkins/.jenkins/workspace/IaC/terraform/terraform.tfstate ~/Desktop/
```

**Verify copy was successful:**
```bash
ls -lh ~/Desktop/terraform.tfstate
```

---

## **Step 3: Extract SSH Key and Public IP**

Navigate to Desktop and extract the necessary outputs:

```bash
cd ~/Desktop

# Extract the SSH private key
terraform output -raw ssh_private_key_pem > ec2-key.pem

# Extract the public IP address
terraform output -raw public_ip

# Extract instance ID (optional, for reference)
terraform output -raw instance_id
```

---

## **Step 4: Set SSH Key Permissions**

Restrict permissions on the private key file for SSH security:

```bash
chmod 400 ec2-key.pem
```

**Verify permissions:**
```bash
ls -lh ec2-key.pem
```

Should show: `-r--------` (read-only for owner)

---

## **Step 5: Connect to EC2 Instance**

Get the public IP and connect via SSH:

```bash
# Save public IP to variable
PUBLIC_IP=$(terraform output -raw public_ip)

# Display the IP
echo $PUBLIC_IP

# Connect to instance
ssh -i ec2-key.pem ec2-user@$PUBLIC_IP
```

**Example:**
```bash
ssh -i ec2-key.pem ec2-user@54.147.62.196
```

**Expected output:** You should be logged in as `ec2-user@ip-xxx-xxx-xxx-xxx`

---

## **Step 6: Verify Kubernetes Installation**

Once connected to the EC2 instance, verify all Kubernetes components are installed:

### Check Component Versions

```bash
# Kubectl version
kubectl version --client

# Kubeadm version
kubeadm version

# Kubelet version
kubelet --version

# Containerd version
containerd --version
```

### Check Service Status

```bash
# Verify containerd is running
systemctl status containerd

# Verify kubelet is active
sudo systemctl status kubelet

# System information
uname -a
```

### Expected Output

```
kubectl version: v1.30.14
kubeadm version: v1.30.14
kubelet version: v1.30.14
containerd version: v2.2.3
OS: Amazon Linux 2023 (kernel 6.18.25-57.109.amzn2023.x86_64)
```

---

## **Step 7: Initialize Kubernetes Cluster (Optional)**

If you want to create an active Kubernetes cluster:

```bash
# Initialize single-node cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubeconfig for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify cluster is running
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## **Quick Reference**

### File Locations
| File | Location |
|------|----------|
| SSH Private Key | `~/Desktop/ec2-key.pem` |
| Terraform State | `~/Desktop/terraform.tfstate` |
| Terraform Config | `c:\Users\rhnha\Desktop\Jenkins_Terraform\terraform\` |

### Essential Commands
| Task | Command |
|------|---------|
| Copy state from Jenkins | `cp /c/ProgramData/Jenkins/.jenkins/workspace/IaC/terraform/terraform.tfstate ~/Desktop/` |
| Extract SSH key | `terraform output -raw ssh_private_key_pem > ec2-key.pem` |
| Get public IP | `terraform output -raw public_ip` |
| Set key permissions | `chmod 400 ec2-key.pem` |
| SSH to instance | `ssh -i ec2-key.pem ec2-user@<PUBLIC_IP>` |
| Exit SSH session | `exit` |

### Kubernetes Verification Commands
```bash
kubectl version --client
kubeadm version
kubelet --version
containerd --version
systemctl status containerd
sudo systemctl status kubelet
```

---

## **Troubleshooting**

### SSH Connection Error: "invalid format"
**Problem:** `Load key "ec2-key.pem": invalid format`

**Solution:**
1. Ensure key file has correct line endings (LF, not CRLF)
2. Ensure key is in proper PEM format
3. Regenerate from Terraform state: `terraform output -raw ssh_private_key_pem > ec2-key.pem`

### SSH Connection Denied
**Problem:** `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`

**Solution:**
1. Verify correct key permissions: `chmod 400 ec2-key.pem`
2. Verify correct public IP
3. Verify security group allows SSH (port 22) from your IP
4. Wait a few seconds for instance to complete bootstrap

### terraform output: No outputs found
**Problem:** Running `terraform output` returns "No outputs found"

**Solution:**
1. Ensure you have copied the state file to Desktop
2. Verify state file exists: `ls -lh ~/Desktop/terraform.tfstate`
3. Re-copy from Jenkins workspace: `cp /c/ProgramData/Jenkins/.jenkins/workspace/IaC/terraform/terraform.tfstate ~/Desktop/`

---

## **Architecture Overview**

```
Jenkins Pipeline (apply)
         ↓
AWS Resources Created:
  • Security Group (SSH port 22)
  • EC2 Instance (t3.micro, Amazon Linux 2023)
  • SSH Key Pair
  • Terraform-generated private key
         ↓
Instance Bootstrap:
  • Update packages
  • Install containerd
  • Install kubeadm, kubelet, kubectl
  • Configure kernel modules & sysctl
         ↓
Terraform State:
  Jenkins: /c/ProgramData/Jenkins/.jenkins/workspace/IaC/terraform/terraform.tfstate
  Desktop: ~/Desktop/terraform.tfstate (copied)
         ↓
SSH Access:
  Key: ~/Desktop/ec2-key.pem
  Command: ssh -i ec2-key.pem ec2-user@<IP>
         ↓
Kubernetes Ready:
  All tools installed
  Cluster can be initialized with: kubeadm init
```

---

## **Next Steps After Verification**

1. **Initialize Kubernetes cluster** (if needed)
2. **Install CNI plugin** (e.g., Flannel) for pod networking
3. **Deploy applications** to the cluster
4. **Configure kubectl** on your local machine for remote cluster access

---

**Last Updated:** May 18, 2026  
**Status:** Production Ready  
**Tested With:** Terraform 1.5+, AWS Provider 5.0+, Kubernetes v1.30
