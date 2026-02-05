# Docker Build & Deployment Guide

## Overview

This guide covers building and running the StartTech Backend application using Docker in both development and production environments.

## Files

- **Dockerfile** - Development build (includes Swagger docs, optimized for debugging)
- **Dockerfile.prod** - Production build (minimal size, security hardened, no debug info)
- **docker-compose.yaml** - Development environment (MongoDB, Redis, MongoDB Express, Redis Commander)
- **docker-compose.prod.yml** - Production environment (backend only, uses AWS services)
- **docker-build.sh** - Build script for easy image creation
- **.dockerignore** - Files to exclude from Docker builds

## Development Build

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB+ available disk space

### Build Development Image

```bash
# Option 1: Using build script
./docker-build.sh dev

# Option 2: Using docker build directly
docker build -f Dockerfile -t starttech-backend:dev .

# Option 3: Using make (if implemented)
make docker-build-dev
```

### Run Development Environment

```bash
# Start all services (MongoDB, Redis, Backend)
docker-compose -f docker-compose.yaml up -d

# View logs
docker-compose -f docker-compose.yaml logs -f backend

# Stop services
docker-compose -f docker-compose.yaml down
```

### Development Access Points

- **Backend API**: http://localhost:3000
- **Swagger Docs**: http://localhost:3000/swagger/index.html
- **MongoDB Express**: http://localhost:8081
- **Redis Commander**: http://localhost:8082

### Environment Configuration

The development environment uses `.env` file:

```bash
PORT=8080
ENVIRONMENT=development
MONGO_URI=mongodb://root:example@mongodb:27017/much_todo_db?authSource=admin
REDIS_ADDR=redis:6379
ENABLE_CACHE=true
```

## Production Build

### Build Production Image

```bash
# Option 1: Using build script
./docker-build.sh prod v1.0.0

# Option 2: Using docker build directly
docker build -f Dockerfile.prod -t starttech-backend:v1.0.0 .

# Option 3: Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker tag starttech-backend:v1.0.0 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/starttech-backend:v1.0.0
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/starttech-backend:v1.0.0
```

### Production Environment Configuration

The production environment uses `.env.production` file with:

```bash
MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/much_todo_db
REDIS_ADDR=your-elasticache-endpoint.cache.amazonaws.com:6379
JWT_SECRET_KEY=<generate-strong-random-secret>
SECURE_COOKIE=true
ALLOW_ORIGINS=https://yourdomain.com
```

### Security Features

**Development Image (Dockerfile)**

- Includes debugging tools
- Swagger documentation enabled
- Full logging

**Production Image (Dockerfile.prod)**

- Minimal Alpine base (security)
- Stripped debug symbols (-ldflags="-w -s")
- Static binary (CGO_ENABLED=0)
- Non-root user (optional)
- Health checks included
- Resource limits configured

### Image Sizes

```bash
Development: ~350MB (with Swagger, debug info)
Production:  ~50MB (minimal, optimized)
```

## Docker Compose Configurations

### Development (docker-compose.yaml)

Services:

- **mongodb** - MongoDB 8.0 with auth
- **mongo-express** - MongoDB web UI
- **redis** - Redis 7.2 with persistence
- **redis-commander** - Redis web UI
- **backend** - Application service

Features:

- Service health checks
- Volume persistence
- Network isolation
- Automatic service startup order

### Production (docker-compose.prod.yml)

Services:

- **backend** - Application only

Configuration:

- Uses AWS services (RDS/MongoDB Atlas, ElastiCache)
- CloudWatch Logs integration
- Security constraints (no-new-privileges)
- Resource limits (CPU, memory)
- Health checks for orchestration

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs backend

# Verify health check
docker-compose ps

# Inspect container
docker inspect <container_id>
```

### MongoDB connection issues

```bash
# Verify MongoDB is running
docker-compose ps mongodb

# Check health
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# Test from backend
docker-compose exec backend wget -O- http://localhost/health
```

### Redis connection issues

```bash
# Verify Redis is running
docker-compose ps redis

# Check health
docker-compose exec redis redis-cli ping

# View Redis memory
docker-compose exec redis redis-cli info memory
```

## Best Practices

### Development

- Use `docker-compose.yaml` for full local testing
- Keep `.env` checked in for consistency (with dummy values)
- Mount source code for hot reload (if configured)
- Use multiple terminal tabs for logs

### Production

- Use `.env.production` with actual AWS credentials
- Never commit `.env.production` to git
- Always tag images with version/commit SHA
- Use ECR for image storage
- Implement proper CI/CD pipeline
- Monitor CloudWatch Logs
- Set resource limits in docker-compose.prod.yml
- Regular security scanning with Trivy

### Security

- Never expose secrets in images
- Use Alpine for minimal attack surface
- Keep dependencies updated
- Scan images for vulnerabilities
- Run as non-root user in production
- Use CloudWatch encryption
- Implement rate limiting at ALB level

## Cleanup

```bash
# Stop containers
docker-compose down

# Remove volumes (CAUTION: deletes data)
docker-compose down -v

# Remove images
docker rmi starttech-backend:dev

# Clean up unused resources
docker system prune
```

## CI/CD Integration

The GitHub Actions workflow automatically:

1. Builds Docker image
2. Runs Trivy security scan
3. Pushes to ECR
4. Updates ASG instances

See `.github/workflows/backend-ci-cd.yml` for details.
