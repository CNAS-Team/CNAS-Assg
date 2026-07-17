# ⚡ Quick Start - Manual Testing

**5 commands, 5 minutes, done.**

---

## 1️⃣ Navigate to project
```powershell
cd "c:\Cloud Native Architecture\CNAS-Assg"
```

## 2️⃣ Start containers
```powershell
docker-compose up -d
```

## 3️⃣ Wait (important!)
Wait 60 seconds for MySQL to initialize.

## 4️⃣ Check status
```powershell
docker-compose ps
```
All should show "Up (healthy)"

## 5️⃣ Open browser
```
http://localhost:8082
```

---

## ✅ Success?

You should see:
- "Team Members in Class -T01 Team – 02"
- A table with columns
- "Add New Team Member" link
- No errors

---

## 🧪 Test CRUD

1. **Add** a user (click "Add New Team Member")
2. **Edit** the user (click "Edit")
3. **Delete** the user (click "Delete")

All working? **You're done!** ✅

---

## 🛑 Stop when finished
```powershell
docker-compose down
```

---

## 🌐 URLs

- **PHP App:** http://localhost:8082
- **phpMyAdmin:** http://localhost:8083 (login: root/rootpass)
- **Jenkins:** http://localhost:8080 (your existing one)

---

## 🆘 Problems?

```powershell
# Check logs
docker-compose logs

# Restart
docker-compose restart

# Clean restart
docker-compose down -v
docker-compose up -d
```

---

**For detailed testing, see: MANUAL-TESTING.md**
