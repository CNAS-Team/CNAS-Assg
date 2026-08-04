# Jenkins CI/CD and DevSecOps pipeline

The committed `Jenkinsfile` builds one immutable application image and promotes that exact image through security checks and Kubernetes deployment. It deliberately does not push a `latest` tag.

## 🏗️ Pipeline Stages

The automated pipeline executes the following stages sequentially:

1. **Checkout & Versioning:** Pulls the latest source code from the repository and tags the build with the current Git SHA for traceability.
2. **Deep Secret Scan (Gitleaks):** Scans the repository history to prevent the accidental exposure of API keys, passwords, or cryptographic keys.
3. **Validate Source:** Lints and validates the PHP source code using an ephemeral container spun up from the `Dockerfile.jenkins`[cite: 2].
4. **SAST Code Scanning (Semgrep):** Performs Static Application Security Testing on the PHP code to catch vulnerabilities (like SQL injection or XSS) early in the lifecycle.
5. **Repository Security Scan (Trivy):** Scans the file system for infrastructure-as-code misconfigurations and high/critical vulnerabilities.
6. **Build & Verify Image:** Compiles the container image using the primary `Dockerfile`[cite: 2] and runs a verification script to ensure required PHP extensions (MySQLi, Redis) are properly loaded.
7. **Image Security & SBOM:** Scans the compiled container image with Trivy and generates a CycloneDX Software Bill of Materials (SBOM) for compliance tracking.
8. **Push Immutable Image:** Pushes the verified, tagged container image to Docker Hub.
9. **Sign Container Image (Cosign):** Dynamically downloads the Cosign binary and cryptographically signs the container image using securely injected private keys. The signature can be verified using the `cosign.pub`[cite: 2] file located in the repository root.
10. **Deploy and Verify:** Creates necessary Kubernetes secrets dynamically, applies the Kubernetes manifests located in the `k8s/`[cite: 2] directory, and deploys the application to the `cnas` namespace followed by a post-deployment smoke test.

---

## Jenkins agent prerequisites

The Jenkins agent needs:

- Docker Engine and Docker CLI;
- `kubectl` with Kustomize support;
- Helm and OpenSSL;
- Trivy;
- Bash, Git, and network access to Docker Hub and the Kubernetes API;
- the Docker Pipeline, Credentials Binding, Kubernetes CLI, Workspace Cleanup, and Pipeline plugins.

The target cluster must be created from `kind-cluster.yaml`. The pipeline runs the idempotent `k8s/scripts/install-platform.sh` before applying application resources. For the local Kind demonstration it also generates a short-lived, self-signed `cnas.local` TLS Secret. A real deployment must replace this with a certificate issued by a trusted CA or cert-manager.

## Required Jenkins credentials

Create these entries in Jenkins. Do not place the values in source control or pipeline parameters.

| Credential ID | Jenkins type | Purpose |
|---|---|---|
| `docker-hub-credentials` | Username with password | Push the application image. |
| `kubeconfig-cluster-secret` | Kubeconfig credential | Authenticate to the target cluster. |
| `cnas-db-credentials` | Username with password | Create/update the application database Secret used by runtime CRUD and versioned migrations. |
| `cnas-mysql-root-password` | Secret text | Initialize and administer the MySQL instance. |
| `cnas-redis-password` | Secret text | Authenticate the shared PHP session store. |
| `cosign-private-key` | Secret file | The `cosign.key` private key used to sign the Docker image prior to deployment. |

Jenkins masks the credential bindings, and the shell disables command tracing while generating `cnas-secret`. The pipeline logs only the Secret object's name, never its values.

## Pipeline gates

1. Checkout and record the twelve-character Git commit.
2. PHP syntax checks and repository unit tests in a clean PHP CLI container.
3. Kubernetes manifest validation and Kustomize rendering.
4. Trivy source, IaC, dependency, and secret scanning; HIGH/CRITICAL findings fail the build.
5. Build `${BUILD_NUMBER}-${GIT_SHA}` once.
6. Trivy image gate and CycloneDX SBOM generation.
7. Push only the immutable build tag.
8. Install or verify platform controllers and admission controls.
9. Inject runtime Secrets from Jenkins credentials.
10. Render a temporary Kustomize overlay containing the exact image tag and deploy it.
11. Wait for rollout, run smoke tests, and verify the running image string.
12. Archive the SBOM, rendered manifests, and test artefacts.

The Deployment is annotated with the Git SHA and image name so the running workload can be traced back to a Jenkins build. A failure before deployment does not touch a healthy release. A deployment or verification failure attempts a Kubernetes rollout undo.

## 🌐 Local Webhook Configuration (ngrok)

Because the Jenkins deployment server runs locally, a secure tunnel must be established to allow GitHub to trigger the pipeline automatically upon code pushes.

### 1. Establish the Tunnel
Start an ngrok tunnel pointing to the local Jenkins port (default `8080`):
```bash
ngrok http 8080
```
### 2. Configure GitHub
Once the tunnel is active, register the generated public URL with GitHub:
1. Navigate to the GitHub repository Settings > Webhooks. 
2. Add or edit a webhook. 
3. Set the Payload URL to the ngrok forwarding address appended with the Jenkins webhook endpoint (e.g., https://<ngrok-id>.ngrok-free.app/github-webhook/). 
4. Set the Content type to application/json.
5. Save the webhook to enable automated trigger events. 

Note: If utilizing the free tier of ngrok, the URL will change each time the tunnel is restarted and must be manually updated in GitHub. 

## Traceability evidence

Use these commands during the demonstration:

```sh
kubectl get deployment php-app -n cnas \
  -o jsonpath='{.metadata.annotations.cnas\.assignment/git-sha}{"\n"}{.metadata.annotations.cnas\.assignment/image}{"\n"}'

kubectl rollout history deployment/php-app -n cnas

kubectl get pods -n cnas \
  -l app=php-app \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[?(@.name=="php-app")].image}{"\n"}{end}'
```

Capture the Jenkins build URL, Git commit, archived SBOM fingerprint, image tag, Deployment annotations, rollout revision, smoke-test result, and final Pod images in one evidence table.

## Deliberate limitations

- The pipeline produces an SBOM but does not yet sign images. Cosign signing and admission verification are a reasonable stretch goal.
- Jenkins controls application delivery; cluster creation and host-level Docker availability are external platform responsibilities.
- Automatic rollback can restore the previous application image, but it cannot reverse incompatible database migrations. Schema changes must use a separately tested, backward-compatible migration process.
- The coursework profile shares one database identity between runtime CRUD, migrations, and backups. Because it therefore has schema privileges, a production design should split these into separate least-privilege identities.
