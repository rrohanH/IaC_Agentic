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
            
            Write-Host ""
            Write-Host "EC2 instance provisioned successfully!"
            Write-Host ""
            Write-Host "To connect via SSH:"
            Write-Host "1. terraform output -raw ssh_private_key_pem > ec2-key.pem"
            Write-Host "2. chmod 400 ec2-key.pem"
            Write-Host "3. ssh -i ec2-key.pem ec2-user@$(terraform output -raw public_ip)"
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
