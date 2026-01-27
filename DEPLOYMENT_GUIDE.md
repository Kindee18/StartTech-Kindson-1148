# Deployment Guide

Quick reference guide for deploying the StartTech MuchToDo application.

---

## Before You Deploy

### Prerequisites Checklist

- [ ] AWS infrastructure deployed (starttech-infra repository)
- [ ] All GitHub secrets configured (see [GITHUB_SECRETS.md](GITHUB_SECRETS.md))
- [ ] GitHub OIDC setup complete (see [RUNBOOK.md](RUNBOOK.md#github-actions-oidc-setup))
- [ ] Local development tested
- [ ] All tests passing

### Verification Commands

```bash
# Verify backend
cd Server/MuchToDo
go test -v ./...
go vet ./...
gofmt -l .  # Should output nothing

# Verify frontend
cd ../../Client
npm run lint
npm run test
npm run build
```

---

## Automated Deployment (Recommended)

### Staging Deployment

```bash
# Create/switch to develop branch
git checkout develop

# Make your changes and commit
git add .
git commit -m "Description of changes"

# Push to trigger pipeline
git push origin develop

# Monitor deployment
# Go to GitHub → Actions → Watch frontend-ci-cd and backend-ci-cd workflows
```

**Pipeline Steps**:

1. Test & Lint ✓
2. Build ✓
3. Deploy to S3 (frontend) / ECR (backend) ✓
4. Update EC2 instances (backend) ✓
5. Run smoke tests ✓

**Verify Deployment**:

```bash
# Check frontend
curl https://<CLOUDFRONT_STAGING_URL>

# Check backend health
curl https://<API_BASE_URL_STAGING>/health
curl https://<API_BASE_URL_STAGING>/swagger/index.html
```

### Production Deployment

```bash
# Switch to main and merge develop
git checkout main
git merge develop

# Push to trigger pipeline
git push origin main

# Monitor deployment (same as staging)
```

---

## Manual Deployment

### Frontend Manual Deployment

```bash
# Set environment variables
export AWS_REGION=us-east-1
export S3_BUCKET_STAGING=muchtodo-frontend-staging
export S3_BUCKET_PROD=muchtodo-frontend-prod
export CLOUDFRONT_ID_STAGING=E1234ABCDEF
export CLOUDFRONT_ID_PROD=E5678GHIJKL
export API_BASE_URL_STAGING=https://api-staging.example.com
export API_BASE_URL_PROD=https://api.example.com

# Deploy to staging
chmod +x scripts/deploy-frontend.sh
./scripts/deploy-frontend.sh staging $S3_BUCKET_STAGING $CLOUDFRONT_ID_STAGING

# Deploy to production
./scripts/deploy-frontend.sh production $S3_BUCKET_PROD $CLOUDFRONT_ID_PROD
```

### Backend Manual Deployment

```bash
# Build Docker image
cd Server/MuchToDo

# Build and tag image
docker build -t muchtodo-backend:latest .

# Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker tag muchtodo-backend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/muchtodo-backend:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/muchtodo-backend:latest

# Create deployment package
mkdir -p deployment
cp ../appspec.yml deployment/
cp -r ../scripts deployment/
cd deployment && zip -r ../deployment.zip . && cd ..

# Upload to S3 and create CodeDeploy deployment
TIMESTAMP=$(date +%s)
S3_KEY="staging/backend-$(git rev-parse --short HEAD)-${TIMESTAMP}.zip"
aws s3 cp deployment.zip s3://muchtodo-codedeploy-artifacts/${S3_KEY}

# Trigger CodeDeploy
aws deploy create-deployment \
  --application-name muchtodo-app \
  --deployment-group-name muchtodo-staging-deployment-group \
  --s3-location bucket=muchtodo-codedeploy-artifacts,key=${S3_KEY},bundleType=zip
```

---

## Deployment Verification

### Health Checks

```bash
# Frontend
curl -I https://<CLOUDFRONT_URL>/index.html

# Backend health endpoint
curl https://<API_URL>/health

# Backend API docs
curl https://<API_URL>/swagger/index.html
```

### CloudWatch Monitoring

1. Go to AWS CloudWatch console
2. Check log groups:
   - `/aws/s3/muchtodo-frontend-*`
   - `/aws/ec2/muchtodo-api`
3. Verify no error spikes
4. Check CloudWatch Alarms are green

### Application Testing

1. Navigate to frontend URL
2. Create an account
3. Log in
4. Create a task
5. Verify task appears in the list
6. Edit task
7. Delete task
8. Log out

---

## Rollback Procedures

### Frontend Rollback

**Using Script** (Requires S3 versioning enabled):

```bash
chmod +x scripts/rollback.sh
./scripts/rollback.sh frontend staging
# Or for production:
./scripts/rollback.sh frontend production
```

**Manual Rollback**:

```bash
# List previous versions
aws s3api list-object-versions --bucket muchtodo-frontend-staging --prefix index.html

# Restore specific version
aws s3api copy-object \
  --bucket muchtodo-frontend-staging \
  --copy-source muchtodo-frontend-staging/index.html?versionId=<VERSION_ID> \
  --key index.html

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234ABCDEF \
  --paths "/*"
```

### Backend Rollback

**Using Script**:

```bash
./scripts/rollback.sh backend staging
# Or with specific deployment ID:
./scripts/rollback.sh backend production d-12345ABCDE
```

**Manual Rollback**:

```bash
# Find previous deployment
aws deploy list-deployments \
  --application-name muchtodo-app \
  --deployment-group-name muchtodo-staging-deployment-group \
  --include-only-statuses Succeeded \
  --max-items 2

# Get deployment details
aws deploy get-deployment --deployment-id <PREVIOUS_DEPLOYMENT_ID>

# Create rollback deployment with previous revision
aws deploy create-deployment \
  --application-name muchtodo-app \
  --deployment-group-name muchtodo-staging-deployment-group \
  --revision <PREVIOUS_REVISION_JSON>
```

---

## Monitoring During Deployment

### GitHub Actions

1. Go to **Actions** tab in your repository
2. Click the workflow run
3. View logs for each step:
   - Check lint results
   - Verify build succeeded
   - Confirm deployment steps completed
   - Review smoke test results

### CloudWatch Logs

```bash
# View recent logs
aws logs tail /aws/ec2/muchtodo-api --follow

# Get logs for specific time range
aws logs get-log-events \
  --log-group-name /aws/ec2/muchtodo-api \
  --log-stream-name staging-<instance-id> \
  --start-time $(date -d '10 minutes ago' +%s)000
```

### Application Performance

```bash
# Get ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average,Maximum

# Get EC2 metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

---

## Troubleshooting Deployments

### Frontend Deployment Fails

**Issue**: "S3 bucket not found"

- Verify `S3_BUCKET_STAGING` and `S3_BUCKET_PROD` secrets are correct
- Check bucket exists in AWS S3 console
- Verify IAM role has S3 permissions

**Issue**: "CloudFront invalidation failed"

- Verify `CLOUDFRONT_ID_STAGING` and `CLOUDFRONT_ID_PROD` are correct
- Check CloudFront distributions exist
- Verify IAM role has CloudFront permissions

**Issue**: "Files not updating"

- Check S3 cache-control headers
- Verify CloudFront invalidation succeeded
- Clear browser cache (Ctrl+Shift+Delete)

### Backend Deployment Fails

**Issue**: "ECR authentication failed"

- Verify `ECR_REPOSITORY_BACKEND` secret is correct
- Check ECR repository exists
- Verify IAM role has ECR permissions

**Issue**: "CodeDeploy deployment failed"

- Check EC2 instances have CodeDeploy agent running
- Verify `appspec.yml` is valid
- Check scripts have proper permissions
- Review CodeDeploy logs in AWS console

**Issue**: "Health check failing after deployment"

- Check backend logs: `docker logs muchtodo-api`
- Verify database connection string
- Check Redis connection
- Review security groups allow traffic

---

## Best Practices

1. **Always test in staging first**
   - Verify all functionality works
   - Monitor logs and metrics
   - Get stakeholder approval

2. **Commit meaningful messages**

   ```bash
   git commit -m "feat: Add new task filtering

   - Implement task filtering by status
   - Add filter UI component
   - Update API endpoint

   Closes #123"
   ```

3. **Use feature branches**

   ```bash
   git checkout -b feature/task-filtering
   # Make changes
   git push origin feature/task-filtering
   # Create pull request for code review
   ```

4. **Monitor after deployment**
   - Watch CloudWatch logs for 15 minutes
   - Check application metrics
   - Monitor error rates
   - Be ready to rollback if issues arise

5. **Document changes**
   - Update CHANGELOG
   - Document database migrations
   - Document configuration changes
   - Update API documentation

---

## Emergency Procedures

### Stop All Deployments

```bash
# Stop frontend deployment (it's immediate, no action needed)

# Stop backend deployment
aws deploy stop-deployment \
  --deployment-id <DEPLOYMENT_ID> \
  --auto-rollback-enabled
```

### Rollback to Last Working Version

```bash
# Frontend
./scripts/rollback.sh frontend production

# Backend
./scripts/rollback.sh backend production
```

### Emergency Stop of Service

```bash
# Stop EC2 instances (will trigger health check failures)
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Or terminate Auto Scaling Group
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name muchtodo-asg-prod \
  --max-size 0 \
  --desired-capacity 0
```

---

## Post-Deployment Checklist

- [ ] Health checks pass
- [ ] CloudWatch logs show no errors
- [ ] Application metrics normal
- [ ] Error rates within threshold
- [ ] User acceptance testing passed
- [ ] No alerts in CloudWatch Alarms
- [ ] Documentation updated
- [ ] Stakeholders notified

---

## Support and Help

- **Documentation**: [RUNBOOK.md](RUNBOOK.md)
- **Setup**: [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- **Secrets**: [GITHUB_SECRETS.md](GITHUB_SECRETS.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Last Updated**: 2026-01-26
**Version**: 1.0.0
