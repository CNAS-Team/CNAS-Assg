# Manual Testing Guide

This guide covers testing both the Docker Compose (local dev) setup and the full Kubernetes deployment on a KinD cluster.

---

## Prerequisites

Make sure these tools are installed before starting:

```powershell
docker --version        # Docker Desktop 20.10+
docker compose version  # v2.0+
kind version            # 0.20+
kubectl version --client
```

---

## Part 1 — Docker Compose (Local Dev)

### 1.1 Set up environment variables

Copy the example env file and fill in your values:

```powershell
cd "c:\Cloud Native Architecture\CNAS-Assg"
copy .env.example .env
```

The defaults in `.env` will work out of the box for local testing:
```
DB_USER=cnasuser
DB_PASSWORD=cnaspass
DB_NAME=mydb
MYSQL_ROOT_PASSWORD=rootpass
```

---

### 1.2 Start containers

```powershell
docker compose up -d
```

Expected output — three lines like:
```
✔ Container cnas-mysql    Healthy
✔ Container cnas-php-app  Started
```

---

### 1.3 Verify containers are healthy

```powershell
docker compose ps
```

Both services should show `running (healthy)`. MySQL's healthcheck runs `mysqladmin ping`, so `healthy` confirms MySQL is actually accepting connections, not just started.

If MySQL shows `starting` wait 30 seconds and recheck. If it shows `unhealthy`:
```powershell
docker compose logs mysql
```

---

### 1.4 Open the app

Go to **http://localhost:8080** in your browser.

You should see:
- Page title: "Team Members in Class -T01 Team – 02"
- "Add New Team Member" link
- An empty table with columns: ID, Student Name, Email, Actions

---

### 1.5 Test CREATE

1. Click **Add New Team Member**
2. Enter:
   - Name: `Alice Tan`
   - Email: `alice@example.com`
3. Click **Create**

Expected: redirected back to the table with Alice listed, ID = 1.

---

### 1.6 Test READ

The table on `index.php` should now show Alice's record. Add two more users:
- `Bob Lim` / `bob@example.com`
- `Charlie Ng` / `charlie@example.com`

All three should appear in the table with sequential IDs.

---

### 1.7 Test UPDATE

1. Click **Edit** next to Alice
2. Change name to `Alice Tan (edited)`
3. Click **Update**

Expected: redirected back, name updated, ID unchanged.

---

### 1.8 Test DELETE

1. Click **Delete** next to Bob
2. A confirmation dialog appears — click OK

Expected: Bob is removed from the table. Alice and Charlie remain.

---

### 1.9 Test data persistence

Stop and restart the containers:

```powershell
docker compose down
docker compose up -d
```

Wait for healthy status then refresh **http://localhost:8080**.

Expected: Alice and Charlie are still there. Data survived the restart because MySQL uses a named volume (`db-data`).

---

### 1.10 Verify database structure directly

```powershell
docker compose exec mysql mysql -u cnasuser -pcnaspass mydb -e "DESCRIBE users;"
```

Expected output:
```
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int          | NO   | PRI | NULL    | auto_increment |
| name  | varchar(100) | NO   |     | NULL    |                |
| email | varchar(100) | NO   |     | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
```

Both `name` and `email` must show `NO` in the Null column.

---

### 1.11 Test container networking

```powershell
docker compose exec web ping -c 3 mysql
```

Expected: 3 packets transmitted, 0% packet loss.

---

### 1.12 Check resource usage

```powershell
docker stats --no-stream
```

Rough expected ranges at idle:
- MySQL: ~200–400 MB memory
- PHP/Apache: ~50–100 MB memory
- Neither should be near 100% CPU

---

### 1.13 Stop Docker Compose

```powershell
# Stop but keep data volume
docker compose down

# Stop AND wipe all data (clean slate for next test)
docker compose down -v
```

---

## Part 2 — Kubernetes on KinD

### 2.1 Create the KinD cluster

```powershell
kind create cluster --config kind-cluster.yaml --name cnas-cluster
```

Verify the cluster is up:
```powershell
kubectl cluster-info --context kind-cnas-cluster
kubectl get nodes
```

Expected: 1 control-plane + 3 worker nodes all in `Ready` state.

---

### 2.2 Install Kyverno

Kyverno must be running before you apply your app manifests, otherwise its admission webhook is not available and pod creation will fail.

```powershell
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.0/install.yaml
```

Wait for Kyverno pods to be ready:
```powershell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s
```

---

### 2.3 Install nginx Ingress controller

Required for the Ingress resource to route traffic.

```powershell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait for it to be ready:
```powershell
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
```

---

### 2.4 Install metrics-server

Required for the HPA to read CPU metrics.

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Patch it for KinD (disables TLS cert verification, needed in local clusters):
```powershell
kubectl patch deployment metrics-server -n kube-system --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

---

### 2.5 Build and load the PHP image into KinD

KinD clusters can't pull from Docker Hub by default during development. Build locally and load directly:

```powershell
docker build -t jqii/cnas-php-app:latest .
kind load docker-image jqii/cnas-php-app:latest --name cnas-cluster
```

---

### 2.6 Apply Kyverno policies

```powershell
kubectl apply -f k8s/kyverno/
kubectl get clusterpolicy
```

Expected — 4 policies all showing `READY = True`:
```
NAME                          ADMISSION   BACKGROUND   READY   AGE
disallow-latest-tag           true        true         True    ...
disallow-privileged-containers true       true         True    ...
require-resource-limits       true        true         True    ...
require-run-as-non-root       true        true         True    ...
```

---

### 2.7 Deploy the application

Apply manifests in order:

```powershell
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/14-serviceaccounts.yaml
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
kubectl apply -f k8s/13-network-policy.yaml
```

---

### 2.8 Wait for all pods to be ready

```powershell
kubectl get pods -n cnas -w
```

Press Ctrl+C once all pods show `Running`. Expected:
```
NAME                       READY   STATUS    RESTARTS
mysql-0                    1/1     Running   0
php-app-xxxxxxxxx-xxxxx    1/1     Running   0
php-app-xxxxxxxxx-xxxxx    1/1     Running   0
php-app-xxxxxxxxx-xxxxx    1/1     Running   0
```

MySQL takes 30–60 seconds because of the init containers on the PHP deployment.

If a pod stays in `Pending` or `CrashLoopBackOff`:
```powershell
kubectl describe pod <pod-name> -n cnas
kubectl logs <pod-name> -n cnas --previous
```

---

### 2.9 Verify all resources deployed correctly

```powershell
kubectl get all -n cnas
kubectl get pvc -n cnas
kubectl get ingress -n cnas
kubectl get networkpolicy -n cnas
kubectl get hpa -n cnas
```

Check the PVC is bound:
```powershell
kubectl get pvc -n cnas
```
`mysql-pvc` should show `STATUS = Bound`.

---

### 2.10 Add hosts entry for the Ingress

The Ingress uses host `cnas.local`. Add it to your hosts file so the browser resolves it:

Open PowerShell **as Administrator**:
```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 cnas.local"
```

---

### 2.11 Open the app

Go to **http://cnas.local** in your browser.

You should see the same Team Members page as in Docker Compose. Run through the same CRUD tests from steps 1.5–1.8.

If the page doesn't load, port-forward directly to bypass the Ingress:
```powershell
kubectl port-forward -n cnas service/php-service 8080:80
```
Then test at **http://localhost:8080**.

---

### 2.12 Verify init containers ran successfully

```powershell
kubectl logs -n cnas <php-app-pod-name> -c wait-for-mysql
kubectl logs -n cnas <php-app-pod-name> -c init-db-schema
```

Expected in `wait-for-mysql`:
```
Checking MySQL availability...
MySQL is ready! Proceeding to start PHP app.
```

Expected in `init-db-schema`:
```
Initializing database schema...
Database schema initialized successfully.
```

---

### 2.13 Verify database schema inside the cluster

```powershell
kubectl exec -it -n cnas mysql-0 -- mysql -u cnasuser -pcnaspass mydb -e "DESCRIBE users;"
```

Same expected output as step 1.10 — both `name` and `email` must show `NOT NULL`.

---

### 2.14 Test the HPA

Generate some load to trigger autoscaling. Open a second terminal and run:

```powershell
kubectl run load-gen --image=busybox:1.36 --restart=Never -n cnas -- sh -c "while true; do wget -q -O- http://php-service/; done"
```

In the first terminal, watch the HPA:
```powershell
kubectl get hpa -n cnas -w
```

After 1–2 minutes you should see `REPLICAS` climb above 3 (up to the max of 6). Stop the load generator:
```powershell
kubectl delete pod load-gen -n cnas
```

Replicas will scale back down to 3 after the cooldown period (~5 minutes).

---

### 2.15 Test Pod Disruption Budget

The PDB requires at least 2 PHP pods available at all times. Test it by draining a worker node:

```powershell
# Get node names
kubectl get nodes

# Drain one worker (replace <node> with the actual name)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

Expected: 2 of 3 PHP pods are evicted and rescheduled on other nodes. The third stays running until replacements are ready, honouring `minAvailable: 2`.

Uncordon the node when done:
```powershell
kubectl uncordon <node>
```

---

### 2.16 Test Kyverno policy enforcement

Try to apply a pod that violates a policy — it should be blocked.

**Test 1: No resource limits**
```powershell
kubectl run policy-test --image=nginx:1.25 -n cnas --restart=Never
```
Expected error:
```
Error from server: admission webhook "validate.kyverno.svc" denied the request:
All containers in namespace 'cnas' must define CPU and memory limits.
```

**Test 2: Latest image tag**
```powershell
kubectl run tag-test --image=nginx:latest -n cnas --restart=Never
```
Expected error mentioning `disallow-latest-tag` policy.

**Test 3: Root container**
```powershell
kubectl run root-test -n cnas --restart=Never --image=nginx:1.25 \
  --overrides='{"spec":{"containers":[{"name":"root-test","image":"nginx:1.25","securityContext":{"runAsUser":0},"resources":{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}}]}}'
```
Expected error mentioning `require-run-as-non-root` policy.

---

### 2.17 Test Network Policy

Verify MySQL is not reachable from an arbitrary pod (non php-app):

```powershell
kubectl run netpol-test --image=busybox:1.36 -n cnas --restart=Never -- sh -c "nc -zv mysql-service 3306; echo exit:$?"
kubectl logs netpol-test -n cnas
kubectl delete pod netpol-test -n cnas
```

Expected: connection times out or is refused — the NetworkPolicy blocks it because the pod does not have the `app: php-app` label.

---

### 2.18 Test rolling update

Simulate a new deployment (e.g. after a Jenkins build):

```powershell
kubectl set image deployment/php-app php-app=jqii/cnas-php-app:latest -n cnas
kubectl rollout status deployment/php-app -n cnas
```

While the rollout is happening, run:
```powershell
kubectl get pods -n cnas -w
```

You should see new pods start (`ContainerCreating`) before old ones terminate, because `maxUnavailable: 1` and `maxSurge: 1` are set. The app stays available throughout.

To roll back:
```powershell
kubectl rollout undo deployment/php-app -n cnas
kubectl rollout status deployment/php-app -n cnas
```

---

### 2.19 Check securityContext is applied

Confirm containers are not running as root:

```powershell
kubectl get pods -n cnas -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.securityContext}{"\n"}{end}{end}'
```

Each container should show `runAsNonRoot:true` and `allowPrivilegeEscalation:false`.

---

### 2.20 View application logs

```powershell
# All PHP pods
kubectl logs -n cnas deployment/php-app

# Follow live logs from a specific pod
kubectl logs -n cnas <pod-name> -f

# MySQL logs
kubectl logs -n cnas mysql-0
```

Look for Apache access log entries when you make requests. No `FATAL` or `ERROR` lines should appear under normal use.

---

### 2.21 Clean up

```powershell
# Delete all app resources
kubectl delete namespace cnas

# Delete the KinD cluster entirely
kind delete cluster --name cnas-cluster
```

---

## Testing Checklist

### Docker Compose
- [ ] Containers start and reach `healthy` status
- [ ] App loads at http://localhost:8080
- [ ] CREATE — can add a new user
- [ ] READ — user appears in the table
- [ ] UPDATE — can edit a user's name/email
- [ ] DELETE — user is removed, confirmation dialog shown
- [ ] Data survives `docker compose down` + `docker compose up -d`
- [ ] DB schema has `NOT NULL` on `name` and `email`
- [ ] Container networking works (`ping mysql`)

### Kubernetes
- [ ] KinD cluster created with 1 control-plane + 3 workers
- [ ] Kyverno, nginx-ingress, and metrics-server installed
- [ ] All 4 Kyverno ClusterPolicies show `READY = True`
- [ ] All pods reach `Running` state
- [ ] PVC `mysql-pvc` is `Bound`
- [ ] App loads at http://cnas.local (or via port-forward)
- [ ] CRUD operations work end-to-end
- [ ] Init container logs show successful DB schema init
- [ ] HPA scales up under load, scales back down after
- [ ] PDB keeps at least 2 pods running during node drain
- [ ] Kyverno blocks pods with no resource limits
- [ ] Kyverno blocks `latest` image tags
- [ ] Kyverno blocks root containers
- [ ] NetworkPolicy blocks MySQL access from unlabelled pods
- [ ] Rolling update completes with zero downtime
- [ ] Rollback (`kubectl rollout undo`) restores previous version
- [ ] No root processes (`runAsNonRoot: true` confirmed)

---

## Quick Reference

```powershell
# Docker Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down -v

# Kubernetes — check everything
kubectl get all -n cnas
kubectl get pvc,ingress,networkpolicy,hpa,pdb -n cnas
kubectl describe pod <name> -n cnas
kubectl logs <name> -n cnas

# Kyverno
kubectl get clusterpolicy
kubectl describe clusterpolicy require-resource-limits

# KinD
kind get clusters
kind delete cluster --name cnas-cluster
```
