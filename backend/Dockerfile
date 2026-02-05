# Multi-stage build for Go backend
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git make

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Copy and build logic
RUN go install github.com/swaggo/swag/cmd/swag@latest && \
    cd src && swag init -g cmd/api/main.go || true

# Build the application
RUN cd src && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ../main ./cmd/api

# Production stage - minimal image
FROM alpine:latest

WORKDIR /root/

# Install runtime dependencies for HTTPS and health checks
RUN apk --no-cache add ca-certificates wget

# Copy binary from builder
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["./main"]
