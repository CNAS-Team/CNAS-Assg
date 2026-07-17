# 🔄 Docker Testing Flowchart

Visual guide to testing your Docker configuration.

---

## 🎯 Quick Path (Choose Your Route)

```
START HERE
    ↓
    ├─→ Want automated testing? → Run quick-test.ps1 → DONE ✅
    │
    └─→ Want detailed testing? → Follow flowchart below ↓
```

---

## 📊 Complete Testing Flowchart

```
┌─────────────────────────────────────────────────────────────┐
│                     START TESTING                           │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Pre-Check                                          │
│  ┌────────────────────────────────────────────────┐         │
│  │ Run: docker --version                          │         │
│  │ Run: docker ps                                 │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
                   ✅ Works?
                   ↙     ↘
                YES       NO → Install/Start Docker → Back to STEP 1
                 ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Navigate to Project                                │
│  ┌────────────────────────────────────────────────┐         │
│  │ cd "c:\Cloud Native Architecture\CNAS-Assg"   │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Clean Environment                                  │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker-compose down -v                         │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Start Services                                     │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker-compose up -d                           │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
                 ✅ Success?
                 ↙       ↘
              YES         NO → Check logs → Fix errors → Back to STEP 3
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Wait for Startup                                   │
│  ┌────────────────────────────────────────────────┐         │
│  │ ⏱️  Wait 60 seconds                             │         │
│  │ (MySQL needs time to initialize)               │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Verify Containers                                  │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker-compose ps                              │         │
│  │                                                │         │
│  │ Expected:                                      │         │
│  │ ✅ cnas-mysql       Up (healthy)               │         │
│  │ ✅ cnas-php-app     Up (healthy)               │         │
│  │ ✅ cnas-phpmyadmin  Up                         │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
              All containers Up?
                 ↙       ↘
              YES         NO → Check logs → Troubleshoot → Back to STEP 5
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 7: Test Web Access                                    │
│  ┌────────────────────────────────────────────────┐         │
│  │ Open Browser:                                  │         │
│  │ • http://localhost:8080  (PHP App)            │         │
│  │ • http://localhost:8081  (phpMyAdmin)         │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
              Both pages load?
                 ↙       ↘
              YES         NO → Wait 30s → Try again → Check logs
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 8: Verify Database                                    │
│  ┌────────────────────────────────────────────────┐         │
│  │ In phpMyAdmin:                                 │         │
│  │ Login: root / rootpass                         │         │
│  │ Check: mydb database exists                    │         │
│  │ Check: users table exists                      │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
               Database OK?
                 ↙       ↘
              YES         NO → Check init script → Restart
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 9: Test CRUD Operations                               │
│                                                              │
│  CREATE Test:                                               │
│  ┌────────────────────────────────────────────────┐         │
│  │ 1. Click "Add New Team Member"                │         │
│  │ 2. Enter Name: Test Student                   │         │
│  │ 3. Enter Email: test@example.com              │         │
│  │ 4. Submit                                      │         │
│  └────────────────────────────────────────────────┘         │
│                       ↓                                      │
│              User created? ─NO→ Check PHP logs              │
│                       ↓ YES                                  │
│  READ Test:                                                 │
│  ┌────────────────────────────────────────────────┐         │
│  │ • View main page                               │         │
│  │ • User appears in table                        │         │
│  └────────────────────────────────────────────────┘         │
│                       ↓                                      │
│              User visible? ─NO→ Check database              │
│                       ↓ YES                                  │
│  UPDATE Test:                                               │
│  ┌────────────────────────────────────────────────┐         │
│  │ 1. Click "Edit"                                │         │
│  │ 2. Change name to "Updated Student"           │         │
│  │ 3. Submit                                      │         │
│  └────────────────────────────────────────────────┘         │
│                       ↓                                      │
│              Name updated? ─NO→ Check update.php            │
│                       ↓ YES                                  │
│  DELETE Test:                                               │
│  ┌────────────────────────────────────────────────┐         │
│  │ 1. Click "Delete"                              │         │
│  │ 2. User disappears                             │         │
│  └────────────────────────────────────────────────┘         │
│                       ↓                                      │
│              User deleted? ─NO→ Check delete.php            │
│                       ↓ YES                                  │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 10: Test Networking                                   │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker exec cnas-php-app ping mysql -c 3      │         │
│  │ docker exec cnas-php-app nc -zv mysql 3306    │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
                Ping succeeds?
                 ↙       ↘
              YES         NO → Check network → docker network ls
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 11: Test Data Persistence                             │
│  ┌────────────────────────────────────────────────┐         │
│  │ 1. Add 2-3 test users                         │         │
│  │ 2. docker-compose down                         │         │
│  │ 3. docker-compose up -d                        │         │
│  │ 4. Wait 60 seconds                             │         │
│  │ 5. Check if users still exist                  │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
               Data persisted?
                 ↙       ↘
              YES         NO → Check volume → docker volume ls
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 12: Test Health Checks                                │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker ps --format "table {{.Names}}\t{{.Status}}"│      │
│  │                                                │         │
│  │ Expected: (healthy) status for:               │         │
│  │ • cnas-mysql                                   │         │
│  │ • cnas-php-app                                 │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
               All healthy?
                 ↙       ↘
              YES         NO → Wait longer → Check health config
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 13: Check Resources                                   │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker stats --no-stream                       │         │
│  │                                                │         │
│  │ Expected:                                      │         │
│  │ • CPU < 10% (when idle)                       │         │
│  │ • Memory < 1GB per container                  │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
            Resources normal?
                 ↙       ↘
              YES         NO → Investigate high usage
               ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 14: Review Logs                                       │
│  ┌────────────────────────────────────────────────┐         │
│  │ docker-compose logs                            │         │
│  │                                                │         │
│  │ Look for:                                      │         │
│  │ ✅ "mysqld: ready for connections"             │         │
│  │ ✅ "Apache configured"                         │         │
│  │ ❌ No ERROR or FATAL messages                  │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
              No errors?
                 ↙       ↘
              YES         NO → Fix errors → Restart
               ↓
┌─────────────────────────────────────────────────────────────┐
│                   ✅ TESTING COMPLETE                        │
│                                                              │
│  ALL TESTS PASSED! 🎉                                       │
│                                                              │
│  Your Docker implementation is working correctly.           │
│                                                              │
│  Next Steps:                                                │
│  • Take screenshots for documentation                       │
│  • Fill out testing report                                  │
│  • Review security checklist                                │
│  • Test Kubernetes deployment                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚨 Error Resolution Flowchart

```
┌─────────────────────────────────────────────────────────────┐
│                    ENCOUNTERED ERROR                         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
                What's the error?
                       ↓
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
   Container      Web page      Database
   won't start    won't load    error
        ↓              ↓              ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Check logs:  │ │ Wait 60s     │ │ Check MySQL: │
│ docker-compose│ │              │ │ docker logs  │
│ logs         │ │ Try again    │ │ cnas-mysql   │
│              │ │      ↓       │ │      ↓       │
│ Look for:    │ │ Still fails? │ │ Look for:    │
│ • Port in use│ │      ↓       │ │ • Init error │
│ • File error │ │ Check if     │ │ • Permission │
│ • Permission │ │ container    │ │   denied     │
│              │ │ is running:  │ │              │
│      ↓       │ │ docker ps    │ │      ↓       │
│ Fix issue    │ │      ↓       │ │ Restart:     │
│      ↓       │ │ Check port:  │ │ docker-compose│
│ Restart:     │ │ netstat -ano │ │ restart mysql│
│ docker-compose│ │ findstr 8080│ │              │
│ restart      │ │              │ │              │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       └────────────────┴────────────────┘
                        ↓
                   Try again
                        ↓
                   ✅ Fixed?
                   ↙     ↘
                YES      NO → Check TESTING-GUIDE.md
                 ↓           Troubleshooting section
         Continue testing
```

---

## 🎯 Decision Tree: Which Test to Run?

```
                    START
                      ↓
        Do you have 5 minutes or less?
                ↙           ↘
              YES            NO
               ↓              ↓
       ┌───────────────┐  ┌──────────────────┐
       │ Run:          │  │ Have 30 minutes? │
       │ quick-test.ps1│  └────┬─────────────┘
       └───────────────┘       ↓
                          ↙         ↘
                        YES          NO
                         ↓            ↓
               ┌─────────────────┐  ┌──────────────┐
               │ Follow:         │  │ Use:         │
               │ TEST-CHECKLIST  │  │ TESTING-GUIDE│
               │ (all phases)    │  │ (pick phases)│
               └─────────────────┘  └──────────────┘
```

---

## 📊 Testing Phases Time Estimate

```
Phase 1: Pre-Check              [ 2 min] ████░░░░░░
Phase 2: Start Services         [ 3 min] ██████░░░░
Phase 3: Verify Containers      [ 2 min] ████░░░░░░
Phase 4: Test Web Access        [ 3 min] ██████░░░░
Phase 5: Verify Database        [ 3 min] ██████░░░░
Phase 6: Test CRUD              [10 min] ████████████████████
Phase 7: Test Networking        [ 3 min] ██████░░░░
Phase 8: Test Persistence       [ 5 min] ██████████░░
Phase 9: Test Health Checks     [ 2 min] ████░░░░░░
Phase 10: Check Resources       [ 2 min] ████░░░░░░
                                ────────
                    TOTAL:      [35 min]
```

---

## 🎓 Testing Priority Matrix

```
                    │ High Priority        │ Medium Priority     │ Low Priority
────────────────────┼─────────────────────┼────────────────────┼──────────────
MUST TEST           │ • Start services     │ • Health checks    │ • Resource
(Before showing     │ • Web access         │ • Networking       │   monitoring
 to anyone)         │ • CRUD operations    │ • Logs review      │
────────────────────┼─────────────────────┼────────────────────┼──────────────
SHOULD TEST         │ • Data persistence   │ • Error handling   │ • Performance
(Before            │ • Database structure │                    │   testing
 deployment)        │                      │                    │
────────────────────┼─────────────────────┼────────────────────┼──────────────
NICE TO TEST        │ • Multiple users     │ • Load testing     │ • Stress
(If time permits)   │ • Edge cases         │                    │   testing
```

---

## ✅ Success Path (Happy Flow)

```
START
  ↓
Pre-Check ✅
  ↓
Start Services ✅
  ↓
All Containers Up ✅
  ↓
Web Pages Load ✅
  ↓
Database Initialized ✅
  ↓
CRUD Works ✅
  ↓
Network OK ✅
  ↓
Data Persists ✅
  ↓
Health Checks Pass ✅
  ↓
Resources Normal ✅
  ↓
No Errors in Logs ✅
  ↓
🎉 SUCCESS! 🎉
  ↓
Document Results
  ↓
Take Screenshots
  ↓
DONE ✅
```

---

## 🔄 Quick Commands Reference

```
┌─────────────────────────────────────────────────────────────┐
│  MOST USED COMMANDS                                          │
├─────────────────────────────────────────────────────────────┤
│  Start:      docker-compose up -d                           │
│  Stop:       docker-compose down                            │
│  Status:     docker-compose ps                              │
│  Logs:       docker-compose logs -f                         │
│  Restart:    docker-compose restart                         │
│  Clean:      docker-compose down -v                         │
│  Rebuild:    docker-compose up -d --build                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Quick Status Check

```
Run this to check everything at once:
────────────────────────────────────────────────────────────
docker-compose ps && `
echo "━━━━━━━━━━━━━━━━━━━━━━" && `
curl -s http://localhost:8080 | Select-String "Team Members" && `
echo "✅ PHP App: OK" || echo "❌ PHP App: FAIL" && `
docker exec cnas-mysql mysql -u root -prootpass -e "SHOW DATABASES" | Select-String "mydb" && `
echo "✅ Database: OK" || echo "❌ Database: FAIL"
────────────────────────────────────────────────────────────
```

---

**Use this flowchart alongside:**
- `quick-test.ps1` - Automated testing
- `TEST-CHECKLIST.md` - Step-by-step checklist
- `TESTING-GUIDE.md` - Detailed guide with explanations
