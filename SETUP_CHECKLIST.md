# First-Time Setup Checklist

This checklist ensures you have everything needed to deploy the StartTech MuchToDo application.

## Prerequisites

- [ ] AWS Account with appropriate IAM permissions
- [ ] GitHub account with access to fork the repository
- [ ] Git installed locally
- [ ] AWS CLI installed and configured
- [ ] Node.js 20+ installed
- [ ] Go 1.21+ installed
- [ ] Docker installed (for local testing)

## Repository Setup

- [ ] Fork the `StartTech-Kindson-1148` repository
- [ ] Clone your fork locally: `git clone https://github.com/YOUR_USERNAME/StartTech-Kindson-1148.git`
- [ ] Configure Git user: `git config user.email "you@example.com" && git config user.name "Your Name"`

## AWS Infrastructure Prerequisites

Before deploying the application, deploy the infrastructure using the separate `starttech-infra` repository:

- [ ] Clone and deploy `starttech-infra` repository
- [ ] Create S3 buckets:
  - [ ] `muchtodo-frontend-staging`
  - [ ] `muchtodo-frontend-prod`
  - [ ] `muchtodo-codedeploy-artifacts`
- [ ] Create CloudFront distributions for both buckets
- [ ] Create ECR repository: `muchtodo-backend`
- [ ] Create CodeDeploy application: `muchtodo-app`
- [ ] Create CodeDeploy deployment groups:
  - [ ] `muchtodo-staging-deployment-group`
  - [ ] `muchtodo-prod-deployment-group`
- [ ] Set up MongoDB Atlas cluster
- [ ] Set up ElastiCache Redis cluster
- [ ] Create ALB and EC2 Auto Scaling Group

## GitHub Actions OIDC Setup

- [ ] Create AWS IAM OIDC identity provider (see [RUNBOOK.md](RUNBOOK.md#github-actions-oidc-setup))
- [ ] Create GitHub Actions IAM role with appropriate permissions
- [ ] Note the role ARN for GitHub secrets configuration

## GitHub Repository Configuration

### Enable GitHub Actions

- [ ] Go to repository Settings → Actions → General
- [ ] Ensure "Actions permissions" is set to "Allow all actions and reusable workflows"
- [ ] Ensure "Workflow permissions" has both:
  - [ ] `contents: read`
  - [ ] `id-token: write`

### Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

**AWS Configuration** (Required):

- [ ] `AWS_ROLE_ARN` - IAM role ARN from OIDC setup
- [ ] `AWS_REGION` - e.g., `us-east-1`

**Frontend Secrets** (Required):

- [ ] `S3_BUCKET_STAGING` - Staging frontend S3 bucket
- [ ] `S3_BUCKET_PROD` - Production frontend S3 bucket
- [ ] `CLOUDFRONT_ID_STAGING` - Staging CloudFront distribution ID
- [ ] `CLOUDFRONT_ID_PROD` - Production CloudFront distribution ID
- [ ] `API_BASE_URL_STAGING` - Staging backend URL
- [ ] `API_BASE_URL_PROD` - Production backend URL

**Backend Secrets** (Required):

- [ ] `ECR_REPOSITORY_BACKEND` - ECR repository name/URI
- [ ] `CODEDEPLOY_APP` - CodeDeploy application name
- [ ] `CODEDEPLOY_GROUP_STAGING` - CodeDeploy staging deployment group
- [ ] `CODEDEPLOY_GROUP_PROD` - CodeDeploy production deployment group
- [ ] `CODEDEPLOY_S3_BUCKET` - S3 bucket for CodeDeploy artifacts

See [GITHUB_SECRETS.md](GITHUB_SECRETS.md) for detailed secret descriptions.

## Local Development Setup

### Backend Setup

```bash
cd Server/MuchToDo
cp .env.example .env
# Edit .env with your local settings
go mod download
docker-compose up -d  # Starts MongoDB and Redis
make run             # Or: go run cmd/api/main.go
```

- [ ] Backend runs without errors
- [ ] Health check works: `curl http://localhost:8080/health`
- [ ] Swagger docs accessible: `http://localhost:8080/swagger/index.html`

### Frontend Setup

```bash
cd Client
cp .env.example .env
npm install
npm run dev
```

- [ ] Frontend runs without errors
- [ ] Can access at `http://localhost:5173`
- [ ] Linter passes: `npm run lint`
- [ ] Tests pass: `npm run test`

## Testing

### Run Backend Tests

```bash
cd Server/MuchToDo
go test -v ./...
```

- [ ] All tests pass
- [ ] Code formatting correct: `gofmt -l .`
- [ ] No vet issues: `go vet ./...`

### Run Frontend Tests

```bash
cd Client
npm run test
npm run lint
npm run build
```

- [ ] All tests pass
- [ ] No lint errors
- [ ] Build completes successfully

## First Deployment

### Staging Deployment

1. **Create develop branch**:

   ```bash
   git checkout -b develop
   git push origin develop
   ```

2. **Push to develop**:

   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin develop
   ```

3. **Monitor deployment**:
   - [ ] Go to GitHub Actions tab
   - [ ] Watch frontend-ci-cd workflow
   - [ ] Watch backend-ci-cd workflow
   - [ ] Both workflows complete successfully

4. **Verify deployment**:
   - [ ] Frontend accessible at staging CloudFront URL
   - [ ] Backend health check passes: `curl https://API_BASE_URL_STAGING/health`
   - [ ] Can log in and create tasks

### Production Deployment

1. **Create main branch**:

   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. **Monitor deployment**:
   - [ ] Go to GitHub Actions tab
   - [ ] Watch frontend-ci-cd workflow
   - [ ] Watch backend-ci-cd workflow
   - [ ] Both workflows complete successfully

3. **Verify deployment**:
   - [ ] Frontend accessible at production CloudFront URL
   - [ ] Backend health check passes: `curl https://API_BASE_URL_PROD/health`
   - [ ] Can log in and create tasks in production

## Monitoring Setup

- [ ] CloudWatch Logs configured for application logging
- [ ] CloudWatch alarms set up for critical metrics:
  - [ ] High CPU usage
  - [ ] High memory usage
  - [ ] Failed health checks
  - [ ] High error rates

## Documentation

- [ ] Read [README.md](README.md) - Overview and getting started
- [ ] Read [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [ ] Read [RUNBOOK.md](RUNBOOK.md) - Operations guide
- [ ] Read [GITHUB_SECRETS.md](GITHUB_SECRETS.md) - Secrets setup guide

## Continuous Deployment Workflow

Once setup is complete, the workflow is:

1. **Development**: Make changes in feature branches
2. **Testing**: Push to develop branch for staging deployment
   - Automated tests run
   - Builds created
   - Deployed to staging
   - Smoke tests verify deployment
3. **Production**: Merge develop to main for production deployment
   - Same automated tests and deployment process
   - Production resources used

## Troubleshooting

If you encounter issues:

1. Check [RUNBOOK.md](RUNBOOK.md#troubleshooting) for troubleshooting guide
2. Review GitHub Actions logs in the Actions tab
3. Check CloudWatch logs in AWS console
4. Review health check scripts: `./scripts/health-check.sh <url>`

## Additional Resources

- **Infrastructure Repository**: starttech-infra
- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Go Documentation**: https://go.dev/doc/
- **React Documentation**: https://react.dev/

## Getting Help

- Check README.md FAQ section (if available)
- Review RUNBOOK.md for common issues
- Check GitHub Issues for your repository
- Contact DevOps team: devops@starttech.com

---

**Estimated Setup Time**: 2-4 hours (depending on AWS infrastructure setup)

**Last Updated**: 2026-01-26
