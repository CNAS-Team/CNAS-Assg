# 🧪 Docker Configuration Testing Guide

Complete step-by-step guide to test your Docker implementation from scratch.

---

## 📋 Prerequisites Check

Before starting, verify you have:
- [ ] Docker Desktop installed and running
- [ ] Docker Compose installed
- [ ] Git Bash or PowerShell
- [ ] Internet connection (to pull images)

---

## 🚀 Step-by-Step Testing Process

### **PHASE 1: Environment Setup** ⚙️

#### Step 1.1: Navigate to Project Directory
```powershell
# Open PowerShell and navigate to your project
cd "c:\Cloud Native Architecture\CNAS-Assg"

# Verify you're in the right directory
dir
# You should see: Dockerfile, docker-compose.yml, k8s folder, etc.
```

#### Step 1.2: Verify Docker is Running
```powershell
# Check Docker version
docker --version
# Expected output: Docker version 20.x.x or higher

# Check Docker Compose version
docker-compose --version
# Expected output: Docker Compose version v2.x.x or higher

# Check Docker daemon is running
docker ps
# Should show table headers (may be empty) - no errors
```

**❌ If you get errors:**
- Open Docker Desktop application
- Wait for it to fully start (whale icon in system tray should be stable)
- Try again

#### Step 1.3: Run Validation Script (Optional but Recommended)
```powershell
# Run the validation script
.\validate-docker.ps1

# Review the output
# ✓ = Good, ⚠ = Warning, ✗ = Error
```

---

### **PHASE 2: Docker Compose Testing** 🐋

#### Step 2.1: Clean Any Existing Containers
```powershell
# Stop and remove any existing containers
docker-compose down -v

# Verify nothing is running
docker ps
# Should be empty or not show cnas-related containers
```

#### Step 2.2: Start Services
```powershell
# Start all services in detached mode
docker-compose up -d

# Expected output:
# Creating network "cnas-network"
# Creating volume "cnas-mysql-data"
# Creating cnas-mysql ... done
# Creating cnas-php-app ... done
# Creating cnas-phpmyadmin ... done
```

**✅ Success indicators:**
- No error messages
- All 3 services created
- Process completes without hanging

#### Step 2.3: Verify Containers are Running
```powershell
# Check container status
docker-compose ps

# Expected output - all should show "Up" status:
# NAME              STATUS
# cnas-mysql        Up (healthy)
# cnas-php-app      Up (healthy)
# cnas-phpmyadmin   Up
```

**Wait 30-60 seconds** for health checks to pass after initial startup.

#### Step 2.4: Check Container Logs
```powershell
# Check MySQL logs
docker-compose logs mysql

# Look for:
# ✅ "mysqld: ready for connections"
# ✅ "MySQL init process done. Ready for start up."

# Check PHP app logs
docker-compose logs php-app

# Look for:
# ✅ "Apache/2.4.x configured"
# ✅ No PHP errors or warnings

# Follow logs in real-time (press Ctrl+C to exit)
docker-compose logs -f
```

---

### **PHASE 3: Network and Connectivity Testing** 🌐

#### Step 3.1: Test Container-to-Container Communication
```powershell
# Ping MySQL from PHP app (verify DNS resolution)
docker exec cnas-php-app ping mysql -c 3

# Expected output:
# PING mysql (172.x.x.x) ...
# 3 packets transmitted, 3 received, 0% packet loss

# Test MySQL port connectivity
docker exec cnas-php-app nc -zv mysql 3306

# Expected output:
# mysql (172.x.x.x:3306) open
```

#### Step 3.2: Verify Network Configuration
```powershell
# List Docker networks
docker network ls

# Should see: cnas-network

# Inspect the network
docker network inspect cnas-network

# Verify all 3 containers are connected
```

---

### **PHASE 4: Application Testing** 🎯

#### Step 4.1: Test PHP Application Access
```powershell
# Open your web browser and navigate to:
# http://localhost:8080

# You should see:
# ✅ Page title: "CNAS Assignment - Team Members List"
# ✅ Table with headers: ID, Student Name, Email, Actions
# ✅ Link: "Add New Team Member"
# ✅ No error messages

# OR test with curl from command line:
curl http://localhost:8080

# Should return HTML content (no connection errors)
```

**🔍 What to look for:**
- ✅ Page loads successfully
- ✅ No database connection errors
- ✅ Table is displayed (may be empty initially)
- ✅ No PHP warnings or errors

**❌ If you see errors:**
- "Database connection failed" → MySQL not ready yet (wait 30 more seconds)
- "Connection refused" → Container not running (check `docker-compose ps`)
- Blank page → Check PHP logs: `docker-compose logs php-app`

#### Step 4.2: Test phpMyAdmin Access
```powershell
# Open browser to:
# http://localhost:8081

# Login credentials:
# Server: mysql
# Username: root
# Password: rootpass

# You should see:
# ✅ phpMyAdmin dashboard
# ✅ "mydb" database in left sidebar
# ✅ "users" table inside mydb
```

#### Step 4.3: Verify Database Structure
**In phpMyAdmin:**
1. Click on "mydb" database
2. Click on "users" table
3. Click "Structure" tab
4. Verify columns:
   - ✅ id (INT, PRIMARY KEY, AUTO_INCREMENT)
   - ✅ name (VARCHAR 100)
   - ✅ email (VARCHAR 100)

**OR via Command Line:**
```powershell
# Connect to MySQL container
docker exec -it cnas-mysql mysql -u root -prootpass

# Inside MySQL prompt, run:
USE mydb;
SHOW TABLES;
DESCRIBE users;

# Expected output:
# +-------+--------------+------+-----+---------+----------------+
# | Field | Type         | Null | Key | Default | Extra          |
# +-------+--------------+------+-----+---------+----------------+
# | id    | int          | NO   | PRI | NULL    | auto_increment |
# | name  | varchar(100) | YES  |     | NULL    |                |
# | email | varchar(100) | YES  |     | NULL    |                |
# +-------+--------------+------+-----+---------+----------------+

# Exit MySQL:
exit;
```

---

### **PHASE 5: CRUD Operations Testing** 📝

#### Step 5.1: Test CREATE (Add New User)
**Via Browser:**
1. Navigate to http://localhost:8080
2. Click "Add New Team Member"
3. Fill in the form:
   - Name: `Test Student`
   - Email: `test@example.com`
4. Click Submit

**Expected Result:**
- ✅ Redirected back to main page
- ✅ New user appears in the table
- ✅ User has ID = 1

**Via phpMyAdmin:**
1. Go to http://localhost:8081
2. Navigate to mydb → users
3. Click "Insert" tab
4. Add test data and click "Go"

#### Step 5.2: Test READ (View Users)
```powershell
# Navigate to main page
# http://localhost:8080

# Verify:
# ✅ All users display in table
# ✅ ID, Name, Email columns show correctly
# ✅ Edit and Delete links appear
```

#### Step 5.3: Test UPDATE (Edit User)
**Via Browser:**
1. Click "Edit" next to a user
2. Modify the name or email
3. Click Submit

**Expected Result:**
- ✅ Redirected to main page
- ✅ Changes reflected in table
- ✅ No duplicate entries created

#### Step 5.4: Test DELETE (Remove User)
**Via Browser:**
1. Click "Delete" next to a user
2. User should be removed from table

**Expected Result:**
- ✅ User disappears from list
- ✅ No errors displayed

---

### **PHASE 6: Health Check Testing** 💓

#### Step 6.1: Verify Health Status
```powershell
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Expected output:
# NAMES              STATUS
# cnas-php-app       Up X minutes (healthy)
# cnas-mysql         Up X minutes (healthy)
# cnas-phpmyadmin    Up X minutes

# Detailed health check info
docker inspect cnas-php-app --format='{{json .State.Health}}' | ConvertFrom-Json

# Check LastOutput and Status
```

#### Step 6.2: Test Health Check Endpoints
```powershell
# Test PHP app health
curl http://localhost:8080

# Should return 200 OK status

# Verify in browser - should load without errors
```

---

### **PHASE 7: Volume Persistence Testing** 💾

#### Step 7.1: Add Test Data
```powershell
# Add 3-5 test users via the web interface
# http://localhost:8080 → Add New Team Member

# Verify they appear in the table
```

#### Step 7.2: Restart Containers
```powershell
# Stop containers
docker-compose down

# Note: This does NOT remove volumes (no -v flag)

# Restart containers
docker-compose up -d

# Wait 30 seconds for services to be ready
```

#### Step 7.3: Verify Data Persisted
```powershell
# Open browser to http://localhost:8080

# Expected result:
# ✅ All previously added users still appear
# ✅ No data loss
# ✅ IDs remain the same
```

**This confirms volume persistence is working correctly!**

---

### **PHASE 8: Resource Usage Monitoring** 📊

#### Step 8.1: Check Resource Usage
```powershell
# View real-time resource stats
docker stats

# Press Ctrl+C to exit

# Look for:
# - CPU % (should be low when idle, <5%)
# - Memory usage (MySQL ~300MB, PHP ~50MB)
# - Network I/O
```

#### Step 8.2: Check Disk Usage
```powershell
# Check Docker disk usage
docker system df

# Expected output:
# TYPE            TOTAL    ACTIVE   SIZE
# Images          3        3        ~600MB
# Containers      3        3        ~5MB
# Local Volumes   1        1        ~150MB

# Detailed volume info
docker volume ls
docker volume inspect cnas-mysql-data
```

---

### **PHASE 9: Error Handling Testing** 🔧

#### Step 9.1: Test Database Connection Failure
```powershell
# Stop only MySQL
docker stop cnas-mysql

# Try accessing http://localhost:8080

# Expected result:
# ⚠ "Database connection failed" error message
# ✅ Application doesn't crash
# ✅ Error message is displayed properly

# Restart MySQL
docker start cnas-mysql

# Wait 30 seconds, then reload the page
# ✅ Application should work again
```

#### Step 9.2: Test Container Restart
```powershell
# Restart PHP app container
docker restart cnas-php-app

# Wait 20 seconds

# Check logs
docker logs cnas-php-app

# Verify:
# ✅ Apache started successfully
# ✅ No errors in startup
# ✅ Web page accessible
```

---

### **PHASE 10: Cleanup and Final Verification** 🧹

#### Step 10.1: View All Components
```powershell
# List everything created by Docker Compose
docker-compose ps
docker network ls | findstr cnas
docker volume ls | findstr cnas
docker images | findstr cnas
```

#### Step 10.2: Full Cleanup (Optional)
```powershell
# Stop and remove everything (including volumes)
docker-compose down -v

# Verify cleanup
docker ps -a | findstr cnas
# Should be empty

docker volume ls | findstr cnas
# Should be empty

# Note: Network and images may still exist (this is normal)
```

#### Step 10.3: Rebuild from Scratch
```powershell
# Remove old images
docker rmi cnas-assg-php-app

# Rebuild and start
docker-compose up -d --build

# Verify everything works again
# http://localhost:8080
```

---

## ✅ Testing Checklist

Mark each item as you test:

### Basic Functionality
- [ ] Docker and Docker Compose installed
- [ ] Containers start without errors
- [ ] All 3 services show "Up" status
- [ ] Health checks pass (healthy status)

### Network & Connectivity
- [ ] Containers can ping each other
- [ ] DNS resolution works (mysql hostname resolves)
- [ ] Port 3306 accessible from PHP container
- [ ] Custom network created successfully

### Application Access
- [ ] PHP app accessible at http://localhost:8080
- [ ] Page loads without errors
- [ ] No database connection errors
- [ ] phpMyAdmin accessible at http://localhost:8081

### Database Operations
- [ ] Database "mydb" exists
- [ ] Table "users" has correct structure
- [ ] Can insert new records (CREATE)
- [ ] Can view records (READ)
- [ ] Can update records (UPDATE)
- [ ] Can delete records (DELETE)

### Data Persistence
- [ ] Data survives container restart
- [ ] Volume mounted correctly
- [ ] No data loss after `docker-compose down` (without -v)

### Health & Monitoring
- [ ] Health checks return healthy status
- [ ] Logs show no critical errors
- [ ] Resource usage is reasonable
- [ ] Container restarts work properly

### Error Handling
- [ ] Graceful error when MySQL is down
- [ ] Application recovers after MySQL restart
- [ ] No unexpected crashes

---

## 🎯 Expected Final State

After completing all tests, you should have:

```
✅ 3 Running Containers:
   - cnas-mysql (MySQL 8.0)
   - cnas-php-app (PHP 8.2 with Apache)
   - cnas-phpmyadmin (phpMyAdmin)

✅ 1 Docker Network:
   - cnas-network

✅ 1 Docker Volume:
   - cnas-mysql-data (persistent database storage)

✅ 2 Accessible URLs:
   - http://localhost:8080 (PHP Application)
   - http://localhost:8081 (phpMyAdmin)

✅ Healthy Status:
   - All health checks passing
   - No errors in logs
   - CRUD operations working
   - Data persisting correctly
```

---

## 🆘 Common Issues & Solutions

### Issue 1: Port Already in Use
**Error:** "Port 8080 is already allocated"

**Solution:**
```powershell
# Find process using the port
netstat -ano | findstr :8080

# Kill the process or change port in docker-compose.yml
# Edit ports: "8081:80" instead of "8080:80"
```

### Issue 2: MySQL Takes Too Long to Start
**Error:** PHP app shows "Connection refused"

**Solution:**
```powershell
# Just wait longer (up to 60 seconds)
# Check MySQL logs:
docker-compose logs mysql

# Look for: "ready for connections"
```

### Issue 3: Container Keeps Restarting
**Error:** Container status shows "Restarting"

**Solution:**
```powershell
# Check logs for errors
docker-compose logs [service-name]

# Common causes:
# - Port conflict
# - Configuration error
# - Missing dependencies
```

### Issue 4: Cannot Access Web Pages
**Error:** "This site can't be reached"

**Solution:**
```powershell
# Verify container is running
docker ps

# Check if port is mapped
docker port cnas-php-app

# Try 127.0.0.1 instead of localhost
# http://127.0.0.1:8080
```

---

## 📸 Screenshot Checklist (For Documentation)

Take screenshots of:
1. [ ] `docker-compose ps` output (all services Up)
2. [ ] Main PHP application page (http://localhost:8080)
3. [ ] User list with sample data
4. [ ] Add new user form
5. [ ] phpMyAdmin dashboard
6. [ ] Database structure in phpMyAdmin
7. [ ] `docker stats` output
8. [ ] Health check status (`docker ps` with Status column)

---

## 🎓 What This Tests

By completing this guide, you've verified:

✅ **Containerization** - Application runs in isolated containers  
✅ **Multi-container Orchestration** - Multiple services work together  
✅ **Networking** - Containers communicate via Docker network  
✅ **Data Persistence** - Database data survives restarts  
✅ **Health Monitoring** - Automated health checks work  
✅ **Security** - Non-root execution, environment variables  
✅ **CRUD Operations** - Full application functionality  
✅ **Error Handling** - Graceful failure and recovery  

---

## 📊 Testing Report Template

Use this template to document your testing:

```
DOCKER IMPLEMENTATION TESTING REPORT
====================================

Tester: [Your Name]
Date: [Date]
Environment: Windows 11 / Docker Desktop [version]

PHASE 1: ENVIRONMENT SETUP
✅ Docker version: [version]
✅ Docker Compose version: [version]
✅ Validation script: [Pass/Fail]

PHASE 2: DOCKER COMPOSE
✅ Services started: [All 3 / Partial / Failed]
✅ Startup time: [seconds]
✅ Health checks: [Pass/Fail]

PHASE 3: CONNECTIVITY
✅ Container-to-container: [Pass/Fail]
✅ Network DNS: [Pass/Fail]
✅ Port connectivity: [Pass/Fail]

PHASE 4: APPLICATION
✅ PHP app accessible: [Yes/No]
✅ phpMyAdmin accessible: [Yes/No]
✅ Database initialized: [Yes/No]

PHASE 5: CRUD OPERATIONS
✅ Create user: [Pass/Fail]
✅ Read users: [Pass/Fail]
✅ Update user: [Pass/Fail]
✅ Delete user: [Pass/Fail]

PHASE 6: DATA PERSISTENCE
✅ Data survives restart: [Yes/No]
✅ Volume mounted: [Yes/No]

ISSUES ENCOUNTERED: [None / List issues]

OVERALL STATUS: ✅ PASS / ❌ FAIL

NOTES:
[Any additional observations]
```

---

## 🚀 Quick Test Command

For rapid verification, run these commands:

```powershell
# Quick test script
docker-compose up -d && `
Start-Sleep -Seconds 30 && `
docker-compose ps && `
curl http://localhost:8080 && `
docker stats --no-stream

# If all succeed, your setup is working! ✅
```

---

Good luck with your testing! 🎉
