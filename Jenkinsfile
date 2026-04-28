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
    TF_VAR_key_name = ""
    TF_VAR_ssh_allowed_cidr = "0.0.0.0/0"
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
      // Workspace cleaned in declarative post actions
    }
  }
}
