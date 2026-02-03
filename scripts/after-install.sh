#!/bin/bash
set -e

echo "Running after install tasks..."

# Load configuration from User Data
if [ -f /etc/starttech/config.env ]; then
    source /etc/starttech/config.env
else
    echo "ERROR: Config file /etc/starttech/config.env not found!"
    exit 1
fi

cd /opt/muchtodo

# Get AWS region from instance metadata if not set
if [ -z "$AWS_REGION" ]; then
    export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
fi

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Pull the latest image
echo "Pulling Docker image..."
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${ENVIRONMENT}

# Load environment variables from SSM Parameter Store or Secrets Manager
# Example: export DATABASE_URL=$(aws ssm get-parameter --name /muchtodo/${ENVIRONMENT}/database-url --with-decryption --query 'Parameter.Value' --output text)

echo "After install tasks completed."
