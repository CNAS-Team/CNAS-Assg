# 🧪 Manual Testing Guide - Step by Step

Simple manual testing without any automation scripts.

---

## 📍 Step 1: Open Terminal

Open PowerShell or Command Prompt and navigate to your project:

```powershell
cd "c:\Cloud Native Architecture\CNAS-Assg"
```

---

## 🚀 Step 2: Start the Containers

```powershell
docker-compose up -d
```

**Expected output:**
```
Creating network "cnas-network" ... done
Creating volume "cnas-mysql-data" ... done
Creating cnas-mysql ... done
Creating cnas-php-app ... done
Creating cnas-phpmyadmin ... done
```

---

## ⏱️ Step 3: Wait for Startup

**Wait 60 seconds** for MySQL to initialize and PHP app to be ready.

You can grab a coffee ☕ or check the logs:

```powershell
docker-compose logs -f
```

Look for these messages:
- MySQL: `"mysqld: ready for connections"`
- PHP: `"Apache/2.4.x configured"`

Press `Ctrl+C` to stop viewing logs.

---

## ✅ Step 4: Check Container Status

```powershell
docker-compose ps
```

**Expected output:**
```
NAME              STATE
cnas-mysql        Up (healthy)
cnas-php-app      Up (healthy)
cnas-phpmyadmin   Up
```

All should show **"Up"** status.

❌ **If any container shows "Exit" or "Restarting":**
```powershell
docker-compose logs [container-name]
```

---

## 🌐 Step 5: Test PHP Application

Open your browser and go to:
```
http://localhost:8082
```

**What you should see:**
- ✅ Page loads successfully
- ✅ Title: "Team Members in Class -T01 Team – 02"
- ✅ "Add New Team Member" link
- ✅ Table with columns: ID, Student Name, Email, Actions
- ✅ No error messages

❌ **If you see an error:** Wait another 30 seconds, MySQL might still be initializing.

---

## 🗄️ Step 6: Test phpMyAdmin

Open your browser and go to:
```
http://localhost:8083
```

**Login with:**
- Server: `mysql`
- Username: `root`
- Password: `rootpass`

**What you should see:**
- ✅ phpMyAdmin dashboard loads
- ✅ Left sidebar shows "mydb" database
- ✅ Click "mydb" → see "users" table
- ✅ Click "users" → see columns: id, name, email

---

## 📝 Step 7: Test CREATE (Add User)

In your browser at http://localhost:8082:

1. Click **"Add New Team Member"**
2. Fill in the form:
   - Name: `Test Student`
   - Email: `test@example.com`
3. Click **Submit**

**Expected:**
- ✅ Redirected back to main page
- ✅ New user appears in the table
- ✅ User has ID = 1

---

## ✏️ Step 8: Test UPDATE (Edit User)

1. Click **"Edit"** next to the user
2. Change name to: `Updated Student`
3. Click **Submit**

**Expected:**
- ✅ Redirected back to main page
- ✅ Name changed to "Updated Student"
- ✅ Same ID (still 1)

---

## 🗑️ Step 9: Test DELETE (Remove User)

1. Click **"Delete"** next to the user
2. User disappears from the table

**Expected:**
- ✅ User removed
- ✅ Table is now empty

---

## 🔌 Step 10: Test Container Networking

```powershell
docker exec cnas-php-app ping mysql -c 3
```

**Expected:**
```
PING mysql (172.x.x.x) ...
3 packets transmitted, 3 received, 0% packet loss
```

---

## 💾 Step 11: Test Data Persistence

### Add some test data first:
1. Go to http://localhost:8082
2. Add 2-3 users with different names

### Restart containers:
```powershell
docker-compose down
docker-compose up -d
```

### Wait 60 seconds, then check:
```powershell
# Wait
Start-Sleep -Seconds 60

# Or just wait manually, then...
```

Go to http://localhost:8082

**Expected:**
- ✅ All your users are still there
- ✅ Same IDs
- ✅ No data lost

---

## 📊 Step 12: Check Resource Usage

```powershell
docker stats
```

Press `Ctrl+C` to exit.

**Look for:**
- CPU usage < 10% (when idle)
- Memory: MySQL ~200-400MB, PHP ~50-100MB

---

## 🔍 Step 13: Verify Database Structure

### Option A: Via phpMyAdmin
1. Go to http://localhost:8083
2. Click "mydb" → "users" → "Structure"
3. Verify columns and types

### Option B: Via Command Line
```powershell
docker exec -it cnas-mysql mysql -u root -prootpass
```

Then inside MySQL:
```sql
USE mydb;
SHOW TABLES;
DESCRIBE users;
exit;
```

**Expected table structure:**
- id: INT, PRIMARY KEY, AUTO_INCREMENT
- name: VARCHAR(100)
- email: VARCHAR(100)

---

## 🧹 Step 14: View Logs (Optional)

Check for any errors:

```powershell
# All logs
docker-compose logs

# Just MySQL
docker-compose logs mysql

# Just PHP app
docker-compose logs php-app

# Follow logs in real-time
docker-compose logs -f
```

**Look for:**
- ✅ No ERROR or FATAL messages
- ✅ MySQL: "ready for connections"
- ✅ PHP: Apache started successfully

---

## 🛑 Step 15: Stop Everything (When Done)

```powershell
docker-compose down
```

**To also remove data (clean slate):**
```powershell
docker-compose down -v
```

---

## ✅ Testing Checklist

Mark these off as you test:

### Basic Tests
- [ ] Containers started successfully
- [ ] All containers show "Up" status
- [ ] PHP app loads at http://localhost:8082
- [ ] phpMyAdmin loads at http://localhost:8083
- [ ] No error messages on web pages

### Database Tests
- [ ] Database "mydb" exists
- [ ] Table "users" has correct structure
- [ ] Can log into phpMyAdmin

### CRUD Tests
- [ ] **CREATE:** Can add new user
- [ ] **READ:** Users display in table
- [ ] **UPDATE:** Can edit user
- [ ] **DELETE:** Can remove user

### Advanced Tests
- [ ] Containers can ping each other
- [ ] Data survives restart
- [ ] Resource usage is normal
- [ ] No errors in logs

---

## 🎯 Success Criteria

Your testing is **SUCCESSFUL** if:

✅ All containers running  
✅ Web pages load without errors  
✅ Can create, read, update, delete users  
✅ Data persists after restart  
✅ No critical errors in logs  

---

## 🆘 Common Issues

### Issue: "Cannot connect to database"
**Wait longer** - MySQL takes 30-60 seconds to initialize on first start.

### Issue: "Page not loading"
```powershell
# Check if containers are running
docker-compose ps

# If not running, check logs
docker-compose logs
```

### Issue: "Port already in use"
```powershell
# Find what's using the port
netstat -ano | findstr :8082

# Change port in docker-compose.yml if needed
```

### Issue: Container keeps restarting
```powershell
# View error messages
docker-compose logs [container-name]
```

---

## 📸 Screenshots to Take

For your report/documentation:

1. `docker-compose ps` output
2. PHP app main page (http://localhost:8082)
3. User list with test data
4. Add/Edit user forms
5. phpMyAdmin database structure
6. `docker stats` output

---

## 🌐 Important URLs

```
Your CNAS Project:
- PHP Application:  http://localhost:8082
- phpMyAdmin:       http://localhost:8083

Your Existing Services:
- Jenkins:          http://localhost:8080  (unchanged)
```

---

## 📋 Quick Command Reference

```powershell
# Start
docker-compose up -d

# Stop
docker-compose down

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Clean everything
docker-compose down -v

# Stats
docker stats
```

---

## ⏱️ Time Estimate

- Setup and start: **5 minutes**
- Basic testing: **10 minutes**
- CRUD testing: **5 minutes**
- Advanced tests: **10 minutes**

**Total: ~30 minutes**

---

**That's it! Follow these steps in order and you'll thoroughly test your Docker setup manually.** 🎉
