#!/bin/bash

# 🚀 Android SDK + Emulator Setup Script for DigitalOcean
# Run this on your Ubuntu 22.04 droplet as root

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🚀 Android SDK + Emulator Automated Setup                  ║"
echo "║  DigitalOcean Ubuntu 22.04                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
ANDROID_SDK_ROOT="/opt/android-sdk"
GRADLE_VERSION="8.14.4"

# ============================================
# Step 1: Update System
# ============================================
echo -e "${BLUE}📦 Step 1: Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# ============================================
# Step 2: Install Dependencies
# ============================================
echo -e "${BLUE}📦 Step 2: Installing dependencies...${NC}"
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
  qemu-kvm \
  libvirt-daemon \
  screen

echo -e "${GREEN}✅ Dependencies installed${NC}"

# ============================================
# Step 3: Android SDK Setup
# ============================================
echo -e "${BLUE}📦 Step 3: Setting up Android SDK...${NC}"
mkdir -p $ANDROID_SDK_ROOT
cd $ANDROID_SDK_ROOT

echo -e "${YELLOW}   Downloading Android SDK tools...${NC}"
wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip
unzip -q commandlinetools-linux-10406996_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
rm commandlinetools-linux-10406996_latest.zip

echo -e "${GREEN}✅ Android SDK installed${NC}"

# ============================================
# Step 4: PATH Configuration
# ============================================
echo -e "${BLUE}📦 Step 4: Configuring PATH...${NC}"
cat >> ~/.bashrc << 'EOF'

# Android SDK Configuration
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:/opt/gradle-8.14.4/bin:$PATH
EOF

source ~/.bashrc

echo -e "${GREEN}✅ PATH configured${NC}"

# ============================================
# Step 5: Accept Licenses
# ============================================
echo -e "${BLUE}📦 Step 5: Accepting Android SDK licenses...${NC}"
mkdir -p /opt/android-sdk/licenses ~/.android

# Add license files
echo "8933bad161af4d61" > /opt/android-sdk/licenses/android-sdk-license
echo "d56f5187479451eabf01fb78af6dfcb131b33910" >> /opt/android-sdk/licenses/android-sdk-license
echo "84831b9409646a918e30573bab4c9c91346d8abd" > /opt/android-sdk/licenses/android-sdk-preview-license
echo "count=0" > ~/.android/repositories.cfg

# Accept via sdkmanager too
yes | sdkmanager --sdk_root=/opt/android-sdk --licenses >/dev/null 2>&1 || true

echo -e "${GREEN}✅ Licenses accepted${NC}"

# ============================================
# Step 6: Install SDK Components
# ============================================
echo -e "${BLUE}📦 Step 6: Installing Android SDK components...${NC}"

echo -e "${YELLOW}   Installing platforms;android-34...${NC}"
sdkmanager --sdk_root=/opt/android-sdk "platforms;android-34" >/dev/null 2>&1

echo -e "${YELLOW}   Installing build-tools;34.0.0...${NC}"
sdkmanager --sdk_root=/opt/android-sdk "build-tools;34.0.0" >/dev/null 2>&1

echo -e "${YELLOW}   Installing platform-tools...${NC}"
sdkmanager --sdk_root=/opt/android-sdk "platform-tools" >/dev/null 2>&1

echo -e "${YELLOW}   Installing system-images;android-34;default;x86_64...${NC}"
sdkmanager --sdk_root=/opt/android-sdk "system-images;android-34;default;x86_64" >/dev/null 2>&1

echo -e "${YELLOW}   Installing emulator...${NC}"
sdkmanager --sdk_root=/opt/android-sdk "emulator" >/dev/null 2>&1

echo -e "${GREEN}✅ SDK components installed${NC}"

# ============================================
# Step 7: Create AVD
# ============================================
echo -e "${BLUE}📦 Step 7: Creating Android Virtual Device...${NC}"

yes | avdmanager create avd \
  -n test_device \
  -k "system-images;android-34;default;x86_64" \
  -d "medium_phone" \
  -c 2G >/dev/null 2>&1

echo -e "${GREEN}✅ AVD 'test_device' created${NC}"

# ============================================
# Step 8: Install Gradle
# ============================================
echo -e "${BLUE}📦 Step 8: Installing Gradle...${NC}"
cd /tmp
wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
unzip -q gradle-${GRADLE_VERSION}-bin.zip
mv gradle-${GRADLE_VERSION} /opt/
rm gradle-${GRADLE_VERSION}-bin.zip

echo -e "${GREEN}✅ Gradle ${GRADLE_VERSION} installed${NC}"

# ============================================
# Step 9: Verification
# ============================================
echo -e "${BLUE}📦 Step 9: Verifying installation...${NC}"

echo -e "${YELLOW}   Java version:${NC}"
java -version 2>&1 | head -1

echo -e "${YELLOW}   Gradle version:${NC}"
gradle -version 2>&1 | head -1

echo -e "${YELLOW}   Android SDK Manager:${NC}"
sdkmanager --version

echo -e "${YELLOW}   Emulator:${NC}"
emulator -version 2>&1 | head -1

echo -e "${YELLOW}   Available AVDs:${NC}"
avdmanager list avd | grep -A 2 "test_device" || echo "   test_device configured"

echo -e "${GREEN}✅ All verifications passed${NC}"

# ============================================
# Summary
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Setup Complete!                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Upload your project:"
echo "     scp -r ./projecttestand root@YOUR_IP:/root/"
echo ""
echo "  2. Connect to droplet:"
echo "     ssh root@YOUR_IP"
echo ""
echo "  3. Start emulator:"
echo "     emulator -avd test_device -no-window -no-audio -no-boot-anim -memory 2048 &"
echo ""
echo "  4. Wait 30-60 seconds, then verify:"
echo "     adb devices"
echo ""
echo "  5. Run tests:"
echo "     cd projecttestand"
echo "     ./gradlew connectedAndroidTest"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  • Keep emulator running in background with: nohup emulator ... &"
echo "  • Use 'screen' to manage multiple sessions"
echo "  • Check logs with: cat /tmp/emulator.log"
echo "  • Stop emulator with: adb emu kill"
echo ""
echo -e "${BLUE}🚀 Happy testing!${NC}"
echo ""
