[CmdletBinding()]
param(
    [switch]$SkipNetworkPolicy,
    [switch]$SkipPolicyTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TestDirectory = Join-Path $RepoRoot "tests\k8s"

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command $($Arguments -join ' ')"
    }
}

function Invoke-TestJob {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Manifest,
        [int]$TimeoutSeconds = 180
    )

    Write-Host "`nRunning $Name..." -ForegroundColor Cyan
    & kubectl -n cnas delete job $Name --ignore-not-found=true *> $null
    Invoke-Checked -Command "kubectl" -Arguments @("apply", "-f", $Manifest)

    & kubectl -n cnas wait "--for=condition=complete" "job/$Name" "--timeout=${TimeoutSeconds}s"
    $exitCode = $LASTEXITCODE
    & kubectl -n cnas logs "job/$Name" --all-containers=true
    if ($exitCode -ne 0) {
        & kubectl -n cnas describe "job/$Name"
        throw "$Name did not complete successfully."
    }
}

function Assert-PolicyRejection {
    param(
        [Parameter(Mandatory = $true)][string]$Manifest,
        [Parameter(Mandatory = $true)][string]$ExpectedPolicy,
        [switch]$AllowPodSecurity
    )

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $result = & kubectl apply --dry-run=server -f $Manifest 2>&1 | ForEach-Object { $_.ToString() }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    $text = $result -join "`n"
    if ($exitCode -eq 0) {
        throw "Expected policy '$ExpectedPolicy' to reject '$Manifest', but the API server accepted it."
    }
    if ($text -match [regex]::Escape($ExpectedPolicy)) {
        Write-Host "PASS: Kyverno policy $ExpectedPolicy rejected $([System.IO.Path]::GetFileName($Manifest))." -ForegroundColor Green
        return
    }
    if ($AllowPodSecurity -and $text -match '(?i)podsecurity|pod security|violates podsecurity') {
        Write-Host "PASS: Pod Security Admission rejected $([System.IO.Path]::GetFileName($Manifest)) before the overlapping Kyverno policy was evaluated." -ForegroundColor Green
        return
    }
    else {
        throw "'$Manifest' was rejected, but not by expected policy '$ExpectedPolicy'. Output:`n$text"
    }
}

function Assert-PrometheusQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query,
        [double]$Minimum = 1,
        [int]$Attempts = 18,
        [int]$DelaySeconds = 5
    )

    $encoded = [System.Uri]::EscapeDataString($Query)
    $path = "/api/v1/namespaces/monitoring/services/http:monitoring-prometheus:9090/proxy/api/v1/query?query=$encoded"
    $lastObservation = "no result"

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            $rawResponse = & kubectl get --raw $path 2>$null
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }

        if ($exitCode -eq 0 -and $rawResponse) {
            try {
                $response = (($rawResponse | ForEach-Object { $_.ToString() }) -join "") | ConvertFrom-Json
                $results = @($response.data.result)
                if ($response.status -eq "success" -and $results.Count -gt 0) {
                    $values = @(
                        foreach ($result in $results) {
                            [double]::Parse(
                                [string]$result.value[1],
                                [System.Globalization.CultureInfo]::InvariantCulture
                            )
                        }
                    )
                    $observedMinimum = ($values | Measure-Object -Minimum).Minimum
                    $lastObservation = "minimum value $observedMinimum"
                    if ($observedMinimum -ge $Minimum) {
                        Write-Host "PASS: $Name ($lastObservation)." -ForegroundColor Green
                        return
                    }
                }
                else {
                    $lastObservation = "empty Prometheus result"
                }
            }
            catch {
                $lastObservation = "invalid Prometheus response: $($_.Exception.Message)"
            }
        }
        else {
            $lastObservation = "Prometheus API request failed"
        }

        if ($attempt -lt $Attempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw "Prometheus check '$Name' did not reach the required value $Minimum after $Attempts attempts ($lastObservation). Query: $Query"
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required."
}

Write-Host "Checking application readiness..." -ForegroundColor Cyan
Invoke-Checked -Command "kubectl" -Arguments @("-n", "cnas", "rollout", "status", "deployment/php-app", "--timeout=180s")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "cnas", "rollout", "status", "statefulset/mysql", "--timeout=180s")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "cnas", "get", "endpoints", "php-service", "mysql-service")

Invoke-TestJob -Name "cnas-smoke-test" -Manifest (Join-Path $TestDirectory "smoke-job.yaml")
& (Join-Path $PSScriptRoot "Test-LoadBalancing.ps1")
Invoke-TestJob -Name "cnas-gateway-controls-test" -Manifest (Join-Path $TestDirectory "gateway-controls-job.yaml") -TimeoutSeconds 180

if (-not $SkipNetworkPolicy) {
    Invoke-TestJob -Name "cnas-network-policy-test" -Manifest (Join-Path $TestDirectory "network-policy-job.yaml") -TimeoutSeconds 90
}
else {
    Write-Warning "NetworkPolicy enforcement test skipped. This should not be skipped for final evidence."
}

if (-not $SkipPolicyTests) {
    Write-Host "`nChecking Kyverno admission controls with server-side dry runs..." -ForegroundColor Cyan
    Assert-PolicyRejection -Manifest (Join-Path $TestDirectory "policy-deny-latest.yaml") -ExpectedPolicy "cnas-disallow-latest-tag"
    Assert-PolicyRejection -Manifest (Join-Path $TestDirectory "policy-require-resources.yaml") -ExpectedPolicy "cnas-require-resources"
    Assert-PolicyRejection -Manifest (Join-Path $TestDirectory "policy-require-nonroot.yaml") -ExpectedPolicy "cnas-require-run-as-non-root" -AllowPodSecurity
    Assert-PolicyRejection -Manifest (Join-Path $TestDirectory "policy-disallow-privileged.yaml") -ExpectedPolicy "cnas-restricted-containers" -AllowPodSecurity
}
else {
    Write-Warning "Kyverno policy tests skipped. This should not be skipped for final evidence."
}

Write-Host "`nChecking observability resources..." -ForegroundColor Cyan
Invoke-Checked -Command "kubectl" -Arguments @("-n", "monitoring", "get", "prometheus,alertmanager,probes,prometheusrules,servicemonitors")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "monitoring", "rollout", "status", "deployment/alloy", "--timeout=180s")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "monitoring", "rollout", "status", "deployment/blackbox-exporter", "--timeout=180s")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "cnas", "rollout", "status", "deployment/mysql-exporter", "--timeout=180s")
Invoke-Checked -Command "kubectl" -Arguments @("-n", "cnas", "rollout", "status", "deployment/redis-exporter", "--timeout=180s")

Write-Host "`nChecking live Prometheus series..." -ForegroundColor Cyan
Assert-PrometheusQuery -Name "blackbox exporter self-monitor" -Query 'max(up{namespace="monitoring",service="blackbox-exporter"})'
Assert-PrometheusQuery -Name "internal application probe" -Query 'min(probe_success{service="php-app"})'
Assert-PrometheusQuery -Name "HTTPS gateway probe" -Query 'min(probe_success{service="gateway"})'
Assert-PrometheusQuery -Name "MySQL target health" -Query 'max(mysql_up{namespace="cnas"})'
Assert-PrometheusQuery -Name "Redis target health" -Query 'max(redis_up{namespace="cnas"})'
Assert-PrometheusQuery -Name "Kong metrics target" -Query 'count(kong_node_info{namespace="kong"})'
Assert-PrometheusQuery -Name "Kong traffic metrics" -Query 'count(kong_http_requests_total{namespace="kong"})'
Assert-PrometheusQuery -Name "KIC configuration metrics" -Query 'count(ingress_controller_configuration_push_count{namespace="kong"})'
Assert-PrometheusQuery -Name "Kind node exporters" -Query 'count(node_uname_info)' -Minimum 4

Write-Host "`nPASS: readiness, HTTP routing, security controls, exporters, probes, Kong traffic metrics, and node monitoring completed." -ForegroundColor Green
Write-Host "Run Invoke-LoadTest.ps1 and Invoke-FailoverTest.ps1 -Execute separately for scaling and resilience evidence."
