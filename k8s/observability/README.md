# Observability profile

Install this profile with `scripts/Install-Observability.ps1`; do not add this
directory to the core Kustomization. The ordered installer first creates the
Prometheus Operator CRDs, then upgrades the existing Kong release so its
chart-managed ServiceMonitor can be created, and finally applies the custom
monitors, probes, dashboards, exporters, and alert rules.

## What is monitored

| Area | Primary signal |
|---|---|
| End-to-end application | Blackbox HTTP probe of dependency-aware `readyz.php` |
| Load balancer/API gateway | Internal HTTPS route availability, Kong request rate, status codes, rate limits, p95 request/Kong/upstream latency, bandwidth, replica health, and logs |
| Gateway controller | KIC configuration-push and translation success/failure metrics |
| Load distribution | Per-PHP-Pod Apache access-log request rate in Loki |
| MySQL | Availability, connections, QPS, slow queries, aborted connections, deadlocks, PVC usage, backup Job failures, and backup age |
| Redis sessions | Availability, memory/maxmemory, clients, command rate, keys, keyspace hits, evictions, rejected connections, and logs |
| Application capacity | Ready replicas, HPA state, CPU as a percentage of request, memory as a percentage of limit, and restarts |
| Kind cluster | Node readiness, node CPU/memory, pressure conditions, Pending Pods, kube-state metrics, kubelet, cAdvisor, and node-exporter |
| Audit trail | CNAS, Kong, and monitoring logs plus Kubernetes Events in Loki |

The profile supplies:

- Prometheus, Alertmanager, Grafana, kube-state-metrics, kubelet/cAdvisor
  scraping, and node-exporter;
- Kong Gateway and Kong Ingress Controller ServiceMonitors;
- blackbox probes for the internal application Service and the HTTPS Gateway
  route;
- restricted MySQL and Redis exporter Deployments with scoped
  NetworkPolicies;
- Loki with a non-root Alloy Kubernetes API log collector;
- three provisioned dashboards:
  - **CNAS Platform Overview**
  - **CNAS Gateway and Load Balancing**
  - **CNAS MySQL and Redis Data Services**
- alert rules for availability, HTTP errors/latency, KIC failures, data-service
  health, storage/backups, HPA/workload health, and node pressure.

## Deliberate local limitations

- Prometheus, Alertmanager, Loki, and Grafana use short-lived, ephemeral
  storage to fit a coursework laptop.
- Alertmanager keeps alerts in its UI unless a secret-backed external receiver
  is configured and tested.
- The Kind TLS probe accepts the repository's self-signed certificate, while a
  separate alert still tracks its expiry.
- The continuous Gateway probe starts inside the cluster. The validation and
  load scripts separately exercise the host-facing Kind port mapping; a host
  firewall or port-mapping failure is not covered by the continuous probe.
- The Redis exporter reuses the application Redis password because the
  coursework Redis configuration has one password-protected user. A production
  deployment should use a dedicated ACL user.
- Redis session data is ephemeral and is lost when its Pod is replaced.
- MySQL, Redis, Prometheus, Loki, and Alertmanager remain single replicas.
- Kind nodes are containers on one host, so node dashboards do not demonstrate
  physical-host high availability.

See `docs/DEMO-RUNBOOK.md` for deployment, validation, load generation, alert
drills, evidence collection, and claims that are safe to make in the report.
