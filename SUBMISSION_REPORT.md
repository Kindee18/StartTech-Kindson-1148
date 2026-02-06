# StartTech "MuchToDo" Project Assessment - Submission Report

## 1. Executive Summary
This project implements a highly available, secure, and automated cloud infrastructure for the "MuchToDo" application. It features a modern React frontend and a robust Go backend, deployed on AWS using Terraform and GitHub Actions.

**Compliance Status:**
- **Infrastructure**: Fully automated with Terraform (state stored in S3).
- **Architecture**: 3-Tier Architecture (Frontend, Backend, Database) with separate VPC subnets.
- **CI/CD**: Fully automated pipelines for Testing, Security Scanning, and Deployment.
- **Security**: Least-privilege IAM roles, security groups, and HTTPS for frontend.

---

## 2. Resource Access

### Repository Links
| Component | Repository URL |
|-----------|----------------|
| **Application Code** | [https://github.com/Kindee18/StartTech-Kindson-1148](https://github.com/Kindee18/StartTech-Kindson-1148) |
| **Infrastructure Code** | [https://github.com/Kindee18/StartTech-Infra-Kindson-1148](https://github.com/Kindee18/StartTech-Infra-Kindson-1148) |

### Live Endpoints
| Service | URL | Status |
|---------|-----|--------|
| **Frontend (CloudFront)** | [https://d2e54px24win36.cloudfront.net](https://d2e54px24win36.cloudfront.net) | ✅ Active |
| **Backend API (ALB)** | [http://dev-alb-v2-886976968.us-east-1.elb.amazonaws.com](http://dev-alb-v2-886976968.us-east-1.elb.amazonaws.com) | ✅ Active |
| **Health Check** | [http://dev-alb-v2-886976968.us-east-1.elb.amazonaws.com/health](http://dev-alb-v2-886976968.us-east-1.elb.amazonaws.com/health) | ✅ JSON OK |

---

## 3. Architecture Overview

### Tech Stack
- **Frontend**: React (Vite) hosted on S3 + CloudFront CDN.
- **Backend**: Go (Gin Framework) running on EC2 via Docker.
- **Database**: MongoDB Atlas (M0 Cluster) for data persistence.
- **Cache**: AWS ElastiCache (Redis) for session/data caching.
- **Infrastructure**: AWS (VPC, ASG, ALB, S3, CodeDeploy) provisioned via Terraform.

### Infrastructure Design
- **Network**: Custom VPC (`10.0.0.0/16`) with Public and Private subnets across 2 Availability Zones (`us-east-1a`, `us-east-1b`).
- **Compute**: Auto Scaling Group (ASG) managing `t3.micro` instances.
- **Load Balancing**: Application Load Balancer (ALB) distributing traffic to healthy instances.
- **Storage**: S3 for frontend assets and Terraform state locking (DynamoDB).

### Key Decisions
- **Instance Type**: Selected `t3.micro` instead of `t3.medium` to adhere to AWS Free Tier limits while maintaining sufficient performance for the assessment workload.
- **Deployment Strategy**: Replaced rolling updates with **ASG Instance Refresh** for immutable infrastructure deployment, ensuring zero downtime.

---

## 4. CI/CD Pipelines

### Frontend Pipeline (`frontend-ci-cd.yml`)
1.  **Build & Test**: Installs dependencies, runs linting, and builds the React app.
2.  **Security**: Runs `npm audit` to check for dependency vulnerabilities.
3.  **Deploy**: Syncs build artifacts to S3 and invalidates CloudFront cache.

### Backend Pipeline (`backend-ci-cd.yml`)
1.  **Test**: Runs Go unit tests (`go test`) and linting (`golangci-lint`).
2.  **Security**: Scans the Docker image using **Trivy** for vulnerabilities (CRITICAL/HIGH).
3.  **Build**: Builds Docker image and pushes to AWS ECR with commit SHA tag.
4.  **Deploy**: Triggers an ASG Instance Refresh to roll out the new image version.

### Infrastructure Pipeline (`infrastructure-deploy.yml`)
1.  **Validate**: Checks Terraform formatting (`fmt`), validation (`validate`), and security (`tfsec`).
2.  **Apply**: Automatically applies infrastructure changes on merge to main.

---

## 5. Verification & Testing

### How we verified success:
1.  **Connectivity Check**: Confirmed frontend can fetch tasks from backend (`/api/tasks`).
2.  **Database check**: Verified MongoDB Atlas connection string and user permissions.
3.  **Load Test**: Verified ALB routes traffic to multiple instances.
4.  **Resiliency**: Terminated an instance and verified ASG launched a replacement immediately.

---

## 6. Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| **VPC Limit Exceeded** | Detected zombie VPCs from previous runs. Implemented `aws-nuke` to clean the account before rebuilding. |
| **Terraform State Drift** | Moved to remote S3 backend with DynamoDB locking to ensure team consistency. |
| **ALB Name Conflict** | Renamed ALB resource to `alb_v2` to fix a persistent Terraform provider state bug. |

---

**Generated on**: 2026-02-06
**Project Status**: COMPLETE (Green)
