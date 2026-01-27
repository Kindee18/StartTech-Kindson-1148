# GitHub Secrets Configuration

This document describes all the required GitHub Actions secrets that need to be configured in your repository to enable the CI/CD pipelines.

## Setup Instructions

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below with its corresponding value

---

## Required Secrets

### AWS Configuration

**AWS_ROLE_ARN**

- **Description**: ARN of the IAM role for GitHub OIDC authentication
- **Example**: `arn:aws:iam::123456789012:role/github-actions-role`
- **Required for**: Frontend CI/CD, Backend CI/CD
- **How to get**:
  1. Create an IAM role with OIDC provider trust relationship
  2. Copy the role ARN from IAM console
  3. See RUNBOOK.md for detailed OIDC setup instructions

**AWS_REGION**

- **Description**: AWS region where resources are deployed
- **Example**: `us-east-1`
- **Required for**: All pipelines
- **Options**: `us-east-1`, `us-west-2`, `eu-west-1`, etc.

---

### Frontend Secrets

**S3_BUCKET_STAGING**

- **Description**: S3 bucket name for staging frontend assets
- **Example**: `muchtodo-frontend-staging`
- **Required for**: Frontend CI/CD (develop branch)
- **Note**: Bucket must have static website hosting enabled

**S3_BUCKET_PROD**

- **Description**: S3 bucket name for production frontend assets
- **Example**: `muchtodo-frontend-prod`
- **Required for**: Frontend CI/CD (main branch)
- **Note**: Bucket must have static website hosting enabled

**CLOUDFRONT_ID_STAGING**

- **Description**: CloudFront distribution ID for staging
- **Example**: `E1A2B3C4D5E6F`
- **Required for**: Frontend CI/CD (develop branch)
- **How to get**: CloudFront console → Distribution ID column

**CLOUDFRONT_ID_PROD**

- **Description**: CloudFront distribution ID for production
- **Example**: `E9Z8Y7X6W5V4U`
- **Required for**: Frontend CI/CD (main branch)
- **How to get**: CloudFront console → Distribution ID column

**API_BASE_URL_STAGING**

- **Description**: Backend API base URL for staging environment
- **Example**: `https://api-staging.muchtodo.com` or `https://staging-alb-123456.us-east-1.elb.amazonaws.com`
- **Required for**: Frontend CI/CD (develop branch)
- **Note**: Used as VITE_API_BASE_URL environment variable

**API_BASE_URL_PROD**

- **Description**: Backend API base URL for production environment
- **Example**: `https://api.muchtodo.com` or `https://prod-alb-789012.us-east-1.elb.amazonaws.com`
- **Required for**: Frontend CI/CD (main branch)
- **Note**: Used as VITE_API_BASE_URL environment variable

---

### Backend Secrets

**ECR_REPOSITORY_BACKEND**

- **Description**: Amazon ECR repository name for backend Docker images
- **Example**: `muchtodo-backend` or `123456789012.dkr.ecr.us-east-1.amazonaws.com/muchtodo-backend`
- **Required for**: Backend CI/CD
- **How to get**:
  1. AWS ECR console
  2. Create a repository named `muchtodo-backend`
  3. Copy the repository name or full URI

**CODEDEPLOY_APP**

- **Description**: AWS CodeDeploy application name
- **Example**: `muchtodo-app`
- **Required for**: Backend CI/CD
- **How to get**:
  1. AWS CodeDeploy console → Applications
  2. Create an application named `muchtodo-app`
  3. Copy the application name

**CODEDEPLOY_GROUP_STAGING**

- **Description**: CodeDeploy deployment group for staging
- **Example**: `muchtodo-staging-deployment-group`
- **Required for**: Backend CI/CD (develop branch)
- **How to get**:
  1. AWS CodeDeploy console → Applications → muchtodo-app
  2. Create deployment group for staging
  3. Copy the deployment group name

**CODEDEPLOY_GROUP_PROD**

- **Description**: CodeDeploy deployment group for production
- **Example**: `muchtodo-prod-deployment-group`
- **Required for**: Backend CI/CD (main branch)
- **How to get**:
  1. AWS CodeDeploy console → Applications → muchtodo-app
  2. Create deployment group for production
  3. Copy the deployment group name

**CODEDEPLOY_S3_BUCKET**

- **Description**: S3 bucket for CodeDeploy deployment artifacts
- **Example**: `muchtodo-codedeploy-artifacts`
- **Required for**: Backend CI/CD
- **Note**: CodeDeploy will upload deployment packages here

---

## Secret Management Best Practices

### 🔒 Security Guidelines

1. **Never commit secrets to Git**
   - Use `.env.example` for placeholder values
   - Add sensitive files to `.gitignore`

2. **Rotate secrets regularly**
   - Schedule quarterly secret rotations
   - Update GitHub secrets immediately after rotation

3. **Use IAM Roles over Access Keys**
   - Prefer OIDC authentication for GitHub Actions
   - Use temporary credentials via STS AssumeRole

4. **Least Privilege Access**
   - IAM role should only have necessary permissions
   - Use inline policies, not `AdministratorAccess`

5. **Audit secret access**
   - Enable CloudTrail for IAM role usage
   - Monitor GitHub Actions logs for secret usage

6. **Separate staging and production secrets**
   - Different S3 buckets per environment
   - Different CloudFront distributions per environment
   - Different CodeDeploy groups per environment

---

## Verification Checklist

Before running the pipelines, verify all secrets are configured:

- [ ] AWS_ROLE_ARN
- [ ] AWS_REGION
- [ ] S3_BUCKET_STAGING
- [ ] S3_BUCKET_PROD
- [ ] CLOUDFRONT_ID_STAGING
- [ ] CLOUDFRONT_ID_PROD
- [ ] API_BASE_URL_STAGING
- [ ] API_BASE_URL_PROD
- [ ] ECR_REPOSITORY_BACKEND
- [ ] CODEDEPLOY_APP
- [ ] CODEDEPLOY_GROUP_STAGING
- [ ] CODEDEPLOY_GROUP_PROD
- [ ] CODEDEPLOY_S3_BUCKET

---

## Troubleshooting

### "Authentication failed" error

- Verify AWS_ROLE_ARN is correct
- Check OIDC provider is configured in AWS IAM
- Ensure GitHub Actions has OIDC permissions enabled

### "Access Denied" error

- Review IAM role permissions
- Ensure role has access to required AWS services (S3, ECR, CodeDeploy, CloudFront)
- Check resource ARNs in IAM policy

### "S3 bucket not found" error

- Verify S3_BUCKET_STAGING and S3_BUCKET_PROD secret values
- Ensure buckets exist and are accessible by the IAM role
- Check bucket names match the created buckets

### "CodeDeploy deployment failed" error

- Verify CODEDEPLOY_APP and deployment group names are correct
- Check EC2 instances have CodeDeploy agent installed
- Review CodeDeploy logs in AWS console

---

## Related Documentation

- [RUNBOOK.md](RUNBOOK.md) - OIDC setup and operations guide
- [README.md](README.md) - General CI/CD pipeline overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture details

---

**Last Updated**: 2026-01-26
