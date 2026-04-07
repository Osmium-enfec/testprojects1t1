#!/bin/bash

# Docker Headless Instrumentation Testing Script

# Enable error reporting but allow some failures
set +e

# Set up environment
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:/opt/gradle-8.14.4/bin:$PATH

echo "════════════════════════════════════════════════"
echo "🐳 Docker Headless Android Instrumentation Test"
echo "════════════════════════════════════════════════"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}1️⃣ Verifying Android SDK tools...${NC}"
if [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
    echo -e "${GREEN}✅ ADB found${NC}"
else
    echo -e "${RED}❌ ADB not found!${NC}"
    exit 1
fi

if [ -f "$ANDROID_HOME/emulator/emulator" ]; then
    echo -e "${GREEN}✅ Emulator found${NC}"
else
    echo -e "${RED}❌ Emulator not found!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}2️⃣ Checking AVD configuration...${NC}"
if [ -d "$HOME/.android/avd/test_device.avd" ]; then
    echo -e "${GREEN}✅ AVD found${NC}"
    cat "$HOME/.android/avd/test_device.avd/config.ini"
else
    echo -e "${RED}❌ AVD not configured!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}3️⃣ Starting ADB server...${NC}"
adb start-server
sleep 2

# Check ADB is running
if ! adb version &>/dev/null; then
    echo -e "${RED}❌ ADB failed to start${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ADB started${NC}"

# Start emulator in headless mode with increased timeout
echo -e "${YELLOW}4️⃣ Starting Android emulator (headless)...${NC}"
emulator -avd test_device \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -memory 2048 \
    -accel off \
    -verbose \
    -qemu -m 2048 &
EMULATOR_PID=$!
echo "Emulator PID: $EMULATOR_PID"
sleep 5

# Wait for emulator to boot
echo -e "${YELLOW}5️⃣ Waiting for emulator to boot (up to 240 seconds)...${NC}"
BOOT_TIMEOUT=240
BOOT_COUNTER=0

while [ $BOOT_COUNTER -lt $BOOT_TIMEOUT ]; do
    DEVICES=$(adb devices 2>/dev/null)
    if echo "$DEVICES" | grep -q "emulator.*device"; then
        echo -e "${GREEN}✅ Emulator connected!${NC}"
        break
    fi
    
    BOOT_COUNTER=$((BOOT_COUNTER + 2))
    if [ $((BOOT_COUNTER % 20)) -eq 0 ]; then
        echo "   Waiting... ($BOOT_COUNTER/$BOOT_TIMEOUT seconds)"
        adb devices 2>/dev/null || true
    fi
    sleep 2
done

if [ $BOOT_COUNTER -ge $BOOT_TIMEOUT ]; then
    echo -e "${RED}❌ Emulator failed to boot after $BOOT_TIMEOUT seconds${NC}"
    adb devices
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

# Wait for system to fully boot
echo -e "${YELLOW}6️⃣ Waiting for system to fully boot...${NC}"
SYSTEM_BOOT_TIMEOUT=60
SYSTEM_BOOT_COUNTER=0

while [ $SYSTEM_BOOT_COUNTER -lt $SYSTEM_BOOT_TIMEOUT ]; do
    BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null || echo "0")
    if [ "$BOOT_COMPLETED" = "1" ]; then
        echo -e "${GREEN}✅ System fully booted!${NC}"
        break
    fi
    
    SYSTEM_BOOT_COUNTER=$((SYSTEM_BOOT_COUNTER + 1))
    if [ $((SYSTEM_BOOT_COUNTER % 10)) -eq 0 ]; then
        echo "   Boot property: $BOOT_COMPLETED ($SYSTEM_BOOT_COUNTER/$SYSTEM_BOOT_TIMEOUT seconds)"
    fi
    sleep 1
done

sleep 5

# Run instrumentation tests
echo -e "${YELLOW}7️⃣ Building and running instrumentation tests...${NC}"
cd /app

# Build and run tests
gradle connectedAndroidTest 2>&1 | tee /tmp/test-output.log
TEST_RESULT=${PIPESTATUS[0]}

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Tests PASSED${NC}"
else
    echo -e "${RED}❌ Tests FAILED (Exit code: $TEST_RESULT)${NC}"
    echo -e "${YELLOW}Last 100 lines of output:${NC}"
    tail -100 /tmp/test-output.log
fi

# Generate test report
echo -e "${YELLOW}8️⃣ Test results:${NC}"
if [ -d "app/build/outputs/androidTest-results/connected" ]; then
    echo -e "${GREEN}📊 Found test results:${NC}"
    find app/build/outputs/androidTest-results/connected -type f | head -10
elif [ -d "app/build/outputs" ]; then
    echo -e "${YELLOW}Available build outputs:${NC}"
    find app/build/outputs -type d | head -10
fi

# Stop emulator gracefully
echo -e "${YELLOW}9️⃣ Stopping emulator...${NC}"
adb emu kill 2>/dev/null || kill $EMULATOR_PID 2>/dev/null || true
sleep 2

# Summary
echo ""
echo "════════════════════════════════════════════════"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}🎉 All Instrumentation Tests PASSED!${NC}"
else
    echo -e "${RED}💥 Some Tests FAILED${NC}"
fi
echo "════════════════════════════════════════════════"

exit $TEST_RESULT
