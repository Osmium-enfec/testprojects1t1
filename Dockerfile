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


WORKDIR /app

# Copy project
COPY . /app

# Make scripts executable (if they exist)
RUN chmod +x /app/gradlew 2>/dev/null || true && \
    chmod +x /app/run-tests-do.sh 2>/dev/null || true

# Default command: Run Roboelectric unit tests
CMD ["./gradlew", "testDebugUnitTest", "--info"]
