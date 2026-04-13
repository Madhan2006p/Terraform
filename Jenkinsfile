// ──────────────────────────────────────────────────────────────
// Jenkinsfile – CI/CD Pipeline for Terraform Docker Deployment
// ──────────────────────────────────────────────────────────────
// Prerequisites (configure in Jenkins):
//   1. Install "Terraform" plugin or add terraform to PATH
//   2. Create AWS credentials (ID: 'aws-credentials') as
//      Secret text or AWS Credentials binding
//   3. Configure a GitHub webhook for automatic triggers
// ──────────────────────────────────────────────────────────────

pipeline {
    agent any

    environment {
        TF_WORKING_DIR  = 'terraform-webapp'
        AWS_REGION      = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        string(
            name: 'INSTANCE_TYPE',
            defaultValue: 't3.micro',
            description: 'EC2 instance type for the Docker host'
        )
        string(
            name: 'DOCKER_IMAGE',
            defaultValue: 'nginx:alpine',
            description: 'Docker image to deploy on EC2'
        )
    }

    stages {

        // ── Stage 1: Checkout Code ──────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ── Stage 2: Terraform Init ─────────────────────────
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            echo "══════════════════════════════════════"
                            echo "  Terraform Init"
                            echo "══════════════════════════════════════"
                            terraform init -input=false
                        '''
                    }
                }
            }
        }

        // ── Stage 3: Terraform Validate ─────────────────────
        stage('Terraform Validate') {
            steps {
                dir("${TF_WORKING_DIR}") {
                    sh '''
                        echo "══════════════════════════════════════"
                        echo "  Terraform Validate"
                        echo "══════════════════════════════════════"
                        terraform validate
                    '''
                }
            }
        }

        // ── Stage 4: Terraform Format Check ─────────────────
        stage('Terraform Format Check') {
            steps {
                dir("${TF_WORKING_DIR}") {
                    sh '''
                        echo "══════════════════════════════════════"
                        echo "  Terraform Format Check"
                        echo "══════════════════════════════════════"
                        terraform fmt -check -recursive || true
                    '''
                }
            }
        }

        // ── Stage 5: Terraform Plan ─────────────────────────
        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_WORKING_DIR}") {
                        sh """
                            echo "══════════════════════════════════════"
                            echo "  Terraform Plan"
                            echo "══════════════════════════════════════"
                            terraform plan \
                                -var='instance_type=${params.INSTANCE_TYPE}' \
                                -var='docker_image=${params.DOCKER_IMAGE}' \
                                -input=false \
                                -out=tfplan
                        """
                    }
                }
            }
        }

        // ── Stage 6: Approval Gate (apply/destroy only) ─────
        stage('Approval') {
            when {
                expression { return params.ACTION != 'plan' }
            }
            steps {
                input message: "Proceed with Terraform ${params.ACTION}?",
                      ok: "Yes, ${params.ACTION} now"
            }
        }

        // ── Stage 7: Terraform Apply ────────────────────────
        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            echo "══════════════════════════════════════"
                            echo "  Terraform Apply"
                            echo "══════════════════════════════════════"
                            terraform apply -auto-approve -input=false tfplan
                        '''
                    }
                }
            }
        }

        // ── Stage 8: Terraform Destroy ──────────────────────
        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_WORKING_DIR}") {
                        sh """
                            echo "══════════════════════════════════════"
                            echo "  Terraform Destroy"
                            echo "══════════════════════════════════════"
                            terraform destroy \
                                -var='instance_type=${params.INSTANCE_TYPE}' \
                                -var='docker_image=${params.DOCKER_IMAGE}' \
                                -auto-approve -input=false
                        """
                    }
                }
            }
        }

        // ── Stage 9: Show Outputs ───────────────────────────
        stage('Show Outputs') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            echo "══════════════════════════════════════"
                            echo "  Terraform Outputs"
                            echo "══════════════════════════════════════"
                            terraform output
                            echo ""
                            echo "  Application URL:"
                            echo "  http://$(terraform output -raw instance_ip)"
                            echo "══════════════════════════════════════"
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above for details.'
        }
        always {
            // Clean up the plan file
            dir("${TF_WORKING_DIR}") {
                sh 'rm -f tfplan'
            }
        }
    }
}
