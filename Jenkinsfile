pipeline {
    agent any
    
    environment {
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        AZURE_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        AZURE_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
        AZURE_TENANT_ID = credentials('AZURE_TENANT_ID')
        SSH_PUBLIC_KEY = credentials('azure_ssh_key')
        SSH_PRIVATE_KEY = credentials('azure_ssh_private_key')
    }

    stages {
        stage('Prepare SSH') {
            steps {
                // Create SSH directory and set up the private key with correct permissions
                sh '''
                    mkdir -p ~/.ssh
                    cp "${SSH_PRIVATE_KEY}" ~/.ssh/id_rsa
                    chmod 600 ~/.ssh/id_rsa
                    cp "${SSH_PUBLIC_KEY}" ~/.ssh/id_rsa.pub
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh """
                    terraform plan \
                        -var="ssh_public_key_path=${SSH_PUBLIC_KEY}" \
                        -out=tfplan
                    """
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    def publicIP = sh(
                        script: "terraform -chdir=terraform output -raw public_ip_address",
                        returnStdout: true
                    ).trim()
                    
                    // Wait for SSH to become available
                    sh """
                        until ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa azureuser@${publicIP} 'echo SSH is up'; do 
                            echo "Waiting for SSH to become available..."
                            sleep 5
                        done
                    """
                    
                    // Install dependencies and copy application
                    sh """
                        ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no azureuser@${publicIP} '
                            sudo apt-get update && \
                            sudo apt-get install -y python3-pip python3-venv
                        '
                        scp -i ~/.ssh/id_rsa -r app/* azureuser@${publicIP}:~/
                        ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no azureuser@${publicIP} '
                            python3 -m venv venv && \
                            source venv/bin/activate && \
                            pip install -r requirements.txt && \
                            sudo nohup python3 main.py > app.log 2>&1 &
                        '
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up SSH keys
            sh 'rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub'
        }
        failure {
            echo 'Pipeline failed! Consider cleaning up resources...'
        }
    }
}