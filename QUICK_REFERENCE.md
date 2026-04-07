# 🚀 DigitalOcean Setup - Quick Reference Card

## 📌 One-Time Setup (on DigitalOcean Droplet)

```bash
# 1. SSH into your droplet
ssh root@YOUR_DROPLET_IP

# 2. Run automated setup
bash <(curl -s https://raw.githubusercontent.com/YOUR_REPO/setup-android-do.sh)

# OR manually: Copy paste the entire setup script
```

**⏱️ Time: 10-15 minutes**

---

## 🎯 Every Time You Want to Run Tests

### From Your Local Machine:

**Option 1: Copy entire project**
```bash
scp -r ./projecttestand root@YOUR_IP:/root/
```

**Option 2: Sync changes only (faster)**
```bash
rsync -avz --delete ./projecttestand/app/ root@YOUR_IP:/root/projecttestand/app/
rsync -avz ./projecttestand/build.gradle root@YOUR_IP:/root/projecttestand/
```

### On DigitalOcean Droplet:

```bash
# Connect
ssh root@YOUR_IP

# Navigate to project
cd projecttestand

# Make runner executable
chmod +x run-tests-do.sh

# Run tests
./run-tests-do.sh
```

**⏱️ Time: 2-3 minutes**

---

## 🧪 Test Options in `run-tests-do.sh`

```
[1] Unit Tests        → Fast (~10 seconds), no emulator needed
[2] Instrumentation   → Slower (~2-3 minutes), uses emulator
[3] Both              → Complete test suite
```

---

## 📋 Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "adb: command not found" | `source ~/.bashrc` |
| "Emulator won't start" | `cat /tmp/emulator.log` |
| "Tests timeout" | Increase droplet size (→ $24/month) |
| "Gradle build fails" | `./gradlew clean && ./gradlew build` |
| "Permission denied" | `chmod +x *.sh` |

---

## 💰 DigitalOcean Costs

| Size | CPU | RAM | Disk | Price/mo |
|------|-----|-----|------|----------|
| $5 | 1 | 512MB | 10GB | ❌ Too small |
| $6 | 1 | 1GB | 25GB | ⚠️ Borderline |
| $12 | 2 | 2GB | 50GB | ✅ Good |
| $18 | 2 | 4GB | 80GB | 🎯 **Best** |
| $24 | 4 | 8GB | 160GB | 🚀 Excellent |

**Recommendation: Start with $18/month**

---

## 🔄 Workflow Example

```
Day 1: Create Droplet + Run Setup (15 min)
       ↓
Day 2-N: Make code changes locally
         ↓
         scp/rsync to droplet (1 min)
         ↓
         ./run-tests-do.sh (3 min)
         ↓
         Get results
```

---

## 🎯 Complete CLI Script (Copy-Paste Ready)

```bash
#!/bin/bash
# Complete local → remote workflow

DROPLET_IP="YOUR_DROPLET_IP"
PROJECT_DIR="$HOME/Desktop/projecttestand"

# 1. Sync project
echo "📤 Syncing project..."
rsync -avz --delete "$PROJECT_DIR/app/" "root@$DROPLET_IP:/root/projecttestand/app/"
rsync -avz "$PROJECT_DIR/build.gradle" "root@$DROPLET_IP:/root/projecttestand/"

# 2. Run tests remotely
echo "🧪 Running tests..."
ssh root@$DROPLET_IP 'cd projecttestand && ./run-tests-do.sh'

# 3. Get results
echo "✅ Done!"
```

---

## 📞 Emergency Commands

```bash
# Stop everything
ssh root@YOUR_IP 'adb emu kill && pkill -f emulator'

# Start fresh
ssh root@YOUR_IP 'adb kill-server && adb start-server'

# Manual emulator start
ssh root@YOUR_IP 'nohup emulator -avd test_device -no-window -no-audio -no-boot-anim &'

# Check what's running
ssh root@YOUR_IP 'ps aux | grep -E "emulator|adb|gradle"'
```

---

## ✨ Pro Tips

✅ Use SSH keys → No password every time  
✅ Keep emulator running → Use `nohup` or `screen`  
✅ Monitor droplet → Check DigitalOcean console  
✅ Set up alerts → If CPU/RAM high  
✅ Automate with CI/CD → GitHub Actions → DigitalOcean  

---

## 🚀 Next Level: GitHub Actions + DigitalOcean

```yaml
# .github/workflows/test.yml
name: Android Tests on DigitalOcean

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests on DO droplet
        run: |
          ssh root@${{ secrets.DROPLET_IP }} \
            'cd projecttestand && ./run-tests-do.sh'
```

---

## 📚 Reference Files

| File | Purpose |
|------|---------|
| `DIGITALOCEAN_SETUP.md` | Full detailed guide |
| `setup-android-do.sh` | Automated setup script |
| `run-tests-do.sh` | Test runner script |
| `QUICK_REFERENCE.md` | This file |

---

**Good luck! You've got this! 🎉**
