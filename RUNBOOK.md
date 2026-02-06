# StartTech MuchToDo Application - Operations Runbook

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [CI/CD Pipeline](#cicd-pipeline)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Deployment Procedures](#deployment-procedures)
6. [Monitoring & Logging](#monitoring--logging)
7. [Troubleshooting](#troubleshooting)
8. [Rollback Procedures](#rollback-procedures)
9. [Emergency Procedures](#emergency-procedures)

---

## System Overview

### Components

- **Frontend**: React SPA hosted on S3 with CloudFront CDN
- **Backend**: Go API running on EC2 instances with Auto Scaling
- **Database**: MongoDB Atlas cluster for data persistence
- **Cache**: AWS ElastiCache Redis for session/cache management
- **Load Balancer**: Application Load Balancer (ALB) for traffic distribution
- **CI/CD**: GitHub Actions for automated build and deployment
- **Registry**: ECR (Elastic Container Registry) for Docker images
- **Monitoring**: CloudWatch for logs, metrics, and alarms

### Environments

- **Development**: `develop` branch → dev resources
- **Staging**: Manual promotion to staging resources
- **Production**: `main` branch → production resources

---

## Architecture

```
CloudFront (CDN)
    ↓
S3 (Frontend Static Files)

Internet → ALB → EC2 Auto Scaling Group (Backend API)
    ↓                    ↓
HTTPS                ElastiCache Redis (Sessions)
                         ↓
                    MongoDB Atlas (Data)
```

### Infrastructure Components

#### Frontend Stack

- **S3 Bucket**: Stores minified React static files
- **CloudFront**: CDN for global content delivery
- **Cache Invalidation**: Automatic after deployments
- **HTTPS**: TLS/SSL via CloudFront

#### Backend Stack

- **EC2 Instances**: Runs Go application in Docker
- **ALB**: Routes traffic to healthy instances
- **Auto Scaling Group**: Scales 2-6 instances based on CPU
- **ECR**: Stores Docker images
- **Security Groups**: Restrict traffic to necessary ports
- **IAM Roles**: Grant permissions to access AWS services

#### Data Layer

- **MongoDB Atlas**: Cloud-hosted MongoDB for persistence
- **Redis ElastiCache**: In-memory cache for sessions and hot data
- **AWS Secrets Manager**: Stores credentials securely

#### Observability

- **CloudWatch Logs**: Centralized logging for all services
- **CloudWatch Metrics**: Performance and operational metrics
- **CloudWatch Alarms**: Alerts for critical conditions
- **CloudWatch Dashboard**: Visual monitoring of system health

- **VPC**: Isolated network environment
- **Subnets**: Public (ALB) and Private (EC2 instances)
- **Security Groups**: Restrict traffic between components
- **IAM Roles**: EC2 instance profiles for AWS service access

---

## CI/CD Pipeline

### Frontend Deployment Pipeline

**Trigger:** Push/PR to main or develop branch in Client/ directory

**Stages:**

1. **Test & Lint**
   - Setup Node.js 20
   - Install dependencies (`npm ci`)
   - Run ESLint (`npm run lint`)
   - Run unit tests (`npm run test`)
   - Security audit (`npm audit`)

2. **Build & Deploy** (Only on push to main/develop)
   - Configure AWS credentials
   - Set environment variables based on branch
   - Install dependencies
   - Build production bundle (`npm run build`)
   - Sync build files to S3 (with proper cache control headers)
   - Create CloudFront invalidation for CDN

3. **Health Checks**
   - Wait 30 seconds for deployment
   - Check website health (curl with retries)
   - Verify CloudFront cache invalidation

**Success Criteria:**

- All tests pass
- Security audit passes
- Build completes without errors
- S3 sync succeeds
- CloudFront invalidation succeeds
- Health checks pass

### Backend Deployment Pipeline

**Trigger:** Push/PR to main or develop branch in Server/ directory

**Stages:**

1. **Test & Scan**
   - Setup Go 1.25.1
   - Download dependencies
   - Run unit tests with race detection (`go test -race`)
   - Generate coverage report
   - Check code formatting (`gofmt`)
   - Run go vet for potential bugs
   - Security scan with gosec

2. **Build & Package** (Only on push to main/develop)
   - Build Go binary (Linux x86_64)
   - Login to ECR
   - Build Docker image
   - Scan image with Trivy for vulnerabilities
   - Push to ECR with tags: commit hash + environment + latest

3. **Deploy** (Only on push to main)
   - Get Auto Scaling Group name
   - Update ASG with new Docker image
   - Start instance refresh (rolling update)
   - Wait for deployment
   - Run smoke tests (health endpoint)


**Success Criteria:**

- All tests pass (50% code coverage minimum)
- Go vet passes
- Formatting is correct
- Docker image builds successfully
- Security scan passes
- Deployment succeeds
- Smoke tests pass

---

## GitHub Secrets Configuration

### Required Secrets for Application Repository

Add these secrets in GitHub Settings → Secrets and variables → Actions:

```
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=XXXXXXXXXXXX

# Frontend Deployment
S3_BUCKET_PROD=muchtodo-frontend-prod-ACCOUNT_ID
S3_BUCKET_STAGING=muchtodo-frontend-staging-ACCOUNT_ID
CLOUDFRONT_ID_PROD=E1234567890ABCDE
CLOUDFRONT_ID_STAGING=E0987654321XYZAB

# Backend Deployment
ECR_REPOSITORY_BACKEND=muchtodo-backend
CODEDEPLOY_APP=muchtodo-app
CODEDEPLOY_GROUP_PROD=muchtodo-prod-group
CODEDEPLOY_GROUP_STAGING=muchtodo-staging-group
CODEDEPLOY_S3_BUCKET=muchtodo-codedeploy-artifacts

# API Configuration
API_BASE_URL_PROD=https://api.muchtodo.com
API_BASE_URL_STAGING=https://api-staging.muchtodo.com
VITE_API_BASE_URL=${{ secrets.API_BASE_URL_PROD }}

# Database
MONGODB_HOST=mongodb.muchtodo.mongodb.net
MONGODB_PORT=27017
MONGODB_DATABASE=muchtodo

# Cache
REDIS_HOST=redis.XXXXXXXXXXXX.ng.0001.use1.cache.amazonaws.com
REDIS_PORT=6379


# OIDC
AWS_ROLE_ARN=arn:aws:iam::XXXXXXXXXXXX:role/github-actions-role
```

---

## GitHub Actions OIDC Setup

### What is OIDC?

OpenID Connect (OIDC) is a secure authentication mechanism that allows GitHub Actions to obtain short-lived credentials from AWS without storing long-term access keys. This is more secure than traditional AWS access key/secret key pairs.

### Benefits

- ✅ No long-term credentials stored in GitHub
- ✅ Automatic credential rotation
- ✅ Better audit trail via CloudTrail
- ✅ Fine-grained permissions per workflow
- ✅ Reduced blast radius if credentials are compromised

### Prerequisites

- AWS Account with appropriate permissions (IAM admin or equivalent)
- GitHub repository owner access
- AWS CLI installed locally (for scripting)

### Step 1: Create IAM OIDC Identity Provider

#### Option A: Using AWS Console

1. Go to **IAM** → **Identity providers** → **Add provider**
2. Select **OpenID Connect**
3. Enter Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Click **Add provider**

#### Option B: Using AWS CLI

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 1b511abead59c6ce207077c0bf4989c3477d8d54 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Note**: Thumbprints are AWS's GitHub Actions OIDC thumbprints. If they change, visit https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#updating-your-actions-for-oidc

### Step 2: Create IAM Role for GitHub Actions

#### Option A: Using AWS Console

1. Go to **IAM** → **Roles** → **Create role**
2. **Trusted entity type**: Choose **Web identity**
3. **Identity provider**: Select your OIDC provider (`token.actions.githubusercontent.com`)
4. **Audience**: `sts.amazonaws.com`
5. Add Trust Condition (Edit trust relationship):

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
				"StringEquals": {
					"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
				},
				"StringLike": {
					"token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_GITHUB_REPO:ref:refs/heads/*"
				}
			}
		}
	]
}
```

6. Attach the policy (see Step 3 below)
7. Name the role: `github-actions-role`

#### Option B: Using AWS CLI

```bash
# Replace these variables
AWS_ACCOUNT_ID="123456789012"
GITHUB_ORG="Kindee18"
GITHUB_REPO="StartTech-Kindson-1148"

# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name github-actions-role \
  --assume-role-policy-document file://trust-policy.json

# Get the role ARN for later
aws iam get-role --role-name github-actions-role --query 'Role.Arn' --output text
```

### Step 3: Create and Attach IAM Policy

Create a policy with minimum required permissions:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "S3FrontendDeployment",
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:DeleteObject",
				"s3:ListBucket",
				"s3:GetObject",
				"s3:GetBucketVersioning"
			],
			"Resource": [
				"arn:aws:s3:::muchtodo-frontend-staging",
				"arn:aws:s3:::muchtodo-frontend-staging/*",
				"arn:aws:s3:::muchtodo-frontend-prod",
				"arn:aws:s3:::muchtodo-frontend-prod/*"
			]
		},
		{
			"Sid": "CloudFrontInvalidation",
			"Effect": "Allow",
			"Action": ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"],
			"Resource": "*"
		},
		{
			"Sid": "ECRBackendDeployment",
			"Effect": "Allow",
			"Action": [
				"ecr:GetAuthorizationToken",
				"ecr:BatchGetImage",
				"ecr:GetDownloadUrlForLayer",
				"ecr:PutImage",
				"ecr:InitiateLayerUpload",
				"ecr:UploadLayerPart",
				"ecr:CompleteLayerUpload",
				"ecr:DescribeImages"
			],
			"Resource": "arn:aws:ecr:*:*:repository/muchtodo-*"
		},
		{
			"Sid": "CodeDeployDeployment",
			"Effect": "Allow",
			"Action": [
				"codedeploy:CreateDeployment",
				"codedeploy:GetDeployment",
				"codedeploy:GetDeploymentConfig",
				"codedeploy:ListDeployments",
				"codedeploy:StopDeployment",
				"codedeploy:WaitUntilDeploymentSuccessful"
			],
			"Resource": "*"
		},
		{
			"Sid": "S3CodeDeployArtifacts",
			"Effect": "Allow",
			"Action": ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
			"Resource": [
				"arn:aws:s3:::muchtodo-codedeploy-artifacts",
				"arn:aws:s3:::muchtodo-codedeploy-artifacts/*"
			]
		}
	]
}
```

#### Attach the policy using AWS CLI:

```bash
# Create inline policy
aws iam put-role-policy \
  --role-name github-actions-role \
  --policy-name github-actions-policy \
  --policy-document file://policy.json

# Or attach a managed policy if you created one
# aws iam attach-role-policy \
#   --role-name github-actions-role \
#   --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/github-actions-policy
```

### Step 4: Configure GitHub Secrets

In your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add `AWS_ROLE_ARN` with the value from Step 2
   - Example: `arn:aws:iam::123456789012:role/github-actions-role`
4. Add `AWS_REGION` with your AWS region
   - Example: `us-east-1`

### Step 5: Verify OIDC Configuration

Test the OIDC configuration by pushing a change:

```bash
git checkout develop
git add .
git commit -m "Test OIDC configuration"
git push origin develop
```

Check GitHub Actions:

- Go to **Actions** tab
- Click the workflow run
- Verify it authenticates with AWS without access key errors

### Troubleshooting OIDC Issues

**Error: "User: arn:aws:iam::... is not authorized to perform"**

- Verify the IAM policy has the required permissions
- Check resource ARNs match your S3 buckets and ECR repositories
- Review the Actions workflow output for exact action names

**Error: "ValidationError: The IAM role ARN is invalid"**

- Verify AWS_ROLE_ARN secret is set correctly
- Check role name exists in IAM console
- Ensure format is `arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME`

**Error: "No OIDC provider found"**

- Verify OIDC provider exists in IAM console
- Check provider URL is exactly `https://token.actions.githubusercontent.com`
- Verify thumbprints are correct

**Error: "AssumeRole failed with a trust relationship error"**

- Review trust relationship in role (see Step 2)
- Verify subject claim condition matches your GitHub org/repo
- Check audience is `sts.amazonaws.com`

### Maintenance

**Thumbprint Rotation**:
AWS may rotate GitHub's certificate thumbprints. Monitor:

- GitHub blog: https://github.blog/
- AWS documentation: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect

If thumbprints change:

```bash
aws iam update-open-id-connect-provider-thumbprint \
  --open-id-connect-provider-arn arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com \
  --thumbprint-list <new-thumbprints>
```

---

## CI/CD Pipeline

### Frontend Pipeline (`.github/workflows/frontend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches (paths: `Client/**`)

**Stages**:

1. **Test & Lint**
   - Install dependencies
   - Run ESLint
   - Execute unit tests
   - Security audit (`npm audit`)

2. **Build & Deploy**
   - Build production bundle
   - Sync to S3
   - Invalidate CloudFront cache
   - Send deployment notifications

**Environment Variables** (set per branch):

- `S3_BUCKET_STAGING` / `S3_BUCKET_PROD`
- `CLOUDFRONT_ID_STAGING` / `CLOUDFRONT_ID_PROD`
- `API_BASE_URL_STAGING` / `API_BASE_URL_PROD`

### Backend Pipeline (`.github/workflows/backend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches (paths: `Server/**`)

**Stages**:

1. **Test & Lint**
   - Run Go tests with race detector
   - Code formatting check (`gofmt`)
   - Static analysis (`go vet`)
   - Security scan (`gosec`)

2. **Build**
   - Build Docker image
   - Scan for vulnerabilities (Trivy)
   - Push to ECR
   - Tag: `latest`, `<environment>`, `<commit-sha>`

3. **Deploy**
   - Create deployment package (appspec.yml + scripts)
   - Upload to S3
   - Trigger CodeDeploy
   - Wait for deployment success
   - Run smoke tests

**Environment Variables** (set per branch):

- `ECR_REPOSITORY_BACKEND`
- `CODEDEPLOY_APP`
- `CODEDEPLOY_GROUP_STAGING` / `CODEDEPLOY_GROUP_PROD`
- `CODEDEPLOY_S3_BUCKET`
- `API_BASE_URL_STAGING` / `API_BASE_URL_PROD`

---

## Deployment Procedures

### Prerequisites

**GitHub Secrets** (Required):

```
AWS_ROLE_ARN                  # IAM role for GitHub OIDC
AWS_REGION                    # e.g., us-east-1

# Frontend
S3_BUCKET_STAGING
S3_BUCKET_PROD
CLOUDFRONT_ID_STAGING
CLOUDFRONT_ID_PROD
API_BASE_URL_STAGING
API_BASE_URL_PROD

# Backend
ECR_REPOSITORY_BACKEND
CODEDEPLOY_APP
CODEDEPLOY_GROUP_STAGING
CODEDEPLOY_GROUP_PROD
CODEDEPLOY_S3_BUCKET
```

### Automated Deployment

1. **Staging Deployment**

   ```bash
   git checkout develop
   git pull origin develop
   # Make changes
   git add .
   git commit -m "Your changes"
   git push origin develop
   ```

   Pipeline automatically deploys to staging.

2. **Production Deployment**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```
   Pipeline automatically deploys to production.

### Manual Deployment

**Frontend**:

```bash
./scripts/deploy-frontend.sh <environment> <s3-bucket> <cloudfront-id>

# Example - Staging
./scripts/deploy-frontend.sh staging my-frontend-staging-bucket E1234ABCDEF

# Example - Production
./scripts/deploy-frontend.sh production my-frontend-prod-bucket E5678GHIJKL
```

**Backend**:

```bash
./scripts/deploy-backend.sh <environment> <s3-key>

# Example
./scripts/deploy-backend.sh staging staging/backend-abc123-1234567890.zip
```

---

## Monitoring & Logging

### Health Checks

**Frontend**:

```bash
curl https://app.muchtodo.com/health
# Expected: 200 OK, "healthy"
```

**Backend**:

```bash
./scripts/health-check.sh https://api.muchtodo.com
# Or manually:
curl https://api.muchtodo.com/health
# Expected: 200 OK
```

### CloudWatch Logs

**Backend API Logs**:

- **Log Group**: `/aws/ec2/muchtodo-api`
- **Log Streams**: `<environment>-<hostname>`

**View Logs**:

```bash
aws logs tail /aws/ec2/muchtodo-api --follow --format short
```

**Query Logs** (CloudWatch Logs Insights):

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

### CloudWatch Alarms

Monitor these metrics:

- **ALB Target Health**: Unhealthy targets
- **EC2 CPU Utilization**: > 80%
- **API Latency**: > 1000ms
- **4xx/5xx Error Rates**: > 5%

### Application Metrics

**API Documentation**: `https://api.muchtodo.com/swagger/index.html`

---

## Troubleshooting

### Common Issues

#### 1. Frontend Not Loading

**Symptoms**: Blank page, 404 errors

**Diagnosis**:

```bash
# Check S3 bucket
aws s3 ls s3://<bucket-name>/

# Check CloudFront distribution
aws cloudfront get-distribution --id <distribution-id>
```

**Solutions**:

- Verify S3 bucket has correct files
- Check CloudFront distribution status (must be "Deployed")
- Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <id> --paths "/*"`

#### 2. Backend API Not Responding

**Symptoms**: 502/503 errors, timeouts

**Diagnosis**:

```bash
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=muchtodo-api-*" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]'

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check container logs
ssh ec2-user@<instance-ip>
docker logs muchtodo-api --tail 100
```

**Solutions**:

- Check EC2 instance health in Auto Scaling Group
- Verify security groups allow ALB → EC2 traffic (port 8080)
- Check application logs for errors
- Restart container: `docker restart muchtodo-api`

#### 3. CodeDeploy Deployment Failed

**Symptoms**: Deployment stuck or failed

**Diagnosis**:

```bash
# Get deployment details
aws deploy get-deployment --deployment-id <deployment-id>

# View deployment logs
aws deploy list-deployment-instances --deployment-id <deployment-id>
```

**Solutions**:

- Check CodeDeploy agent on EC2: `sudo service codedeploy-agent status`
- Review lifecycle event logs: `/var/log/aws/codedeploy-agent/`
- Verify IAM role has necessary permissions
- Check appspec.yml syntax

#### 4. Database Connection Issues

**Symptoms**: API returns 500 errors, "connection refused"

**Diagnosis**:

```bash
# Test MongoDB connection from EC2
docker exec -it muchtodo-api sh
# Inside container:
nc -zv <mongodb-host> 27017
```

**Solutions**:

- Verify MongoDB Atlas IP whitelist includes EC2 NAT Gateway IPs
- Check MongoDB connection string in environment variables
- Verify MongoDB Atlas cluster is running

#### 5. Redis Cache Issues

**Symptoms**: Slow API responses, cache misses

**Diagnosis**:

```bash
# Test Redis connection
docker exec -it muchtodo-api sh
nc -zv <redis-endpoint> 6379
```

**Solutions**:

- Check ElastiCache cluster status
- Verify security group allows EC2 → ElastiCache traffic (port 6379)
- Check Redis endpoint in environment variables

---

## Rollback Procedures

### Frontend Rollback

**Option 1: Using Script**

```bash
./scripts/rollback.sh frontend production
```

**Option 2: Manual S3 Versioning**

```bash
# List versions
aws s3api list-object-versions --bucket <bucket-name> --prefix index.html

# Restore previous version
aws s3api copy-object \
  --copy-source <bucket-name>/index.html?versionId=<version-id> \
  --bucket <bucket-name> \
  --key index.html

# Invalidate cache
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

**Prerequisite**: Enable S3 versioning

```bash
aws s3api put-bucket-versioning \
  --bucket <bucket-name> \
  --versioning-configuration Status=Enabled
```

### Backend Rollback

**Option 1: Using Script**

```bash
./scripts/rollback.sh backend production <deployment-id>
# If deployment-id is omitted, script finds last successful deployment
```

**Option 2: Manual CodeDeploy**

```bash
# Find last successful deployment
aws deploy list-deployments \
  --application-name <app-name> \
  --deployment-group-name <group-name> \
  --include-only-statuses Succeeded \
  --max-items 2

# Get deployment revision
aws deploy get-deployment --deployment-id <previous-deployment-id>

# Create rollback deployment
aws deploy create-deployment \
  --application-name <app-name> \
  --deployment-group-name <group-name> \
  --revision <previous-revision-json> \
  --description "Rollback to <deployment-id>"
```

**Option 3: ECR Image Rollback**

```bash
# List ECR images
aws ecr describe-images --repository-name <repo-name> --query 'sort_by(imageDetails,& imagePushedAt)[-5:]'

# Retag previous image as latest
aws ecr batch-get-image --repository-name <repo-name> --image-ids imageTag=<previous-tag> \
  --query 'images[0].imageManifest' --output text | \
  aws ecr put-image --repository-name <repo-name> --image-tag latest --image-manifest file:///dev/stdin

# Trigger new deployment or restart instances
```

### Emergency Stop

**Stop Ongoing Deployment**:

```bash
aws deploy stop-deployment \
  --deployment-id <deployment-id> \
  --auto-rollback-enabled
```

---

## Emergency Contacts

### Team Contacts

- **DevOps Lead**: devops@starttech.com
- **Backend Team**: backend@starttech.com
- **Frontend Team**: frontend@starttech.com
- **On-Call**: oncall@starttech.com

### Escalation

1. **L1**: DevOps Engineer (15 min response)
2. **L2**: Senior DevOps / Team Lead (30 min response)
3. **L3**: CTO / Engineering Director (1 hour response)

### External Services

- **AWS Support**: https://console.aws.amazon.com/support/
- **MongoDB Atlas Support**: https://cloud.mongodb.com/support
- **GitHub Support**: https://support.github.com/

---

## Best Practices

### Pre-Deployment Checklist

- [ ] All tests passing locally
- [ ] Code reviewed and approved
- [ ] Feature flags configured (if applicable)
- [ ] Database migrations tested
- [ ] Backup verification (MongoDB, Redis)
- [ ] Monitoring dashboards checked
- [ ] Rollback plan documented

### Post-Deployment Checklist

- [ ] Health checks passing
- [ ] CloudWatch alarms normal
- [ ] Application metrics normal
- [ ] Error rates within threshold
- [ ] User acceptance testing passed
- [ ] Documentation updated

### Security

- [ ] Never commit secrets to Git
- [ ] Use AWS Secrets Manager or SSM Parameter Store
- [ ] Rotate credentials regularly
- [ ] Enable MFA for AWS console access
- [ ] Review IAM policies for least privilege
- [ ] Monitor CloudTrail logs

---

## Additional Resources

- **Infrastructure Repository**: https://github.com/<org>/starttech-infra
- **Architecture Diagram**: See ARCHITECTURE.md
- **API Documentation**: https://api.muchtodo.com/swagger/index.html
- **Terraform Docs**: See starttech-infra/terraform/README.md

---

**Last Updated**: 2026-01-25
**Version**: 1.0.0
