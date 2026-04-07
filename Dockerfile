FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=$PATH:/opt/gradle-8.14.4/bin

# Install ALL required dependencies (including missing ones)
RUN apt-get update && apt-get install -y \
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
    libnss3 \
    libasound2 \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android SDK Command Line Tools
RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp && \
    mv /tmp/cmdline-tools/* /opt/android-sdk/cmdline-tools/ && \
    rm /tmp/cmdline-tools.zip

# Set PATH for SDK tools early
ENV PATH=/opt/android-sdk/cmdline-tools/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:$PATH

# Download and install Gradle
RUN wget -q https://services.gradle.org/distributions/gradle-8.14.4-bin.zip -O /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    rm /tmp/gradle.zip

# Pre-create license directories and PROPERLY accept licenses
RUN mkdir -p /opt/android-sdk/licenses ~/.android && \
    echo "8933bad161af4d61" > /opt/android-sdk/licenses/android-sdk-license && \
    echo "d56f5187479451eabf01fb78af6dfcb131b33910" >> /opt/android-sdk/licenses/android-sdk-license && \
    echo "84831b9409646a918e30573bab4c9c91346d8abd" > /opt/android-sdk/licenses/android-sdk-preview-license && \
    echo "count=0" > ~/.android/repositories.cfg

# Accept licenses with yes command (proper way)
RUN yes | sdkmanager --sdk_root=/opt/android-sdk --licenses

# Install SDK components - one at a time with error output
RUN echo "📦 Installing platforms;android-34..." && \
    sdkmanager --sdk_root=/opt/android-sdk "platforms;android-34" || echo "⚠️ Warning: platforms may not install, continuing..."

RUN echo "📦 Installing build-tools;34.0.0..." && \
    sdkmanager --sdk_root=/opt/android-sdk "build-tools;34.0.0" || echo "⚠️ Warning: build-tools may not install, continuing..."

RUN echo "📦 Installing platform-tools..." && \
    sdkmanager --sdk_root=/opt/android-sdk "platform-tools" || echo "⚠️ Warning: platform-tools may not install, continuing..."

RUN echo "📦 Installing system-images;android-34;default;x86_64..." && \
    sdkmanager --sdk_root=/opt/android-sdk "system-images;android-34;default;x86_64" || echo "⚠️ Warning: system-images may not install, continuing..."

RUN echo "📦 Installing emulator..." && \
    sdkmanager --sdk_root=/opt/android-sdk "emulator" || echo "⚠️ Warning: emulator may not install, continuing..."

# Create AVD using PROPER avdmanager command (not manual file writing)
RUN echo "📱 Creating AVD test_device..." && \
    yes | avdmanager create avd \
    -n test_device \
    -k "system-images;android-34;default;x86_64" \
    -d "medium_phone" \
    -c 2G || echo "⚠️ Warning: AVD creation issues, will try to fix..."

# List what was actually installed
RUN echo "=== SDK Contents ===" && \
    ls -la /opt/android-sdk/ && \
    echo "=== AVD Contents ===" && \
    ls -la ~/.android/avd/ 2>/dev/null || echo "AVD directory empty"

# Copy project into container
WORKDIR /app
COPY . /app

# Make test scripts executable
RUN chmod +x /app/docker-run-tests.sh /app/run_headless_tests.sh

# Expose ADB port
EXPOSE 5037

# Set the default command
CMD ["/app/docker-run-tests.sh"]
