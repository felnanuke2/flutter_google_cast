#!/bin/bash

# Android Build Fix Script for flutter_google_cast
# This script fixes common Android build issues

set -e

echo "🔧 Flutter Google Cast - Android Build Fix Script"
echo "================================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the flutter_google_cast root directory"
    exit 1
fi

echo "🧹 Cleaning previous builds..."
flutter clean
cd example && flutter clean && cd ..

echo "📦 Getting dependencies..."
flutter pub get
cd example && flutter pub get && cd ..

echo "⚙️  Configuring Android build settings..."

# Configure main plugin gradle.properties
cat > android/gradle.properties << EOF
org.gradle.jvmargs=-Xmx3072M -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true
# Optimize Jetifier for better performance
android.jetifier.blacklist=bcprov-jdk15on
# Gradle performance optimizations
org.gradle.parallel=true
org.gradle.caching=true
EOF

# Configure example gradle.properties
cat > example/android/gradle.properties << EOF
org.gradle.jvmargs=-Xmx3072M -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true
# Optimize Jetifier for better performance
android.jetifier.blacklist=bcprov-jdk15on
# Gradle performance optimizations
org.gradle.parallel=true
org.gradle.caching=true
EOF

echo "🛠️  Updating build.gradle for x86 exclusion..."

# Check if ABI filters are already present
if ! grep -q "abiFilters" example/android/app/build.gradle; then
    # Find the defaultConfig section and add ABI filters
    sed -i.bak '/versionName flutterVersionName/a\
        \
        // Exclude x86 architectures as they are deprecated\
        ndk {\
            abiFilters '\''arm64-v8a'\'', '\''armeabi-v7a'\''\
        }' example/android/app/build.gradle
    
    echo "✅ Added ABI filters to exclude x86 targets"
else
    echo "✅ ABI filters already configured"
fi

echo "🧹 Cleaning Gradle caches..."
cd example/android
./gradlew clean --quiet
cd ../..

echo "📋 Checking for outdated dependencies..."
flutter pub outdated || true

echo ""
echo "✅ Android build configuration completed!"
echo ""
echo "📝 Next steps:"
echo "1. Try building with: flutter build apk --target-platform android-arm64,android-arm"
echo "2. For development: flutter run (will use ARM64 by default)"
echo "3. Check ANDROID_BUILD_TROUBLESHOOTING.md for more solutions"
echo ""
echo "🎯 Build commands:"
echo "   Debug APK (ARM only): flutter build apk --debug --target-platform android-arm64,android-arm"
echo "   Release APK (ARM only): flutter build apk --release --target-platform android-arm64,android-arm"
echo "   Development: cd example && flutter run"
echo ""
