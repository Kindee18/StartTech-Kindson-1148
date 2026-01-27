# Quick Reference Card

## Essential Links & Commands

### Documentation

| Document                                   | Purpose                                 |
| ------------------------------------------ | --------------------------------------- |
| [README.md](README.md)                     | Project overview and quick start        |
| [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)   | First-time setup verification           |
| [GITHUB_SECRETS.md](GITHUB_SECRETS.md)     | GitHub secrets configuration            |
| [RUNBOOK.md](RUNBOOK.md)                   | Operations, OIDC setup, troubleshooting |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Deployment procedures                   |
| [ARCHITECTURE.md](ARCHITECTURE.md)         | System architecture diagram             |

---

## Quick Setup (5 minutes)

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/StartTech-Kindson-1148.git
cd StartTech-Kindson-1148

# 2. Setup backend
cd Server/MuchToDo
cp .env.example .env
docker-compose up -d
go run ./cmd/api/main.go

# 3. Setup frontend (new terminal)
cd Client
cp .env.example .env
npm install
npm run dev

# 4. Verify
curl http://localhost:8080/health
open http://localhost:5173
```

---

## Deployment Cheat Sheet

### Staging Deploy

```bash
git checkout develop
git add . && git commit -m "changes"
git push origin develop
# Wait for GitHub Actions to complete
```

### Production Deploy

```bash
git checkout main
git merge develop
git push origin main
# Wait for GitHub Actions to complete
```

### Manual Frontend Deploy

```bash
cd Client
export S3_BUCKET=muchtodo-frontend-staging
export CLOUDFRONT_ID=E1234ABCDEF
./scripts/deploy-frontend.sh staging $S3_BUCKET $CLOUDFRONT_ID
```

### Manual Backend Deploy

```bash
export S3_KEY=staging/backend-$(git rev-parse --short HEAD).zip
./scripts/deploy-backend.sh staging $S3_KEY
```

---

## Verification Commands

### Health Checks

```bash
# Frontend (local)
curl http://localhost:5173

# Backend (local)
curl http://localhost:8080/health

# Backend (staging)
curl https://api-staging.muchtodo.com/health

# Backend (production)
curl https://api.muchtodo.com/health
```

### Run Tests

```bash
# Backend
cd Server/MuchToDo
go test -v ./...

# Frontend
cd Client
npm run test
npm run lint
npm run build
```

### View Logs

```bash
# Backend logs
aws logs tail /aws/ec2/muchtodo-api --follow

# Docker logs
docker logs muchtodo-api

# Frontend build
npm run build
```

---

## GitHub Secrets (Required)

### AWS

```
AWS_ROLE_ARN          arn:aws:iam::123456789012:role/github-actions-role
AWS_REGION            us-east-1
```

### Frontend

```
S3_BUCKET_STAGING     muchtodo-frontend-staging
S3_BUCKET_PROD        muchtodo-frontend-prod
CLOUDFRONT_ID_STAGING E1234ABCDEF
CLOUDFRONT_ID_PROD    E5678GHIJKL
API_BASE_URL_STAGING  https://api-staging.muchtodo.com
API_BASE_URL_PROD     https://api.muchtodo.com
```

### Backend

```
ECR_REPOSITORY_BACKEND              muchtodo-backend
CODEDEPLOY_APP                      muchtodo-app
CODEDEPLOY_GROUP_STAGING            muchtodo-staging-deployment-group
CODEDEPLOY_GROUP_PROD               muchtodo-prod-deployment-group
CODEDEPLOY_S3_BUCKET                muchtodo-codedeploy-artifacts
```

---

## Troubleshooting Quick Fixes

| Issue                            | Solution                                                  |
| -------------------------------- | --------------------------------------------------------- |
| "Tests fail locally"             | Delete node_modules: `rm -rf node_modules && npm install` |
| "Port 8080 already in use"       | Kill process: `lsof -ti:8080 \| xargs kill -9`            |
| "Docker container won't start"   | Check logs: `docker logs muchtodo-api`                    |
| "S3 sync failed"                 | Check IAM permissions and region                          |
| "CloudFront invalidation failed" | Verify distribution ID is correct                         |
| "CodeDeploy failed"              | Check EC2 has CodeDeploy agent running                    |
| "Health check failing"           | Check database/Redis connection strings                   |

---

## Rollback Quick Commands

```bash
# Frontend rollback
./scripts/rollback.sh frontend production

# Backend rollback
./scripts/rollback.sh backend production
```

---

## AWS Resources (Check These First)

1. **S3 Buckets**: https://s3.console.aws.amazon.com/
   - `muchtodo-frontend-staging`
   - `muchtodo-frontend-prod`
   - `muchtodo-codedeploy-artifacts`

2. **CloudFront**: https://console.aws.amazon.com/cloudfront/
   - Staging distribution (CloudFront ID: ...)
   - Production distribution (CloudFront ID: ...)

3. **ECR**: https://console.aws.amazon.com/ecr/
   - `muchtodo-backend` repository

4. **CodeDeploy**: https://console.aws.amazon.com/codedeploy/
   - Application: `muchtodo-app`
   - Deployment groups: `muchtodo-staging-deployment-group`, `muchtodo-prod-deployment-group`

5. **EC2**: https://console.aws.amazon.com/ec2/
   - Check instances are running
   - Verify Auto Scaling Group

6. **CloudWatch**: https://console.aws.amazon.com/cloudwatch/
   - View logs: `/aws/ec2/muchtodo-api`
   - Check alarms for errors

7. **RDS/MongoDB Atlas**: https://cloud.mongodb.com/
   - Check cluster is running

8. **ElastiCache**: https://console.aws.amazon.com/elasticache/
   - Check Redis cluster is running

---

## GitHub Actions Monitoring

1. Go to **Actions** tab
2. Click the workflow run
3. Expand job logs to see:
   - ✅ Test status
   - ✅ Build status
   - ✅ Deploy status
   - ✅ Smoke test results

---

## Contact & Help

- **Documentation**: See [RUNBOOK.md](RUNBOOK.md)
- **Setup Issues**: See [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- **Secrets Help**: See [GITHUB_SECRETS.md](GITHUB_SECRETS.md)
- **Deployment Issues**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Key Workflows

### Daily Development

```
Make changes → Test locally → Commit → Push develop → Staging deploys automatically
```

### Release to Production

```
Merge develop → main → Production deploys automatically
```

### Emergency Rollback

```
./scripts/rollback.sh [component] [environment] → Previous version deployed
```

---

**Last Updated**: 2026-01-26

**Pro Tip**: Bookmark this page for quick reference during deployments!
