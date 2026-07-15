# Docker Implementation Validation Script
# Run this script to validate your Docker setup

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Docker Implementation Validator" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Check Docker installation
Write-Host "1. Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✓ Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker not found! Please install Docker Desktop." -ForegroundColor Red
    $errors++
}

# Check Docker Compose
Write-Host "2. Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "   ✓ Docker Compose installed: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker Compose not found!" -ForegroundColor Red
    $errors++
}

# Check if Docker daemon is running
Write-Host "3. Checking Docker daemon..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "   ✓ Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
    $errors++
}

# Check for required files
Write-Host "4. Checking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "Dockerfile",
    "docker-compose.yml",
    ".dockerignore",
    ".env.example"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "   ✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $file is missing!" -ForegroundColor Red
        $errors++
    }
}

# Check for .env file
Write-Host "5. Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   ✓ .env file exists" -ForegroundColor Green
} else {
    Write-Host "   ⚠ .env file not found. Copy .env.example to .env and configure." -ForegroundColor Yellow
    $warnings++
}

# Check Dockerfile best practices
Write-Host "6. Validating Dockerfile..." -ForegroundColor Yellow
$dockerfile = Get-Content "Dockerfile" -Raw

if ($dockerfile -match "USER\s+\w+") {
    Write-Host "   ✓ Non-root user specified" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Consider adding non-root user (USER directive)" -ForegroundColor Yellow
    $warnings++
}

if ($dockerfile -match "HEALTHCHECK") {
    Write-Host "   ✓ Health check configured" -ForegroundColor Green
} else {
    Write-Host "   ⚠ No health check found" -ForegroundColor Yellow
    $warnings++
}

if ($dockerfile -match "php:\d+\.\d+-apache") {
    Write-Host "   ✓ Specific PHP version tag used" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Consider using specific version tags" -ForegroundColor Yellow
    $warnings++
}

# Try building the image
Write-Host "7. Testing Docker build..." -ForegroundColor Yellow
try {
    $buildOutput = docker build -t cnas-php-app-test:latest . 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Docker build successful" -ForegroundColor Green
        
        # Clean up test image
        docker rmi cnas-php-app-test:latest -f | Out-Null
    } else {
        Write-Host "   ✗ Docker build failed!" -ForegroundColor Red
        Write-Host "   Error: $buildOutput" -ForegroundColor Red
        $errors++
    }
} catch {
    Write-Host "   ✗ Build test failed: $_" -ForegroundColor Red
    $errors++
}

# Check if php-app directory exists
Write-Host "8. Checking application structure..." -ForegroundColor Yellow
$phpAppPath = "c:\Users\Lau Jia Qi\Downloads\cnas app\cnas app\php-app"
if (Test-Path $phpAppPath) {
    Write-Host "   ✓ PHP application directory found" -ForegroundColor Green
    
    $phpFiles = @("index.php", "db.php", "create.php", "update.php", "delete.php")
    foreach ($file in $phpFiles) {
        $fullPath = Join-Path $phpAppPath $file
        if (Test-Path $fullPath) {
            Write-Host "   ✓ $file exists" -ForegroundColor Green
        } else {
            Write-Host "   ✗ $file is missing!" -ForegroundColor Red
            $errors++
        }
    }
} else {
    Write-Host "   ⚠ PHP application directory not found at expected location" -ForegroundColor Yellow
    $warnings++
}

# Summary
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "✓ All checks passed! Your Docker implementation is ready." -ForegroundColor Green
} elseif ($errors -eq 0) {
    Write-Host "⚠ Validation passed with $warnings warning(s)" -ForegroundColor Yellow
    Write-Host "Review the warnings above for recommended improvements." -ForegroundColor Yellow
} else {
    Write-Host "✗ Validation failed with $errors error(s) and $warnings warning(s)" -ForegroundColor Red
    Write-Host "Please fix the errors above before proceeding." -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. docker-compose up -d       # Start the application" -ForegroundColor White
Write-Host "2. docker-compose logs -f     # View logs" -ForegroundColor White
Write-Host "3. Visit http://localhost:8080 # Access the app" -ForegroundColor White
Write-Host ""
