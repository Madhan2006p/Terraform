// ──────────────────────────────────────────────────────────────
// Jenkinsfile – CI/CD Pipeline for Terraform Docker Deployment
// ──────────────────────────────────────────────────────────────
// Prerequisites (configure in Jenkins):
//   1. Install "Terraform" plugin or add terraform to PATH
//   2. Create two Secret Text credentials in Jenkins:
//        - ID: 'aws-access-key-id'     → your AWS Access Key
//        - ID: 'aws-secret-access-key'  → your AWS Secret Key
//   3. Configure a GitHub webhook for automatic triggers
// ──────────────────────────────────────────────────────────────

pipeline {
    agent any

    environment {
        TF_WORKING_DIR     = '.'
        AWS_DEFAULT_REGION = 'ap-south-1'
        TF_IN_AUTOMATION   = 'true'
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
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

        // ── Stage 2b: Import Existing S3 Resources ─────────
        stage('Import Existing Resources') {
            steps {
                dir("${TF_WORKING_DIR}") {
                    sh '''
                        echo "══════════════════════════════════════"
                        echo "  Import Existing Resources"
                        echo "══════════════════════════════════════"

                        # Import S3 bucket if not already in state
                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_bucket.bucket"; then
                            echo "Importing existing S3 bucket..."
                            terraform import module.s3.aws_s3_bucket.bucket madhan-terraform-bucket-2026-001 || true
                        else
                            echo "S3 bucket already in state, skipping import."
                        fi

                        # Import S3 public access block
                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_bucket_public_access_block.public_access"; then
                            echo "Importing S3 public access block..."
                            terraform import module.s3.aws_s3_bucket_public_access_block.public_access madhan-terraform-bucket-2026-001 || true
                        else
                            echo "S3 public access block already in state, skipping."
                        fi

                        # Import S3 website configuration
                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_bucket_website_configuration.website"; then
                            echo "Importing S3 website config..."
                            terraform import module.s3.aws_s3_bucket_website_configuration.website madhan-terraform-bucket-2026-001 || true
                        else
                            echo "S3 website config already in state, skipping."
                        fi

                        # Import S3 bucket policy
                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_bucket_policy.public_read"; then
                            echo "Importing S3 bucket policy..."
                            terraform import module.s3.aws_s3_bucket_policy.public_read madhan-terraform-bucket-2026-001 || true
                        else
                            echo "S3 bucket policy already in state, skipping."
                        fi

                        # Import S3 objects
                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_object.index"; then
                            echo "Importing S3 index.html object..."
                            terraform import module.s3.aws_s3_object.index madhan-terraform-bucket-2026-001/index.html || true
                        fi

                        if ! terraform state list 2>/dev/null | grep -q "module.s3.aws_s3_object.styles"; then
                            echo "Importing S3 styles.css object..."
                            terraform import module.s3.aws_s3_object.styles madhan-terraform-bucket-2026-001/styles.css || true
                        fi

                        echo "Import complete."
                    '''
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

        // ── Stage 8: Terraform Destroy ──────────────────────
        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
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

        // ── Stage 9: Show Outputs ───────────────────────────
        stage('Show Outputs') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
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
