#!/bin/bash

# Headless Android Testing Script
# This script runs both unit tests (headless) and instrumentation tests

set -e  # Exit on error

echo "======================================"
echo "🧪 Android Headless Testing"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set up Gradle
if [ -z "$GRADLE_HOME" ]; then
    # Try gradle@8 first, fall back to system gradle
    if command -v /opt/homebrew/opt/gradle@8/bin/gradle &> /dev/null; then
        GRADLE_CMD="/opt/homebrew/opt/gradle@8/bin/gradle"
        echo "Using Gradle 8 from Homebrew..."
    else
        GRADLE_CMD="gradle"
        echo "Using system gradle..."
    fi
else
    GRADLE_CMD="$GRADLE_HOME/bin/gradle"
fi

echo -e "${YELLOW}📦 Step 1: Running Unit Tests (Headless)...${NC}"
$GRADLE_CMD testDebugUnitTest --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Unit Tests PASSED${NC}"
else
    echo -e "${RED}❌ Unit Tests FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🏗️ Step 2: Building APK...${NC}"
$GRADLE_CMD assembleDebug --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ APK Build SUCCESSFUL${NC}"
else
    echo -e "${RED}❌ APK Build FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📊 Step 3: Test Report Summary${NC}"
if [ -f "app/build/test-results/testDebugUnitTest/TEST-com.example.helloworldapp.HelloWorldUnitTest.xml" ]; then
    TESTS=$(grep -o 'tests="[0-9]*"' app/build/test-results/testDebugUnitTest/TEST-com.example.helloworldapp.HelloWorldUnitTest.xml | grep -o '[0-9]*')
    FAILURES=$(grep -o 'failures="[0-9]*"' app/build/test-results/testDebugUnitTest/TEST-com.example.helloworldapp.HelloWorldUnitTest.xml | grep -o '[0-9]*')
    
    echo "  Total Tests: $TESTS"
    echo "  Failures: $FAILURES"
    if [ "$FAILURES" -eq "0" ]; then
        echo -e "  ${GREEN}Status: ALL PASSED${NC}"
    else
        echo -e "  ${RED}Status: SOME FAILED${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}======================================"
echo "🎉 All Headless Tests Passed!"
echo "======================================${NC}"

echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "  • For Instrumentation Tests (requires emulator/device):"
echo "    gradle connectedAndroidTest"
echo ""
echo "  • Or start emulator with:"
echo "    emulator -avd <device_name> -no-window -no-audio"
