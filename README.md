# CNAS Assignment - Cloud Native Application

A containerized PHP web application with MySQL database, deployed on Kubernetes with CI/CD automation.

## 📋 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Docker Implementation](#docker-implementation)
- [Local Development](#local-development)
- [Kubernetes Deployment](#kubernetes-deployment)
- [CI/CD Pipeline & DevSecOps](#cicd-pipeline--devsecops)
- [Security & Compliance](#security--compliance)
- [Team Roles & Ownership](#team-roles--ownership)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Ingress Controller                  │  │
│  │         (nginx - External Access)                │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │          PHP Application Service                 │  │
│  │      (LoadBalancer - Port 80)                    │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │      PHP App Deployment (3 Replicas)            │  │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐     │  │
│  │   │  Pod 1   │  │  Pod 2   │  │  Pod 3   │     │  │
│  │   │ php:8.2  │  │ php:8.2  │  │ php:8.2  │     │  │
│  │   └──────────┘  └──────────┘  └──────────┘     │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │          MySQL Service (Internal)                │  │
│  │             (ClusterIP - Port 3306)              │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │      MySQL StatefulSet (1 Replica)              │  │
│  │   ┌──────────────────────────────────┐          │  │
│  │   │  MySQL Pod                       │          │  │
│  │   │  mysql:8.0                       │          │  │
│  │   │  Persistent Volume (10Gi)        │          │  │
│  │   └──────────────────────────────────┘          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Supporting & Security Components:                      │
│  • HPA (Horizontal Pod Autoscaler)                    │
│  • PDB (Pod Disruption Budget)                        │
│  • ConfigMaps & Secrets                               │
│  • Kyverno Policy Engine                              │
│  • NetworkPolicies (Pod-to-Pod isolation)               │
│  • Role-Based Access Control (RBAC)                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Prerequisites

### Required Tools
- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- **Kind** (Kubernetes in Docker) or Minikube
- **kubectl** (v1.25+)
- **Git**

### Optional Tools
- Jenkins (for CI/CD pipeline)
- Trivy (for vulnerability scanning)
- Kyverno (for policy enforcement)
- Helm (for package management)

### Installation Commands

**Windows (PowerShell):**
```powershell
# Install Docker Desktop
winget install Docker.DockerDesktop

# Install kubectl
winget install Kubernetes.kubectl

# Install Kind
choco install kind

# Verify installations
docker --version
kubectl version --client
kind version
```

**Linux/macOS:**
```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

---

## 🐳 Docker Implementation

### **Dockerfile Explanation**

Our Dockerfile implements multi-layer security and optimization:

```dockerfile
# Base image with PHP 8.2 and Apache
FROM php:8.2-apache AS base

# Install required PHP extensions for MySQL connectivity
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Copy application code
WORKDIR /var/www/html/
COPY php-app/ /var/www/html/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Security: Run as non-root user
USER www-data

# Health check for monitoring
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
CMD ["apache2-foreground"]
```

### **Key Docker Features:**
1. ✅ **Non-root user** - Runs as `www-data` for security
2. ✅ **Health checks** - Automatic container monitoring
3. ✅ **Optimized layers** - Minimal image size
4. ✅ **Clean builds** - Uses `.dockerignore` to exclude unnecessary files
5. ✅ **Specific versions** - No `latest` tags for reproducibility

### **Building the Docker Image**

```bash
# Build the image
docker build -t cnas-php-app:v1 .

# Tag for registry
docker tag cnas-php-app:v1 yourdockerhub/cnas-php-app:v1

# Push to Docker Hub
docker login
docker push yourdockerhub/cnas-php-app:v1

# Scan for vulnerabilities (recommended)
docker scout cves cnas-php-app:v1
```

---

## 💻 Local Development

### **Using Docker Compose**

Docker Compose simplifies local testing with all dependencies:

```bash
# Start all services (MySQL + PHP + phpMyAdmin)
docker-compose up -d

# View logs
docker-compose logs -f php-app

# Check service status
docker-compose ps

# Access the application
# PHP App: http://localhost:8080
# phpMyAdmin: http://localhost:8081

# Stop services
docker-compose down

# Clean up volumes (caution: deletes data)
docker-compose down -v
```

### **Container Networking**

Services communicate via Docker's internal DNS:
- PHP app connects to MySQL using hostname `mysql` (service name)
- Network: `cnas-network` (bridge driver)
- Isolation: Containers can only communicate within the same network

### **Database Initialization**

The MySQL container automatically runs `db/users.sql` on first startup:
```sql
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);
```

---

## ☸️ Kubernetes Deployment

### **1. Create Kind Cluster**

```bash
# Create cluster with custom configuration
kind create cluster --config kind-cluster.yaml --name cnas-cluster

# Verify cluster
kubectl cluster-info --context kind-cnas-cluster
kubectl get nodes
```

### **2. Deploy Application**

```bash
# Apply all Kubernetes manifests in order
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-configmap.yaml
kubectl apply -f k8s/02-secret.yaml
kubectl apply -f k8s/03-mysql-pvc.yaml
kubectl apply -f k8s/04-mysql-statefulset.yaml
kubectl apply -f k8s/05-mysql-service.yaml
kubectl apply -f k8s/11-mysql-init-configmap.yaml
kubectl apply -f k8s/06-php-deployment.yaml
kubectl apply -f k8s/07-php-service.yaml
kubectl apply -f k8s/08-ingress.yaml
kubectl apply -f k8s/09-hpa.yaml
kubectl apply -f k8s/12-pdb.yaml

# Verify deployment
kubectl get all -n cnas
kubectl get pvc -n cnas
```

### **3. Install Kyverno (Policy Engine)**

```bash
# Install Kyverno
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.10.0/install.yaml

# Apply security policies
kubectl apply -f k8s/kyverno/01-require-resource-limits.yaml
kubectl apply -f k8s/kyverno/02-disallow-privileged-containers.yaml
kubectl apply -f k8s/kyverno/03-disallow-latest-tag.yaml

# Verify policies
kubectl get clusterpolicy
```

### **4. Access the Application**

```bash
# Port forward to access locally
kubectl port-forward -n cnas service/php-service 8080:80

# Access at: http://localhost:8080

# Check logs
kubectl logs -n cnas deployment/php-app -f

# Check MySQL
kubectl exec -it -n cnas mysql-0 -- mysql -u appuser -p mydb
```

---

## 🔄 CI/CD Pipeline & DevSecOps

The project uses an automated Jenkins Pipeline (`Jenkinsfile`) designed to enforce security controls, vulnerability checks, dynamic tag deployment, and automated rollbacks.

---

### **DevSecOps Workflow Diagram**

┌──────────────────┐    ┌─────────────────────────┐    ┌──────────────────────┐
│   Git Checkout   │───>│  Static Security Scan   │───>│  Build Docker Image  │
│  (Source Code)   │    │  (Trivy Repository FS)  │    │  (Dynamic Tagging)   │
└──────────────────┘    └─────────────────────────┘    └──────────────────────┘
                                                                  │
┌──────────────────┐    ┌─────────────────────────┐               │
│ Deploy to K8s    │<───│ Container Vulnerability │<──────────────┘
│ & Kyverno Check  │    │ Scan (Trivy Image)      │
└────────┬─────────┘    └─────────────────────────┘
         │
         ▼
┌──────────────────┐    ┌─────────────────────────┐
│ Post-Build       │───>│   Post-Build Cleanup    │
│ Deployment Check │    │   (cleanWs Isolation)   │
└──────────────────┘    └─────────────────────────┘

### Pipeline Stages:
1. **Checkout** - Clone Git repository
2. **Scan Repository** - Static file vulnerability scanning with Trivy
3. **Build Docker Image** - Build containerized application with dynamic build tag
4. **Scan Container Image** - Container layer security scanning with Trivy
5. **Push to Registry** - Upload tagged image to Docker Hub
6. **Deploy to Kubernetes** - Apply Kyverno policies and update manifests
7. **Verify Deployment & Post Cleanup** - Verify status and execute cleanWs() workspace isolation

---

### **Complete `Jenkinsfile` Implementation**

```groovy
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_IMAGE_NAME = 'sinoceratops/cnas-php-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBERNETES_CREDENTIALS_ID = 'kubeconfig-cluster-secret'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Ensure latest repo state is pulled cleanly
                checkout scm
            }
        }

        stage('Static Security Scan') {
            steps {
                echo "=== Scanning Source Code & Manifests for Misconfigurations ==="
                // Scans workspace for exposed secrets or vulnerable IaC configurations
                sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL .'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    appImage = docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Scan Image') {
            steps {
                echo "=== Scanning Container Image with Trivy ==="
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL --no-progress ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_REGISTRY_CREDENTIALS_ID) {
                        echo "=== Pushing Container Image to Registry ==="
                        appImage.push()
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    // Reset local git changes so 'latest' string always exists
                    echo "=== Resetting Local Git Changes ==="
                    sh "git checkout -- k8s/06-php-deployment.yaml || true"

                    // Apply Kyverno policies first and wait for the webhook to be ready
                    echo "=== Applying Kyverno Admission Policies ==="
                    sh "kubectl apply -f k8s/kyverno/"
                    sh "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=90s || true"

                    echo "=== Deploying Workloads to 'cnas' Namespace ==="
                    // Inject the exact build tag into the manifest before applying
                    sh "sed -i 's|sinoceratops/cnas-php-app:latest|${DOCKER_IMAGE_NAME}:${IMAGE_TAG}|g' k8s/06-php-deployment.yaml"
                    // Apply all remaining k8s manifests (NetworkPolicies, RBAC, Services, Secrets)
                    sh "kubectl apply -f k8s/ -n cnas"
                    sh "kubectl rollout status deployment/php-app -n cnas"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    sh "kubectl get pods,svc,deployment -n cnas"
                }
            }
        }
    }

    post {
        always {
            // Clean workspace post-build to prevent lingering artifacts or secret leaks
            cleanWs()
        }
        failure {
            echo "Pipeline failed — check the logs above for details. Triggering automated rollback..."
            withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                sh "kubectl rollout undo deployment/php-app -n cnas || true"
                echo "Rollback triggered for php-app deployment."
            }
        }
        success {
            echo "Pipeline completed successfully. Image deployed: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
```

---

## 🔒 Security & Compliance

See [DOCKER-SECURITY.md](./DOCKER-SECURITY.md) for comprehensive security documentation.

### Key Security Features:
- ✅ Non-root container execution
- ✅ Secret management via Kubernetes Secrets
- ✅ Resource limits to prevent resource exhaustion
- ✅ Vulnerability scanning via Trivy (FS & Container scanning)
- ✅ Network policies for traffic control
- ✅ Kubernetes RBAC for deployment isolation
- ✅ Kyverno policies for compliance enforcement
- ✅ Health checks for automatic recovery
- ✅ Minimal base images to reduce attack surface

### Security Checklist:
```bash
# Scan image for vulnerabilities
docker scout cves cnas-php-app:v1

# Check Kubernetes security
kubectl auth can-i --list --namespace=cnas

# Verify RBAC
kubectl get rolebindings -n cnas

# Check pod security
kubectl get pods -n cnas -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'
```

---

## 👥 Team Roles & Ownership

**Class:** T01 | **Team:** 02

| Person | Role | Core Ownership |
| :--- | :--- | :--- |
| **Ee Ting Li** | Application + Docker Engineer | PHP app, MySQL, Dockerfile, Docker Compose, Docker Hub |
| **Lau Jia Qi** | Kubernetes Platform Engineer | Multi-node cluster, Deployments, Services, Ingress, HPA, Probes, PV/PVC |
| **Chee Hsiao En Samuela** | DevSecOps + Security Engineer | GitHub Actions/Jenkins, Trivy, RBAC, NetworkPolicy, Secrets, Secure Pipeline |
| **Janice Oh Shi Ting** | Monitoring + Testing + Report | Prometheus, Grafana, Loki/Promtail, Testing evidence, Demo script, Report coordination |

---

## 🧪 Testing

### Local Testing with Docker Compose:
```bash
# Start services
docker-compose up -d

# Run integration tests
curl http://localhost:8080
curl http://localhost:8080/create.php

# Check database connectivity
docker-compose exec mysql mysql -u appuser -papppass -e "SELECT * FROM mydb.users;"
```

### Kubernetes Testing:
```bash
# Check pod readiness
kubectl get pods -n cnas

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n cnas -- curl http://php-service

# Test database connection
kubectl exec -it -n cnas mysql-0 -- mysql -u appuser -papppass -e "SHOW DATABASES;"
```

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kyverno Policies](https://kyverno.io/policies/)
- [PHP Docker Official Images](https://hub.docker.com/_/php)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -m "Add new feature"`
4. Push to branch: `git push origin feature/new-feature`
5. Submit pull request

---

## 📝 License

This project is for educational purposes as part of CNAS coursework.
