pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action to perform')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region')
    string(name: 'INSTANCE_TYPE', defaultValue: 't3.micro', description: 'EC2 instance type')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = 'false'
    TF_VAR_region = "${params.AWS_REGION}"
    TF_VAR_instance_type = "${params.INSTANCE_TYPE}"
    TERRAFORM_DIR = 'terraform'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          powershell '''
            $ErrorActionPreference = 'Stop'
            Set-Location $env:TERRAFORM_DIR
            terraform init
          '''
        }
      }
    }

    stage('Terraform Format') {
      steps {
        powershell '''
          $ErrorActionPreference = 'Stop'
          Set-Location $env:TERRAFORM_DIR
          terraform fmt -check -recursive
        '''
      }
    }

    stage('Terraform Validate') {
      steps {
        powershell '''
          $ErrorActionPreference = 'Stop'
          Set-Location $env:TERRAFORM_DIR
          terraform validate
        '''
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          powershell '''
            $ErrorActionPreference = 'Stop'
            Set-Location $env:TERRAFORM_DIR
            terraform plan -out=tfplan
          '''
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { params.ACTION == 'apply' }
      }
      steps {
        input message: 'Apply Terraform plan?', ok: 'Apply'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          powershell '''
            $ErrorActionPreference = 'Stop'
            Set-Location $env:TERRAFORM_DIR
            terraform apply -auto-approve tfplan
          '''
        }
      }
    }

    stage('Verify Kubernetes Installation') {
      when {
        expression { params.ACTION == 'apply' }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          powershell '''
            $ErrorActionPreference = 'Stop'
            Set-Location $env:TERRAFORM_DIR

            $instanceId = terraform output -raw instance_id
            Write-Host "Sending SSM verification command to instance $instanceId"

            $commands = @(
              'set -euo pipefail',
              'echo "Hostname: $(hostname)"',
              'if command -v kubectl >/dev/null 2>&1; then kubectl version --client --short || kubectl version --client; else echo "kubectl: not installed"; exit 1; fi',
              'if command -v kubeadm >/dev/null 2>&1; then kubeadm version --short || kubeadm version; else echo "kubeadm: not installed"; exit 1; fi',
              'if command -v kubelet >/dev/null 2>&1; then kubelet --version; systemctl is-enabled kubelet; systemctl is-active kubelet; else echo "kubelet: not installed"; exit 1; fi'
            )

            $parameters = @{ commands = $commands } | ConvertTo-Json -Compress
            $commandId = aws ssm send-command --document-name AWS-RunShellScript --instance-ids $instanceId --comment 'Verify Kubernetes installation' --parameters $parameters --query 'Command.CommandId' --output text

            for ($attempt = 1; $attempt -le 24; $attempt++) {
              try {
                $invocationJson = aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId --output json
                $invocation = $invocationJson | ConvertFrom-Json

                if ($invocation.Status -in @('Pending', 'InProgress', 'Delayed')) {
                  Start-Sleep -Seconds 10
                  continue
                }

                if ($invocation.StandardOutputContent) {
                  Write-Host $invocation.StandardOutputContent
                }

                if ($invocation.StandardErrorContent) {
                  Write-Host $invocation.StandardErrorContent
                }

                if ($invocation.Status -ne 'Success') {
                  throw "SSM command ended with status $($invocation.Status)"
                }

                break
              } catch {
                if ($attempt -eq 24) {
                  throw
                }

                Start-Sleep -Seconds 10
              }
            }
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { params.ACTION == 'destroy' }
      }
      steps {
        input message: 'Destroy Terraform resources?', ok: 'Destroy'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          powershell '''
            $ErrorActionPreference = 'Stop'
            Set-Location $env:TERRAFORM_DIR
            terraform destroy -auto-approve
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'Pipeline execution completed'
    }
  }
}
