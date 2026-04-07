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
