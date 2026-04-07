# Docker Headless Instrumentation Testing Guide

## Overview

Run Android instrumentation tests in a headless Docker container - perfect for CI/CD pipelines and distributed testing environments.

## What's Included

- ✅ Ubuntu 22.04 base image
- ✅ OpenJDK 21
- ✅ Gradle 8.14.4
- ✅ Android SDK 34
- ✅ Android Emulator (x86_64)
- ✅ Pre-configured AVD (test_device)
- ✅ ADB daemon
- ✅ Automated test execution

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and run tests
docker-compose up --build

# View logs
docker-compose logs -f

# Clean up
docker-compose down
```

### Option 2: Using Docker CLI

```bash
# Build image
docker build -t android-instrumentation-tests .

# Run container
docker run --rm \
  -v $(pwd)/build:/app/build \
  -v $(pwd)/app:/app/app \
  --privileged \
  android-instrumentation-tests
```

### Option 3: Headless Mode (No Interactive Terminal)

```bash
docker-compose up --build --remove-orphans --exit-code-from android-tests
```

## Environment Setup

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+ (for docker-compose.yml)
- 4GB RAM available
- 20GB disk space

### macOS Setup

```bash
# Enable Docker Desktop
# Increase memory: Docker > Preferences > Resources > Memory = 4GB+

# Optional: Enable KVM (if available)
# Note: KVM not available on macOS, but Docker Desktop provides HyperKit
```

### Linux Setup

```bash
# Enable KVM for acceleration
sudo apt-get install qemu-kvm libvirt-daemon-system

# Add user to docker group
sudo usermod -aG docker $USER

# Restart Docker daemon
sudo systemctl restart docker
```

### Windows Setup

```powershell
# Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart computer
Restart-Computer

# In Docker Desktop, enable WSL 2 backend
```

## Building the Docker Image

### Build with Default Settings

```bash
docker build -t android-instrumentation-tests .
```

### Build with Custom Tags

```bash
docker build -t myregistry/android-tests:latest .
docker build -t myregistry/android-tests:v1.0 .
```

### Build and Push to Registry

```bash
docker build -t myregistry/android-tests:latest .
docker push myregistry/android-tests:latest
```

## Running Tests

### Basic Execution

```bash
# Run with docker-compose
docker-compose up

# Run with Docker CLI
docker run --rm \
  -v $(pwd)/build:/app/build \
  android-instrumentation-tests
```

### Running Specific Tests

```bash
# Modify docker-compose.yml to run specific test
# Then override command:
docker-compose run android-tests \
  gradle connectedAndroidTest -PtestFilter=*HelloWorldTest
```

### Interactive Mode (Debugging)

```bash
# Start container with bash shell
docker run -it \
  --rm \
  -v $(pwd):/app \
  android-instrumentation-tests \
  /bin/bash

# Inside container:
adb devices
gradle connectedAndroidTest
```

### With Volume Mounts

```bash
docker run --rm \
  -v $(pwd)/app:/app/app \
  -v $(pwd)/build:/app/build \
  -v $(pwd)/app/build/reports:/reports \
  android-instrumentation-tests
```

## Test Results

### Access Test Reports

After running tests, check:

```bash
# Test results XML
./app/build/outputs/androidTest-results/connected/index.html

# Logcat output
./app/build/outputs/connected_android_test_additional_output/

# JUnit reports
./app/build/test-results/
```

### Example Test Output

```
════════════════════════════════════════════════
🐳 Docker Headless Android Instrumentation Test
════════════════════════════════════════════════

1️⃣ Starting ADB daemon...
2️⃣ Starting Android emulator (headless)...
3️⃣ Waiting for emulator to boot...
   ✅ Emulator connected!
4️⃣ Waiting for system to boot...
5️⃣ Building and running instrumentation tests...
   > Task :app:connectedAndroidTest
   
   com.example.helloworldapp.HelloWorldTest:
   - testHelloWorldTextDisplayed PASSED
   
   BUILD SUCCESSFUL
   
6️⃣ Generating test report...
7️⃣ Stopping emulator...

════════════════════════════════════════════════
🎉 All Instrumentation Tests PASSED!
════════════════════════════════════════════════
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Docker Instrumentation Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker Image
        run: docker build -t android-tests .
      
      - name: Run Instrumentation Tests
        run: |
          docker run --rm \
            -v $(pwd)/build:/app/build \
            android-tests
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: app/build/outputs/androidTest-results/
```

### GitLab CI

```yaml
stages:
  - test

docker_instrumentation_tests:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t android-tests .
    - docker run --rm -v $(pwd)/build:/app/build android-tests
  artifacts:
    paths:
      - app/build/outputs/androidTest-results/
    reports:
      junit: app/build/outputs/androidTest-results/junit.xml
```

### Jenkins

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t android-tests .'
            }
        }
        
        stage('Run Instrumentation Tests') {
            steps {
                sh '''
                    docker run --rm \\
                      -v $(pwd)/build:/app/build \\
                      android-tests
                '''
            }
        }
        
        stage('Archive Results') {
            steps {
                junit 'app/build/outputs/androidTest-results/**/*.xml'
            }
        }
    }
}
```

## Advanced Configuration

### Custom Emulator Settings

Edit `docker-run-tests.sh` to modify emulator parameters:

```bash
emulator -avd test_device \
    -no-window \
    -no-audio \
    -memory 4096 \        # Increase RAM
    -cores 4 \            # Use 4 CPU cores
    -gpu angle_indirect   # Different GPU mode
```

### Multiple Test Devices

Create additional AVDs:

```dockerfile
# Add to Dockerfile
RUN ${ANDROID_HOME}/cmdline-tools/bin/avdmanager create avd \
    -n tablet_device \
    -k "system-images;android-34;default;x86_64" \
    -d "Nexus 7" \
    --force
```

### Custom Test Filters

```bash
# Run specific test class
docker-compose run android-tests \
  gradle connectedAndroidTest \
  -PtestFilter=com.example.helloworldapp.HelloWorldTest

# Run specific test method
docker-compose run android-tests \
  gradle connectedAndroidTest \
  -PtestFilter=com.example.helloworldapp.HelloWorldTest#testHelloWorldTextDisplayed
```

## Troubleshooting

### Issue: Emulator fails to start

```bash
# Check logs
docker logs <container_id>

# Enable KVM on Linux
kvm-ok

# Disable hardware acceleration
# Edit docker-run-tests.sh: remove -accel on
```

### Issue: Out of Memory

```bash
# Increase Docker memory
docker-compose down
# Increase memory in Docker Desktop or docker run -m 4g
```

### Issue: Tests timeout

```bash
# Increase boot wait time
# Edit docker-run-tests.sh: change sleep 10 to sleep 30
```

### Issue: ADB not connecting

```bash
# Inside container
adb kill-server
adb start-server
adb devices
```

## Performance Optimization

### Build Cache

```bash
# Use BuildKit for faster builds
DOCKER_BUILDKIT=1 docker build -t android-tests .
```

### Layer Caching

```dockerfile
# Place frequently changing content at end of Dockerfile
# Place stable content (SDK) earlier
```

### Multi-stage Build

```dockerfile
# Create smaller final image by using multi-stage
FROM ubuntu:22.04 as base
# ... setup steps ...

FROM base as final
COPY --from=base /opt/android-sdk /opt/android-sdk
```

## Security Considerations

### Don't Use in Production

This setup is for development/testing. For production:
- Use proper image signing
- Implement image vulnerability scanning
- Use private registries
- Implement RBAC

### Best Practices

- Keep base image updated
- Minimize privileges
- Use read-only volumes where possible
- Don't hardcode sensitive data

## Performance Metrics

- **Image Size**: ~4GB
- **Build Time**: 10-15 minutes (first time)
- **Test Execution**: 2-5 minutes
- **Total Pipeline Time**: 15-20 minutes

## Files Reference

- `Dockerfile` - Docker image definition
- `docker-compose.yml` - Docker Compose configuration
- `docker-run-tests.sh` - Test execution script
- `run_headless_tests.sh` - Headless unit test script

## Next Steps

1. Build Docker image: `docker-compose build`
2. Run tests: `docker-compose up`
3. Check results: `./app/build/outputs/androidTest-results/`
4. Integrate with CI/CD: See examples above

## Support

For issues:
- Check Docker logs: `docker logs <container>`
- Check emulator: `adb devices`
- Run tests locally first to isolate issues

---

**Status**: ✅ Ready for CI/CD  
**Last Updated**: April 7, 2026  
**Version**: 1.0
