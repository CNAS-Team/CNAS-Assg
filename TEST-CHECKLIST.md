# ✅ Docker Testing Checklist

Quick reference checklist for testing your Docker implementation.

---

## 🚀 Quick Start (5 Minutes)

### Option 1: Automated Test
```powershell
cd "c:\Cloud Native Architecture\CNAS-Assg"
.\quick-test.ps1
```

### Option 2: Manual Test
```powershell
cd "c:\Cloud Native Architecture\CNAS-Assg"
docker-compose up -d
# Wait 60 seconds
Start-Sleep -Seconds 60
# Open browser to http://localhost:8080
```

---

## 📝 Testing Checklist

### ☑️ Pre-Testing (Before You Start)
- [ ] Docker Desktop is installed
- [ ] Docker Desktop is running (check system tray)
- [ ] You're in the correct directory: `c:\Cloud Native Architecture\CNAS-Assg`
- [ ] You have internet connection (to pull images)

**Commands:**
```powershell
docker --version
docker-compose --version
docker ps
```

---

### ☑️ Phase 1: Start Services (5 minutes)

**Commands:**
```powershell
# Clean any existing setup
docker-compose down -v

# Start services
docker-compose up -d

# Wait for startup (important!)
Start-Sleep -Seconds 60
```

**Checklist:**
- [ ] Command completes without errors
- [ ] You see: "Creating cnas-mysql ... done"
- [ ] You see: "Creating cnas-php-app ... done"
- [ ] You see: "Creating cnas-phpmyadmin ... done"

---

### ☑️ Phase 2: Verify Containers (2 minutes)

**Commands:**
```powershell
docker-compose ps
```

**Expected Output:**
```
NAME              STATE
cnas-mysql        Up (healthy)
cnas-php-app      Up (healthy)
cnas-phpmyadmin   Up
```

**Checklist:**
- [ ] All 3 containers show "Up" status
- [ ] MySQL shows "(healthy)" status
- [ ] PHP app shows "(healthy)" status
- [ ] No containers show "Restarting" or "Exit"

**❌ If containers are restarting:**
```powershell
docker-compose logs
```

---

### ☑️ Phase 3: Test Web Access (3 minutes)

**Browser Tests:**

1. **PHP Application:**
   - [ ] Open: http://localhost:8080
   - [ ] Page loads (no timeout)
   - [ ] You see: "Team Members in Class -T01 Team – 02"
   - [ ] You see: "Add New Team Member" link
   - [ ] You see a table with columns: ID, Student Name, Email, Actions
   - [ ] No error messages displayed

2. **phpMyAdmin:**
   - [ ] Open: http://localhost:8081
   - [ ] Login page appears
   - [ ] Login with: Server=`mysql`, Username=`root`, Password=`rootpass`
   - [ ] Dashboard loads successfully
   - [ ] You see "mydb" database in left sidebar

**❌ If pages don't load:**
```powershell
# Check if containers are running
docker-compose ps

# Check application logs
docker-compose logs php-app

# Wait longer (MySQL might still be initializing)
Start-Sleep -Seconds 30
```

---

### ☑️ Phase 4: Test Database (5 minutes)

**In phpMyAdmin (http://localhost:8081):**
- [ ] Click "mydb" database
- [ ] You see "users" table
- [ ] Click "users" table
- [ ] Click "Structure" tab
- [ ] Verify columns: `id`, `name`, `email`
- [ ] `id` is PRIMARY KEY and AUTO_INCREMENT

**Or via Command Line:**
```powershell
docker exec -it cnas-mysql mysql -u root -prootpass -e "USE mydb; SHOW TABLES; DESCRIBE users;"
```

**Expected Output:**
```
Tables_in_mydb
users

Field | Type         | Null | Key | Default | Extra
id    | int          | NO   | PRI | NULL    | auto_increment
name  | varchar(100) | YES  |     | NULL    |
email | varchar(100) | YES  |     | NULL    |
```

**Checklist:**
- [ ] Database "mydb" exists
- [ ] Table "users" exists
- [ ] Table has correct structure
- [ ] No errors in query

---

### ☑️ Phase 5: Test CRUD Operations (10 minutes)

**CREATE Test:**
1. [ ] Go to http://localhost:8080
2. [ ] Click "Add New Team Member"
3. [ ] Fill in: Name = "Test Student 1", Email = "test1@example.com"
4. [ ] Click Submit
5. [ ] You're redirected back to main page
6. [ ] New user appears in the table with ID = 1

**READ Test:**
- [ ] Main page displays the user you just created
- [ ] ID, Name, and Email are correct
- [ ] Edit and Delete links appear

**UPDATE Test:**
1. [ ] Click "Edit" next to the user
2. [ ] Change name to "Updated Student"
3. [ ] Click Submit
4. [ ] Redirected to main page
5. [ ] Name is updated in the table
6. [ ] ID remains the same

**DELETE Test:**
1. [ ] Click "Delete" next to the user
2. [ ] User disappears from the table
3. [ ] Table is now empty (or shows remaining users)

**Checklist:**
- [ ] Can create new users
- [ ] Can view users
- [ ] Can update existing users
- [ ] Can delete users
- [ ] No PHP errors displayed
- [ ] No database connection errors

---

### ☑️ Phase 6: Test Container Networking (3 minutes)

**Commands:**
```powershell
# Test DNS resolution (PHP container can find MySQL by name)
docker exec cnas-php-app ping mysql -c 3

# Test port connectivity
docker exec cnas-php-app nc -zv mysql 3306
```

**Expected Results:**
- [ ] Ping succeeds (0% packet loss)
- [ ] Port 3306 is "open"
- [ ] No "connection refused" errors

**Checklist:**
- [ ] Containers can communicate
- [ ] DNS resolution works
- [ ] MySQL port is accessible

---

### ☑️ Phase 7: Test Data Persistence (5 minutes)

**Setup:**
1. [ ] Add 2-3 test users via web interface
2. [ ] Note their names and IDs

**Test:**
```powershell
# Stop containers (without removing volumes)
docker-compose down

# Start again
docker-compose up -d

# Wait for startup
Start-Sleep -Seconds 60

# Check web page
```

**Verification:**
- [ ] Go to http://localhost:8080
- [ ] All previously added users still appear
- [ ] IDs are the same
- [ ] No data was lost

**This proves your volume is working! 🎉**

---

### ☑️ Phase 8: Test Health Checks (2 minutes)

**Commands:**
```powershell
# View health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health info
docker inspect cnas-php-app --format='{{.State.Health.Status}}'
```

**Checklist:**
- [ ] PHP app shows "healthy" status
- [ ] MySQL shows "healthy" status
- [ ] No containers show "unhealthy" status

---

### ☑️ Phase 9: Test Resource Usage (2 minutes)

**Commands:**
```powershell
# View resource stats (Press Ctrl+C to exit)
docker stats --no-stream
```

**Expected Values (approximate):**
- [ ] MySQL: ~200-400 MB RAM, <5% CPU (when idle)
- [ ] PHP App: ~20-100 MB RAM, <5% CPU (when idle)
- [ ] phpMyAdmin: ~20-50 MB RAM, <5% CPU (when idle)

**Checklist:**
- [ ] No container using excessive CPU (>50% when idle)
- [ ] No container using excessive memory (>1GB)
- [ ] Resource usage is reasonable

---

### ☑️ Phase 10: Test Logs (3 minutes)

**Commands:**
```powershell
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs mysql
docker-compose logs php-app

# Follow logs in real-time (Ctrl+C to exit)
docker-compose logs -f
```

**What to Look For:**
- [ ] MySQL: "mysqld: ready for connections"
- [ ] PHP App: "Apache/2.4.x configured"
- [ ] No critical errors (ERROR, FATAL)
- [ ] No repeated warnings

**Red Flags:**
- ❌ Connection refused errors
- ❌ Permission denied errors
- ❌ "Cannot find file" errors
- ❌ Containers continuously restarting

---

## 🎯 Final Verification (All Must Pass)

### Core Functionality ✅
- [ ] All 3 containers running
- [ ] PHP app accessible at http://localhost:8080
- [ ] phpMyAdmin accessible at http://localhost:8081
- [ ] Database initialized with correct structure
- [ ] Can create, read, update, delete users
- [ ] Data persists after restart

### Networking ✅
- [ ] Containers can communicate
- [ ] DNS resolution works (mysql hostname)
- [ ] Custom network created

### Health & Monitoring ✅
- [ ] Health checks pass
- [ ] Logs show no critical errors
- [ ] Resource usage is normal

### Security ✅
- [ ] Containers run as non-root user (check Dockerfile)
- [ ] Secrets not hardcoded in compose file
- [ ] Health checks enabled

---

## 📊 Testing Report

Fill this out after testing:

```
TESTING COMPLETED: [Date/Time]

✅ PASSED TESTS:
- [ ] Environment setup
- [ ] Container startup
- [ ] Web access (PHP app)
- [ ] Web access (phpMyAdmin)
- [ ] Database structure
- [ ] CRUD operations
- [ ] Container networking
- [ ] Data persistence
- [ ] Health checks
- [ ] Resource usage
- [ ] Logs verification

❌ FAILED TESTS:
- [List any failures]

⚠️ ISSUES ENCOUNTERED:
- [List any issues and how you resolved them]

OVERALL STATUS: ✅ PASS / ❌ FAIL

TIME TAKEN: ___ minutes

NOTES:
[Any additional observations]
```

---

## 🆘 Quick Troubleshooting

### Problem: Containers won't start
```powershell
docker-compose down -v
docker-compose up -d --build
```

### Problem: Can't access web pages
```powershell
# Check if running
docker-compose ps

# Wait longer
Start-Sleep -Seconds 60

# Try 127.0.0.1 instead of localhost
```

### Problem: Database connection errors
```powershell
# Check MySQL is ready
docker-compose logs mysql | Select-String "ready for connections"

# Restart services
docker-compose restart
```

### Problem: Port already in use
```powershell
# Find what's using the port
netstat -ano | findstr :8080

# Stop that process or change port in docker-compose.yml
```

---

## 📸 Required Screenshots (For Report)

Take these screenshots:

1. [ ] `docker-compose ps` showing all containers Up
2. [ ] PHP app main page (http://localhost:8080)
3. [ ] phpMyAdmin showing mydb database
4. [ ] Table with test data (after adding users)
5. [ ] `docker stats` output
6. [ ] Health check status (`docker ps` with Status column)
7. [ ] Network test output (ping mysql)
8. [ ] CRUD operation (before and after edit)

---

## ✅ Success Criteria

You can consider your testing **SUCCESSFUL** if:

1. ✅ All containers start and remain running
2. ✅ Both web interfaces are accessible
3. ✅ Database is properly initialized
4. ✅ All CRUD operations work
5. ✅ Data persists after restart
6. ✅ Health checks pass
7. ✅ No critical errors in logs
8. ✅ Resource usage is reasonable

---

## 🎓 What You've Demonstrated

By completing this checklist, you've proven:

- ✅ Docker containerization works
- ✅ Multi-container orchestration functions
- ✅ Container networking is configured correctly
- ✅ Data persistence is implemented
- ✅ Health monitoring is active
- ✅ Application is fully functional
- ✅ Your setup is production-ready (for dev/test)

---

## 📚 Next Steps After Testing

1. Document any issues you encountered
2. Take screenshots for your report
3. Review the DOCKER-SECURITY.md file
4. Test the Kubernetes deployment (k8s folder)
5. Set up CI/CD pipeline (Jenkinsfile)

---

**Good luck with your testing! 🚀**

For detailed explanations, see: **TESTING-GUIDE.md**
For quick automated test, run: **quick-test.ps1**
