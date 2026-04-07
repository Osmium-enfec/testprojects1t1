# 🚀 Android Testing on DigitalOcean - Complete Setup Guide

## 📋 Table of Contents
1. [Create DigitalOcean Droplet](#1-create-digitalocean-droplet)
2. [Connect to Droplet](#2-connect-to-droplet)
3. [Automated Setup](#3-automated-setup)
4. [Run Tests](#4-run-tests)
5. [Troubleshooting](#5-troubleshooting)

---

## 1️⃣ Create DigitalOcean Droplet

### Step 1: Sign Up / Login
- Go to [DigitalOcean](https://www.digitalocean.com)
- Create account or login
- Click **Create** → **Droplets**

### Step 2: Configure Droplet
- **Image**: Ubuntu 22.04 LTS (x64)
- **Size**: **$18/month** (4GB RAM, 2 vCPU) - MINIMUM for Android
  - ⚠️ Avoid $5 plan (512MB RAM won't work)
  - 💡 Best: $18/month or higher
- **Region**: Choose closest to you (e.g., New York, San Francisco)
- **Authentication**: SSH Key (recommended) or Password
- **Hostname**: `android-tests` or any name

### Step 3: Create & Wait
- Click **Create Droplet**
- Wait 1-2 minutes for startup
- Copy your **Droplet IP Address** (e.g., `123.45.67.89`)

---

## 2️⃣ Connect to Droplet

### On macOS Terminal:
```bash
ssh root@YOUR_DROPLET_IP
# Example:
# ssh root@123.45.67.89
```

### If using password login:
```
Password: [enter your password]
```

### First time warning:
```
Are you sure you want to continue connecting (yes/no)? yes
```

✅ You should now see:
```
root@android-tests:~#
```

---

## 3️⃣ Automated Setup

### Option A: One-Command Setup (EASIEST) 🎯

Copy-paste this entire command in your DigitalOcean terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup-android-do.sh)
```

**OR** (if repo not available yet):

Download from local machine and run manually (see Option B)

### Option B: Manual Step-by-Step Setup

**1. Update system:**
```bash
apt-get update
apt-get upgrade -y
```

**2. Install dependencies:**
```bash
apt-get install -y \
  openjdk-21-jdk \
  wget \
  unzip \
  git \
  curl \
  libgl1-mesa-glx \
  libxrender1 \
  libxrandr2 \
  libxinerama1 \
  libxi6 \
  libxext6 \
  libx11-6 \
  libc6 \
  libstdc++6 \
  libpulse0 \
  libxkbcommon0 \
  xvfb \
  qemu-kvm
```

**3. Create Android SDK directory:**
```bash
mkdir -p /opt/android-sdk
cd /opt/android-sdk
```

**4. Download Android SDK:**
```bash
wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip
unzip commandlinetools-linux-10406996_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
rm commandlinetools-linux-10406996_latest.zip
```

**5. Set PATH:**
```bash
echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**6. Accept licenses:**
```bash
mkdir -p /opt/android-sdk/licenses
echo "8933bad161af4d61" > /opt/android-sdk/licenses/android-sdk-license
echo "d56f5187479451eabf01fb78af6dfcb131b33910" >> /opt/android-sdk/licenses/android-sdk-license
echo "84831b9409646a918e30573bab4c9c91346d8abd" > /opt/android-sdk/licenses/android-sdk-preview-license
```

**7. Install SDK components:**
```bash
yes | sdkmanager --sdk_root=/opt/android-sdk --licenses
sdkmanager --sdk_root=/opt/android-sdk "platforms;android-34"
sdkmanager --sdk_root=/opt/android-sdk "build-tools;34.0.0"
sdkmanager --sdk_root=/opt/android-sdk "platform-tools"
sdkmanager --sdk_root=/opt/android-sdk "system-images;android-34;default;x86_64"
sdkmanager --sdk_root=/opt/android-sdk "emulator"
```

**8. Create Android Virtual Device (AVD):**
```bash
yes | avdmanager create avd \
  -n test_device \
  -k "system-images;android-34;default;x86_64" \
  -d "medium_phone" \
  -c 2G
```

**9. Download Gradle:**
```bash
cd /tmp
wget https://services.gradle.org/distributions/gradle-8.14.4-bin.zip
unzip gradle-8.14.4-bin.zip
mv gradle-8.14.4 /opt/
echo 'export PATH=/opt/gradle-8.14.4/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
rm gradle-8.14.4-bin.zip
```

**10. Verify installation:**
```bash
java -version
gradle -version
sdkmanager --version
emulator -version
avdmanager list avd
```

✅ If all commands work → **Setup complete!**

---

## 4️⃣ Run Tests

### A. Upload Your Project

**From your local machine (macOS):**
```bash
scp -r /Users/enfec/Desktop/projecttestand root@YOUR_DROPLET_IP:/root/
```

### B. Connect & Navigate
```bash
ssh root@YOUR_DROPLET_IP
cd projecttestand
```

### C. Start ADB Server
```bash
adb start-server
```

### D. Start Emulator (Headless)
```bash
nohup emulator -avd test_device \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -memory 2048 \
  -accel off > /tmp/emulator.log 2>&1 &
```

Wait 30-60 seconds for emulator to boot...

### E. Verify Emulator Started
```bash
adb devices
```

You should see:
```
List of attached devices
emulator-5554          device
```

### F. Run Unit Tests (NO emulator needed)
```bash
cd projecttestand
./gradlew testDebugUnitTest
```

### G. Run Instrumentation Tests (with emulator)
```bash
./gradlew connectedAndroidTest
```

### H. View Test Results
```bash
find app/build/outputs -name "*.xml" -o -name "*.html"
cat app/build/outputs/androidTest-results/connected/index.html
```

---

## 5️⃣ Troubleshooting

### ❌ "emulator not found"
```bash
# Verify path
ls -la /opt/android-sdk/emulator/emulator

# If missing, reinstall:
sdkmanager --sdk_root=/opt/android-sdk "emulator"
```

### ❌ "adb: command not found"
```bash
# Add to PATH:
export PATH=/opt/android-sdk/platform-tools:$PATH
adb start-server
```

### ❌ "Emulator takes forever"
```bash
# Check if it's running
ps aux | grep emulator

# Check logs
tail -100 /tmp/emulator.log

# Use faster config
emulator -avd test_device \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -memory 4096 \
  -accel auto
```

### ❌ "Build fails - space issue"
```bash
# Check space
df -h

# If <5GB free, upgrade droplet or delete old builds
rm -rf app/build
```

### ❌ "Tests timeout"
```bash
# Increase timeout in gradle
./gradlew connectedAndroidTest --no-daemon --max-workers=1 -x lint
```

---

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Connect to droplet | `ssh root@YOUR_IP` |
| Upload project | `scp -r ./projecttestand root@YOUR_IP:/root/` |
| Start emulator | `emulator -avd test_device -no-window -no-audio -no-boot-anim &` |
| Check devices | `adb devices` |
| Run unit tests | `./gradlew testDebugUnitTest` |
| Run instrumentation tests | `./gradlew connectedAndroidTest` |
| View logs | `tail -f /tmp/emulator.log` |
| Stop emulator | `adb emu kill` |

---

## 💡 Tips

✅ **Keep emulator running**: Use `nohup` or `screen` to keep it alive  
✅ **SSH keys**: Setup SSH keys to avoid password every time  
✅ **Firewall**: DigitalOcean has built-in firewall - configure if needed  
✅ **Monitoring**: DigitalOcean has CPU/Memory graphs - check if stressed  
✅ **Cost**: Droplet runs 24/7 unless you delete it ($18/month)  

---

## 🚀 Next Steps

1. ✅ Create DigitalOcean account
2. ✅ Create Ubuntu 22.04 Droplet ($18/month)
3. ✅ Run automated setup script
4. ✅ Upload project
5. ✅ Run tests
6. ✅ View results

**Estimated time**: 15-20 minutes total ⏱️

---

## 📞 Support

If stuck, check:
- DigitalOcean console logs
- Emulator logs: `cat /tmp/emulator.log`
- This guide's troubleshooting section

Good luck! 🎉
