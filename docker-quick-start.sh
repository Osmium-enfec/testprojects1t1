#!/bin/bash

# Docker Build and Test Quick Start

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Android Instrumentation Testing via Docker - Quick Start   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check dependencies
echo -e "${YELLOW}✓ Checking dependencies...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "  Install from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    echo "  Install from: https://docs.docker.com/compose/install/"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
COMPOSE_VERSION=$(docker-compose --version)

echo -e "${GREEN}✓ $DOCKER_VERSION${NC}"
echo -e "${GREEN}✓ $COMPOSE_VERSION${NC}"
echo ""

# Build options
echo -e "${BLUE}Choose an option:${NC}"
echo ""
echo "1) Build Docker image"
echo "2) Run tests with docker-compose"
echo "3) Run tests with Docker CLI"
echo "4) Interactive shell in Docker"
echo "5) View test results"
echo "6) Clean up containers and images"
echo "7) Run both unit tests and instrumentation tests"
echo ""
read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo -e "${YELLOW}Building Docker image...${NC}"
        docker build -t android-instrumentation-tests .
        echo -e "${GREEN}✓ Build complete${NC}"
        ;;
    2)
        echo -e "${YELLOW}Running tests with docker-compose...${NC}"
        docker-compose up --build
        ;;
    3)
        echo -e "${YELLOW}Running tests with Docker CLI...${NC}"
        docker run --rm \
          -v $(pwd)/build:/app/build \
          -v $(pwd)/app:/app/app \
          --privileged \
          android-instrumentation-tests
        ;;
    4)
        echo -e "${YELLOW}Starting interactive shell...${NC}"
        docker run -it --rm \
          -v $(pwd):/app \
          --privileged \
          android-instrumentation-tests \
          /bin/bash
        ;;
    5)
        echo -e "${YELLOW}Test Results:${NC}"
        if [ -f "app/build/outputs/androidTest-results/connected/index.html" ]; then
            echo "✓ HTML Report: app/build/outputs/androidTest-results/connected/index.html"
        fi
        if [ -f "app/build/test-results/androidTest/index.html" ]; then
            echo "✓ JUnit Report: app/build/test-results/androidTest/index.html"
        fi
        ls -lah app/build/test-results/ 2>/dev/null || echo "No test results yet"
        ;;
    6)
        echo -e "${YELLOW}Cleaning up...${NC}"
        docker-compose down --remove-orphans || true
        docker rmi android-instrumentation-tests || true
        echo -e "${GREEN}✓ Cleanup complete${NC}"
        ;;
    7)
        echo -e "${YELLOW}Running unit tests (headless)...${NC}"
        ./run_headless_tests.sh
        echo ""
        echo -e "${YELLOW}Building instrumentation test image...${NC}"
        docker build -t android-instrumentation-tests .
        echo ""
        echo -e "${YELLOW}Running instrumentation tests...${NC}"
        docker-compose up
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
