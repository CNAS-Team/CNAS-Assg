# Docker Security Considerations

## 🔒 Security Implementations in This Project

### 1. **Base Image Security**
- ✅ Using official PHP image from Docker Hub: `php:8.2-apache`
- ✅ Specific version tag (not `latest`) to ensure reproducibility
- 🔄 **Recommendation**: Regularly update base image to get security patches

### 2. **Non-Root User Execution**
```dockerfile
USER www-data
```
- ✅ Container runs as `www-data` user (not root)
- ✅ Reduces privilege escalation risks
- ✅ Follows principle of least privilege

### 3. **Minimal Layer Approach**
- ✅ Combined RUN commands to reduce layers
- ✅ Cleaned up apt cache to reduce image size
- ✅ Used `.dockerignore` to exclude unnecessary files

### 4. **Secrets Management**
- ✅ **Never hardcode credentials in Dockerfile**
- ✅ Use environment variables for configuration
- ✅ In Kubernetes: Use Secrets for sensitive data
- ✅ In Docker Compose: Use environment files (`.env`)

**Example `.env` file (DO NOT commit to Git):**
```env
DB_USER=appuser
DB_PASSWORD=strong_password_here
MYSQL_ROOT_PASSWORD=another_strong_password
```

### 5. **Container Health Monitoring**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
```
- ✅ Automatic health status monitoring
- ✅ Container orchestration can restart unhealthy containers

### 6. **Network Security**
- ✅ Using custom Docker network (`cnas-network`)
- ✅ Services communicate via service names (DNS)
- ✅ MySQL not directly exposed in production (only accessible via service)

### 7. **Volume Security**
- ✅ Named volumes for data persistence
- ✅ Read-only mounts where applicable (`:ro` flag)
- ✅ Proper file permissions set in Dockerfile

### 8. **Image Scanning** (Recommended Addition)
Run vulnerability scans before deploying:
```bash
# Using Docker Scout
docker scout cves yourdockerhub/cnas-php-app:v1

# Using Trivy
trivy image yourdockerhub/cnas-php-app:v1

# Using Snyk
snyk container test yourdockerhub/cnas-php-app:v1
```

### 9. **Resource Limits** (Kubernetes)
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```
- ✅ Prevents resource exhaustion attacks
- ✅ Ensures fair resource allocation

### 10. **Security Policy Enforcement** (Kyverno)
Your project includes Kyverno policies:
- ✅ `require-resource-limits.yaml` - Enforces resource limits
- ✅ `disallow-privileged-containers.yaml` - Blocks privileged mode
- ✅ `disallow-latest-tag.yaml` - Requires specific image tags

---

## 🚨 Additional Security Recommendations

### **High Priority**
1. **Enable Content Trust** (Docker signing)
   ```bash
   export DOCKER_CONTENT_TRUST=1
   ```

2. **Use Multi-Stage Builds** (when applicable)
   - Separates build dependencies from runtime
   - Reduces final image size

3. **Regular Updates**
   ```bash
   # Rebuild images regularly to get security patches
   docker-compose build --no-cache
   ```

4. **Limit Container Capabilities**
   ```yaml
   securityContext:
     allowPrivilegeEscalation: false
     runAsNonRoot: true
     capabilities:
       drop:
         - ALL
   ```

### **Medium Priority**
5. **Implement Network Policies** (Kubernetes)
   - Restrict pod-to-pod communication
   - Allow only necessary traffic

6. **Use Private Registry**
   - Host images in private registry (Docker Hub private, AWS ECR, GCR)
   - Implement image pull secrets in Kubernetes

7. **Enable Audit Logging**
   - Track who deployed what and when
   - Monitor for suspicious activities

### **Best Practices**
8. **Never expose sensitive ports publicly**
   - MySQL should not be accessible from outside cluster
   - Use bastion hosts or kubectl port-forward for debugging

9. **Implement RBAC** (Kubernetes)
   - Limit who can deploy/modify resources
   - Use service accounts with minimal permissions

10. **Container Immutability**
    - Never `docker exec` to modify running containers
    - Deploy new versions instead

---

## 🔍 Security Checklist

Before deploying to production:

- [ ] Base images updated to latest security patches
- [ ] No hardcoded secrets in code or Dockerfiles
- [ ] Container runs as non-root user
- [ ] Resource limits defined
- [ ] Health checks implemented
- [ ] Image vulnerability scan passed
- [ ] Kyverno policies enforced
- [ ] Network policies defined
- [ ] Secrets encrypted at rest
- [ ] RBAC configured
- [ ] Audit logging enabled
- [ ] Backup strategy in place

---

## 📚 References
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-checklist/)
