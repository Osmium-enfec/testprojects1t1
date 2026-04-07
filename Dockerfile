FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Install only what's needed for Roboelectric unit tests (minimal footprint)
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download Gradle (minimal install - no Android SDK needed for Roboelectric)
RUN mkdir -p /opt/gradle && \
    wget -q https://services.gradle.org/distributions/gradle-8.5-bin.zip -O /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    rm /tmp/gradle.zip && \
    ln -s /opt/gradle-8.5/bin/gradle /usr/local/bin/gradle

# Download minimal Android SDK cmdline-tools (just for license acceptance, not used for Roboelectric)
RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp && \
    mv /tmp/cmdline-tools/* /opt/android-sdk/cmdline-tools/ && \
    rm /tmp/cmdline-tools.zip

# Accept licenses (required for build, even though Roboelectric doesn't use SDK)
RUN mkdir -p /opt/android-sdk/licenses && \
    echo "8933bad161af4d61" > /opt/android-sdk/licenses/android-sdk-license && \
    echo "d56f5187479451eabf01fb78af6dfcb131b33910" >> /opt/android-sdk/licenses/android-sdk-license

WORKDIR /app

# Copy project
COPY . /app

# Create dummy Android SDK path (Roboelectric doesn't actually need it)
RUN mkdir -p /opt/android-sdk

# Make scripts executable (if they exist)
RUN chmod +x /app/gradlew 2>/dev/null || true && \
    chmod +x /app/run-tests-do.sh 2>/dev/null || true

# Default command: Run Roboelectric unit tests
CMD ["./gradlew", "testDebugUnitTest"]
