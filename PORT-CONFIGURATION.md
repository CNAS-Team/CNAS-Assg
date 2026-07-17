# 🔌 Port Configuration Guide

## Current Port Assignments

```
┌─────────────────────────────────────────────────┐
│  Service        │  Port   │  URL               │
├─────────────────┼─────────┼────────────────────┤
│  Jenkins        │  8080   │  localhost:8080    │ ← Your existing
│  PHP App        │  8082   │  localhost:8082    │ ← This project
│  phpMyAdmin     │  8083   │  localhost:8083    │ ← This project
│  MySQL          │  3306   │  internal only     │ ← This project
└─────────────────────────────────────────────────┘
```

## ✅ No Conflicts!

Your Docker setup is configured to **avoid Jenkins on port 8080**.

- ✅ Jenkins continues running on **8080**
- ✅ PHP Application uses **8082**
- ✅ phpMyAdmin uses **8083**
- ✅ MySQL uses internal port 3306 (not exposed externally)

## 🌐 Access URLs

### Your CNAS Project (Docker):
```
PHP Application:  http://localhost:8082
phpMyAdmin:       http://localhost:8083
```

### Your Existing Services:
```
Jenkins:          http://localhost:8080  (unchanged)
```

## 🔧 Changing Ports (If Needed)

If ports 8082 or 8083 are also in use, edit `docker-compose.yml`:

```yaml
services:
  php-app:
    ports:
      - "8084:80"  # Change left number (host port)
  
  phpmyadmin:
    ports:
      - "8085:80"  # Change left number (host port)
```

**Remember:** Only change the **left number** (host port), not the right (container port).

## 🔍 Check Available Ports

```powershell
# See what's using ports
netstat -ano | findstr :8080
netstat -ano | findstr :8082
netstat -ano | findstr :8083
```

## 📝 Update Testing Commands

After changing ports, update these URLs in:
- START-HERE.md
- TEST-CHECKLIST.md
- TESTING-GUIDE.md
- quick-test.ps1

Or just remember your new port numbers!

## ⚡ Quick Test

```powershell
# Test your ports
curl http://localhost:8080  # Should show Jenkins
curl http://localhost:8082  # Should show PHP app (after docker-compose up)
curl http://localhost:8083  # Should show phpMyAdmin (after docker-compose up)
```

## 🎯 Summary

**Current configuration:**
- ✅ All port conflicts avoided
- ✅ Jenkins unaffected on 8080
- ✅ PHP App on 8082
- ✅ phpMyAdmin on 8083
- ✅ Ready to test!

**Just run:**
```powershell
.\quick-test.ps1
# Then visit: http://localhost:8082
```
