#!/bin/bash

# 🧪 Android Test Runner for DigitalOcean
# Run this on your DigitalOcean droplet in your project directory

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT=$(pwd)
EMULATOR_TIMEOUT=120  # 2 minutes to boot

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🧪 Android Test Runner (DigitalOcean)                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# Step 1: Start ADB
# ============================================
echo -e "${BLUE}1️⃣ Starting ADB daemon...${NC}"
adb start-server
sleep 2
echo -e "${GREEN}✅ ADB started${NC}"

# ============================================
# Step 2: Check for running emulator
# ============================================
echo -e "${BLUE}2️⃣ Checking for emulator...${NC}"

EMULATOR_RUNNING=$(adb devices | grep -c "emulator.*device" || echo "0")

if [ "$EMULATOR_RUNNING" -eq "0" ]; then
  echo -e "${YELLOW}   No emulator detected. Starting one...${NC}"
  
  nohup emulator -avd test_device \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -memory 2048 \
    -accel off > /tmp/emulator.log 2>&1 &
  
  EMULATOR_PID=$!
  echo "   Emulator PID: $EMULATOR_PID"
  
  echo -e "${YELLOW}   Waiting for emulator to boot (up to $EMULATOR_TIMEOUT seconds)...${NC}"
  
  COUNTER=0
  while [ $COUNTER -lt $EMULATOR_TIMEOUT ]; do
    if adb devices | grep -q "emulator.*device"; then
      echo -e "${GREEN}✅ Emulator connected!${NC}"
      break
    fi
    
    COUNTER=$((COUNTER + 2))
    if [ $((COUNTER % 10)) -eq 0 ]; then
      echo "   Waiting... ($COUNTER/$EMULATOR_TIMEOUT seconds)"
    fi
    sleep 2
  done
  
  if [ $COUNTER -ge $EMULATOR_TIMEOUT ]; then
    echo -e "${RED}❌ Emulator failed to boot${NC}"
    echo "   Check logs: cat /tmp/emulator.log"
    exit 1
  fi
else
  echo -e "${GREEN}✅ Emulator already running${NC}"
fi

# ============================================
# Step 3: Verify emulator fully booted
# ============================================
echo -e "${BLUE}3️⃣ Verifying system boot...${NC}"

BOOT_COUNTER=0
BOOT_TIMEOUT=30

while [ $BOOT_COUNTER -lt $BOOT_TIMEOUT ]; do
  BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null || echo "0")
  
  if [ "$BOOT_COMPLETED" = "1" ]; then
    echo -e "${GREEN}✅ System fully booted!${NC}"
    break
  fi
  
  BOOT_COUNTER=$((BOOT_COUNTER + 1))
  if [ $((BOOT_COUNTER % 5)) -eq 0 ]; then
    echo "   Boot status: $BOOT_COMPLETED ($BOOT_COUNTER/$BOOT_TIMEOUT seconds)"
  fi
  sleep 1
done

sleep 5

# ============================================
# Step 4: Show test options
# ============================================
echo ""
echo -e "${BLUE}4️⃣ Select test type:${NC}"
echo "   [1] Unit Tests (fast, no emulator needed)"
echo "   [2] Instrumentation Tests (requires emulator)"
echo "   [3] Both (unit + instrumentation)"
echo ""
read -p "   Enter choice [1-3]: " TEST_CHOICE

cd "$PROJECT_ROOT"

case $TEST_CHOICE in
  1)
    echo -e "${BLUE}Running Unit Tests...${NC}"
    ./gradlew testDebugUnitTest -x lint 2>&1 | tee /tmp/unit-test.log
    TEST_RESULT=${PIPESTATUS[0]}
    ;;
  2)
    echo -e "${BLUE}Running Instrumentation Tests...${NC}"
    ./gradlew connectedAndroidTest -x lint 2>&1 | tee /tmp/instrumentation-test.log
    TEST_RESULT=${PIPESTATUS[0]}
    ;;
  3)
    echo -e "${BLUE}Running All Tests...${NC}"
    ./gradlew testDebugUnitTest -x lint 2>&1 | tee /tmp/unit-test.log
    UNIT_RESULT=${PIPESTATUS[0]}
    
    echo ""
    ./gradlew connectedAndroidTest -x lint 2>&1 | tee /tmp/instrumentation-test.log
    INSTR_RESULT=${PIPESTATUS[0]}
    
    # Combine results
    if [ $UNIT_RESULT -eq 0 ] && [ $INSTR_RESULT -eq 0 ]; then
      TEST_RESULT=0
    else
      TEST_RESULT=1
    fi
    ;;
  *)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

# ============================================
# Step 5: Results
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $TEST_RESULT -eq 0 ]; then
  echo -e "║  ${GREEN}✅ All Tests PASSED!${NC}                                   ║"
else
  echo -e "║  ${RED}❌ Some Tests FAILED${NC}                                   ║"
fi
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# Step 6: Show results location
# ============================================
echo -e "${BLUE}📊 Test Results:${NC}"
echo ""

if [ -d "app/build/outputs" ]; then
  echo "   Unit Test Results:"
  find app/build/outputs -name "*test-results*" -type d 2>/dev/null | head -3
  
  echo ""
  echo "   Instrumentation Test Results:"
  find app/build/outputs -name "*androidTest-results*" -type d 2>/dev/null | head -3
fi

echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "   • View emulator logs: tail -f /tmp/emulator.log"
echo "   • Stop emulator: adb emu kill"
echo "   • Restart emulator: adb kill-server && emulator -avd test_device -no-window &"
echo "   • Check device: adb devices"
echo ""

exit $TEST_RESULT
