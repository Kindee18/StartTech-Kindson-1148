include .env
export $(shell sed 's/=.*//' .env)

run: generate-docs
	go run ./cmd/api/main.go

build:
	go build -o much-to-do ./cmd/api/main.go
	mv much-to-do ./bin/much-to-do

clean:
	rm -f ./bin/much-to-do

tidy:
	go mod tidy

# Docker targets
docker-build-dev:
	docker build -f Dockerfile -t starttech-backend:dev .

docker-build-prod:
	docker build -f Dockerfile.prod -t starttech-backend:latest .

docker-build-prod-tag:
	@read -p "Enter image tag (e.g., v1.0.0): " tag; \
	docker build -f Dockerfile.prod -t starttech-backend:$$tag -t starttech-backend:latest .

docker-push-ecr:
	@read -p "Enter AWS account ID: " account_id; \
	read -p "Enter AWS region (default: us-east-1): " region; \
	region=$${region:-us-east-1}; \
	aws ecr get-login-password --region $$region | docker login --username AWS --password-stdin $$account_id.dkr.ecr.$$region.amazonaws.com; \
	docker tag starttech-backend:latest $$account_id.dkr.ecr.$$region.amazonaws.com/starttech-backend:latest; \
	docker push $$account_id.dkr.ecr.$$region.amazonaws.com/starttech-backend:latest

docker-scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image starttech-backend:latest

# Docker Compose targets
dc-up:
	docker-compose -f docker-compose.yaml up -d --build

dc-up-prod:
	docker-compose -f docker-compose.prod.yml up -d

dc-restart:
	docker-compose -f docker-compose.yaml restart

dc-down:
	docker-compose -f docker-compose.yaml down

dc-down-prod:
	docker-compose -f docker-compose.prod.yml down

dc-logs:
	docker-compose -f docker-compose.yaml logs -f backend

dc-logs-prod:
	docker-compose -f docker-compose.prod.yml logs -f backend

dc-ps:
	docker-compose -f docker-compose.yaml ps

# Generation and testing
generate-docs:
	swag init -g ./cmd/api/main.go -o ./docs

unit-test:
	go test -v ./...

integration-test:
	go test -tags=integration -v ./...

# Help
help:
	@echo "StartTech Backend Makefile"
	@echo ""
	@echo "Development:"
	@echo "  make run                 - Run application locally"
	@echo "  make build               - Build binary"
	@echo "  make unit-test           - Run unit tests"
	@echo "  make integration-test    - Run integration tests"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build-dev    - Build development Docker image"
	@echo "  make docker-build-prod   - Build production Docker image"
	@echo "  make docker-scan         - Scan image with Trivy"
	@echo "  make docker-push-ecr     - Push image to ECR"
	@echo ""
	@echo "Docker Compose:"
	@echo "  make dc-up               - Start dev environment"
	@echo "  make dc-up-prod          - Start prod environment"
	@echo "  make dc-down             - Stop dev environment"
	@echo "  make dc-logs             - View dev logs"
	@echo "  make dc-ps               - Show running containers"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean               - Remove binary"
	@echo "  make tidy                - Tidy go.mod"

.PHONY: run build clean tidy docker-build-dev docker-build-prod docker-scan \
	docker-push-ecr dc-up dc-up-prod dc-down dc-logs dc-logs-prod dc-ps \
	generate-docs unit-test integration-test help
