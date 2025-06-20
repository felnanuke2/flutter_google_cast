# Android Build Troubleshooting

This document provides solutions for common Android build issues with the flutter_google_cast plugin.

## Common Build Issues

### 1. Java Heap Space Issues

**Error**: `Java heap space` during Jetifier transformation

**Solution**: The plugin now includes optimized Gradle settings. If you still encounter issues:

```properties
# In android/gradle.properties
org.gradle.jvmargs=-Xmx3072M -XX:MaxMetaspaceSize=512m
org.gradle.daemon=false
org.gradle.parallel=true
org.gradle.caching=true
```

### 2. Android x86 Target Deprecation

**Warning**: `Support for Android x86 targets will be removed in the next stable release`

**Solution**: The plugin now excludes x86 targets by default. To manually exclude:

```gradle
// In android/app/build.gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
}
```

Or build with specific targets:
```bash
flutter build apk --target-platform android-arm64,android-arm
```

### 3. AndroidX Migration Issues

**Warning**: Library contains references to both AndroidX and old support library

**Solution**: The plugin includes optimized Jetifier settings:

```properties
# In android/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
android.jetifier.blacklist=bcprov-jdk15on
```

### 4. Dependency Conflicts

**Error**: `Could not resolve all files for configuration`

**Solutions**:

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   flutter build apk
   ```

2. **Update Flutter and dependencies**:
   ```bash
   flutter upgrade
   flutter pub outdated
   flutter pub upgrade
   ```

3. **Force dependency resolution**:
   ```gradle
   // In android/app/build.gradle
   configurations.all {
       resolutionStrategy {
           force 'androidx.core:core:1.6.0'
           force 'androidx.appcompat:appcompat:1.4.0'
       }
   }
   ```

## CI/CD Considerations

For continuous integration:

1. **Use specific Flutter versions** in CI to ensure reproducible builds
2. **Increase memory allocation** for Gradle in CI environments
3. **Use build caching** to speed up builds
4. **Exclude x86 targets** to avoid deprecation warnings

Example CI configuration is provided in `.github/workflows/ci.yml`.

## Performance Optimizations

1. **Enable R8**: Already enabled by default
2. **Use parallel builds**: Configured in gradle.properties
3. **Enable build caching**: Configured in gradle.properties
4. **Optimize Jetifier**: Blacklisted problematic dependencies

## Debugging Build Issues

1. **Verbose output**:
   ```bash
   flutter build apk --debug -v
   ```

2. **Gradle logs**:
   ```bash
   cd android
   ./gradlew assembleDebug --stacktrace --debug
   ```

3. **Dependency tree**:
   ```bash
   cd android
   ./gradlew :app:dependencies
   ```

## Version Compatibility

- **Flutter**: 3.24.0 or higher
- **Android Gradle Plugin**: 8.3.0
- **Kotlin**: 1.9.10
- **Compile SDK**: 35
- **Min SDK**: 21
- **Target SDK**: 34

## Support

If you continue to experience build issues:

1. Check the [Flutter documentation](https://docs.flutter.dev/deployment/android)
2. Review the [Google Cast SDK documentation](https://developers.google.com/cast/docs/android_sender)
3. Create an issue with:
   - Flutter version (`flutter --version`)
   - Android build tools version
   - Complete build logs
   - Device/emulator specifications
