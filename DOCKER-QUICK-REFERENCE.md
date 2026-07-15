# Docker Quick Reference Guide

## 🚀 Essential Docker Commands

### **Image Management**

```bash
# Build image
docker build -t cnas-php-app:v1 .

# Build without cache (fresh build)
docker build --no-cache -t cnas-php-app:v1 .

# List images
docker images

# Remove image
docker rmi cnas-php-app:v1

# Tag image
docker tag cnas-php-app:v1 yourdockerhub/cnas-php-app:v1

# Push to registry
docker push yourdockerhub/cnas-php-app:v1

# Pull from registry
docker pull yourdockerhub/cnas-php-app:v1

# Inspect image layers
docker history cnas-php-app:v1

# Save image to tar
docker save -o cnas-php-app.tar cnas-php-app:v1

# Load image from tar
docker load -i cnas-php-app.tar
```

### **Container Management**

```bash
# Run container
docker run -d -p 8080:80 --name my-app cnas-php-app:v1

# Run with environment variables
docker run -d -p 8080:80 \
  -e DB_HOST=mysql \
  -e DB_USER=appuser \
  -e DB_PASSWORD=apppass \
  --name my-app cnas-php-app:v1

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop container
docker stop my-app

# Start stopped container
docker start my-app

# Restart container
docker restart my-app

# Remove container
docker rm my-app

# Remove running container (force)
docker rm -f my-app

# View container logs
docker logs my-app

# Follow logs in real-time
docker logs -f my-app

# View last 100 lines
docker logs --tail 100 my-app

# Execute command in running container
docker exec -it my-app bash

# Inspect container
docker inspect my-app

# View container resource usage
docker stats my-app

# Copy files from container
docker cp my-app:/var/www/html/index.php ./index.php

# Copy files to container
docker cp ./config.php my-app:/var/www/html/
```

### **Network Management**

```bash
# List networks
docker network ls

# Create network
docker network create cnas-network

# Inspect network
docker network inspect cnas-network

# Connect container to network
docker network connect cnas-network my-app

# Disconnect container from network
docker network disconnect cnas-network my-app

# Remove network
docker network rm cnas-network
```

### **Volume Management**

```bash
# List volumes
docker volume ls

# Create volume
docker volume create mysql-data

# Inspect volume
docker volume inspect mysql-data

# Remove volume
docker volume rm mysql-data

# Remove unused volumes
docker volume prune

# Run container with volume
docker run -d -v mysql-data:/var/lib/mysql mysql:8.0
```

### **Docker Compose Commands**

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# List services
docker-compose ps

# Stop services
docker-compose stop

# Start services
docker-compose start

# Restart services
docker-compose restart

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes
docker-compose down -v

# Build/rebuild services
docker-compose build

# Build without cache
docker-compose build --no-cache

# Scale service
docker-compose up -d --scale php-app=3

# Execute command in service
docker-compose exec php-app bash

# View service logs
docker-compose logs -f php-app
```

### **Cleanup Commands**

```bash
# Remove unused containers, networks, images
docker system prune

# Remove everything (including volumes)
docker system prune -a --volumes

# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# View disk usage
docker system df
```

---

## 🔍 Troubleshooting Commands

### **Debugging Container Issues**

```bash
# Check if container is running
docker ps -f name=my-app

# View recent logs
docker logs --tail 50 my-app

# Check container health status
docker inspect --format='{{.State.Health.Status}}' my-app

# Check container exit code
docker inspect --format='{{.State.ExitCode}}' my-app

# View container processes
docker top my-app

# Interactive shell in container
docker exec -it my-app sh

# Check container IP address
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-app

# Test connectivity to another container
docker exec my-app ping mysql -c 4

# Check port mappings
docker port my-app
```

### **Performance Analysis**

```bash
# Real-time resource stats
docker stats

# Resource usage for specific container
docker stats my-app --no-stream

# Container events
docker events --filter container=my-app

# Image layer analysis
docker history cnas-php-app:v1 --no-trunc
```

### **Security Scanning**

```bash
# Scan with Docker Scout
docker scout cves cnas-php-app:v1

# Quick view of vulnerabilities
docker scout quickview cnas-php-app:v1

# Compare images
docker scout compare cnas-php-app:v1 cnas-php-app:v2
```

---

## 🌐 Container Networking

### **Understanding Docker Networks**

```
Bridge Network (default):
┌─────────────────────────────────────┐
│        Host Machine                 │
│  ┌─────────────────────────────┐   │
│  │   Docker Bridge Network     │   │
│  │   (172.17.0.0/16)          │   │
│  │  ┌──────┐      ┌──────┐   │   │
│  │  │ App  │ ───→ │MySQL │   │   │
│  │  │172.17│      │172.17│   │   │
│  │  │.0.2  │      │.0.3  │   │   │
│  │  └──────┘      └──────┘   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### **Network Testing**

```bash
# Ping another container
docker exec php-app ping mysql -c 3

# Check DNS resolution
docker exec php-app nslookup mysql

# Test port connectivity
docker exec php-app nc -zv mysql 3306

# Curl from one container to another
docker exec php-app curl http://mysql:3306
```

---

## 📊 Container Health Checks

### **Dockerfile Health Check**

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
```

**Parameters:**
- `--interval=30s` - Check every 30 seconds
- `--timeout=3s` - Timeout after 3 seconds
- `--start-period=40s` - Grace period for app startup
- `--retries=3` - Mark unhealthy after 3 failures

### **Check Health Status**

```bash
# View health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health info
docker inspect --format='{{json .State.Health}}' my-app | jq

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' my-app
```

---

## 🔐 Environment Variables

### **Methods to Pass Environment Variables**

**1. Command Line:**
```bash
docker run -e DB_HOST=mysql -e DB_USER=root my-app
```

**2. Environment File:**
```bash
docker run --env-file .env my-app
```

**3. Docker Compose:**
```yaml
services:
  php-app:
    environment:
      - DB_HOST=mysql
      - DB_USER=appuser
```

**4. From Shell:**
```bash
docker run -e DB_HOST=$DB_HOST my-app
```

### **View Container Environment**

```bash
# View all environment variables
docker exec my-app env

# View specific variable
docker exec my-app printenv DB_HOST
```

---

## 📦 Multi-Platform Builds

### **Build for Multiple Architectures**

```bash
# Create buildx builder
docker buildx create --name mybuilder --use

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 \
  -t yourdockerhub/cnas-php-app:v1 \
  --push .

# Inspect builder
docker buildx inspect mybuilder
```

---

## 🎯 Best Practices Checklist

### **Image Building**
- [ ] Use specific base image tags (not `latest`)
- [ ] Minimize layers (combine RUN commands)
- [ ] Use `.dockerignore` file
- [ ] Run as non-root user
- [ ] Include health checks
- [ ] Clean up in same layer (apt cache, temp files)
- [ ] Use multi-stage builds when applicable

### **Container Running**
- [ ] Use named volumes for data persistence
- [ ] Set resource limits (--memory, --cpus)
- [ ] Use restart policies (--restart unless-stopped)
- [ ] Use custom networks (not default bridge)
- [ ] Set environment variables via files or secrets
- [ ] Enable health checks
- [ ] Use meaningful container names

### **Security**
- [ ] Don't run as root
- [ ] Scan images for vulnerabilities
- [ ] Use minimal base images
- [ ] Keep base images updated
- [ ] Don't expose unnecessary ports
- [ ] Use secrets for sensitive data
- [ ] Enable Docker Content Trust
- [ ] Limit container capabilities

---

## 🆘 Common Issues & Solutions

### **Issue: Container exits immediately**
```bash
# Check logs
docker logs container-name

# Check exit code
docker inspect --format='{{.State.ExitCode}}' container-name

# Run in foreground to see errors
docker run --rm -it cnas-php-app:v1
```

### **Issue: Cannot connect to MySQL**
```bash
# Check if MySQL is running
docker ps -f name=mysql

# Check network connectivity
docker exec php-app ping mysql

# Verify environment variables
docker exec php-app env | grep DB_

# Check MySQL logs
docker logs mysql
```

### **Issue: Port already in use**
```bash
# Find process using port
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Use different port
docker run -p 8081:80 my-app
```

### **Issue: Out of disk space**
```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a --volumes

# Remove specific objects
docker volume prune
docker image prune -a
```

---

## 📚 Additional Resources

- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Security](https://docs.docker.com/engine/security/)
