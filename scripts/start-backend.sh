#!/bin/bash
set -e

echo "Starting backend application..."

# Load configuration from User Data
if [ -f /etc/starttech/config.env ]; then
    source /etc/starttech/config.env
else
    echo "ERROR: Config file /etc/starttech/config.env not found!"
    exit 1
fi

cd /opt/muchtodo

# Start the Docker container
docker run -d \
  --name muchtodo-api \
  --restart unless-stopped \
  -p ${PORT}:${PORT} \
  -e PORT=${PORT} \
  -e MONGODB_URI=${MONGODB_URI} \
  -e REDIS_ADDR=${REDIS_ADDR} \
  -e JWT_SECRET_KEY=${JWT_SECRET_KEY} \
  -e JWT_EXPIRATION_HOURS=${JWT_EXPIRATION_HOURS} \
  -e ENVIRONMENT=${ENVIRONMENT} \
  --log-driver=awslogs \
  --log-opt awslogs-region=${AWS_REGION} \
  --log-opt awslogs-group=${LOG_GROUP_NAME} \
  --log-opt awslogs-stream=${ENVIRONMENT}-$(hostname) \
  ${ECR_REGISTRY}/${ECR_REPOSITORY}:${ENVIRONMENT}

echo "Waiting for application to start..."
sleep 10

echo "Backend application started successfully."
