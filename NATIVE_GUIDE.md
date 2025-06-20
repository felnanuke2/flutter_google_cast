# Flutter Chrome Cast - Native Development Guide

## 🎯 Overview

This guide covers the native implementation details for the Flutter Chrome Cast plugin. The plugin supports both **iOS (Swift)** and **Android (Kotlin)** platforms, providing a complete Google Cast SDK integration.

## 📚 Documentation Structure

### Platform-Specific Guides

- **[iOS Native Guide](NATIVE_IOS_GUIDE.md)** - Swift implementation details
- **[Android Native Guide](NATIVE_ANDROID_GUIDE.md)** - Kotlin implementation details

### Dart/Flutter Guides

- **[Import Guide](IMPORT_GUIDE.md)** - Flutter package import optimization
- **[Main README](README.md)** - General plugin usage and setup

## 🏗️ Architecture Overview

```
Flutter Chrome Cast Plugin
├── Flutter/Dart Layer
│   ├── Platform Interface
│   ├── Method Channels
│   └── Widget Components
├── iOS Native Layer (Swift)
│   ├── Google Cast SDK iOS
│   ├── Method Channel Handlers
│   └── Cast Context Management
└── Android Native Layer (Kotlin)
    ├── Google Cast SDK Android
    ├── Method Channel Handlers
    └── Cast Context Management
```

## 🔄 Cross-Platform Communication

### Method Channels

The plugin uses Flutter's method channels for bidirectional communication:

| Channel Name | Purpose | iOS Handler | Android Handler |
|--------------|---------|-------------|-----------------|
| `google_cast.context` | Cast context management | `SwiftGoogleCastPlugin` | `CastContextMethodChannel` |
| `google_cast.discovery_manager` | Device discovery | `DiscoveryManagerMethodChannel` | `DiscoveryManagerMethodChannel` |
| `google_cast.session_manager` | Session management | `SessionManagerMethodChannel` | `SessionManagerMethodChannel` |
| `google_cast.media_client` | Media control | `RemoteMediaClientMethodChannel` | `RemoteMediaClientMethodChannel` |

### Data Flow

```
Flutter App
    ↕ (Method Channels)
Platform Interface
    ↕ (Method Channels)
Native Implementation
    ↕ (SDK Calls)
Google Cast SDK
    ↕ (Network)
Cast Receiver Device
```

## 🚀 Quick Start for Contributors

### 1. Setting Up Development Environment

**For iOS Development:**
```bash
# Install dependencies
cd ios/
pod install

# Open in Xcode
open Runner.xcworkspace
```

**For Android Development:**
```bash
# Build project
cd android/
./gradlew build

# Open in Android Studio
studio .
```

### 2. Understanding the Codebase

1. **Start with platform interfaces** - Understand the Flutter contracts
2. **Study method channels** - See how Dart communicates with native
3. **Explore native implementations** - Dive into Swift/Kotlin code
4. **Review extensions** - Understand data transformation helpers

### 3. Common Development Tasks

#### Adding a New Cast SDK Feature

1. **Define Dart Interface**:
```dart
// In appropriate platform interface file
Future<void> newFeature(Map<String, dynamic> params);
```

2. **Implement iOS (Swift)**:
```swift
// Add to appropriate method channel
case "newFeature":
    handleNewFeature(call.arguments, result: result)
```

3. **Implement Android (Kotlin)**:
```kotlin
// Add to appropriate method channel
"newFeature" -> handleNewFeature(call.arguments, result)
```

4. **Add Documentation**: Update both native guides

## 🔧 Development Guidelines

### Code Quality Standards

- **Swift**: Follow Apple's Swift API Design Guidelines
- **Kotlin**: Follow Kotlin coding conventions
- **Documentation**: Comprehensive comments for all public APIs
- **Error Handling**: Graceful handling of all failure cases
- **Testing**: Unit tests for core functionality

### Cross-Platform Consistency

Ensure both platforms provide:
- **Identical API surface** - Same method names and parameters
- **Consistent error codes** - Use standardized error reporting
- **Similar behavior** - Account for platform differences appropriately
- **Equivalent performance** - Optimize for each platform's strengths

### Version Compatibility

- **iOS**: Support iOS 10.0+
- **Android**: Support API level 21+ (Android 5.0)
- **Google Cast SDK**: Stay current with latest stable versions
- **Flutter**: Support current stable and beta channels

## 🐛 Debugging Strategies

### Cross-Platform Debugging

1. **Enable Cast SDK Logging**:
   - iOS: Set `kDebugLoggingEnabled = true`
   - Android: Enable debug logging in Cast context

2. **Method Channel Debugging**:
   - Log all method calls and results
   - Verify data serialization/deserialization
   - Check for platform-specific differences

3. **Device Testing**:
   - Test on multiple Cast devices
   - Verify network configurations
   - Test various media formats

### Common Cross-Platform Issues

| Issue | iOS Solution | Android Solution |
|-------|-------------|------------------|
| Discovery timeout | Check network permissions | Verify WiFi state |
| Session connection fails | Validate app ID | Check Cast options provider |
| Media loading errors | Verify URL accessibility | Check network security config |
| UI thread blocking | Use async operations | Handle on background thread |

## 📊 Performance Considerations

### iOS Optimizations

- Use weak references to prevent retain cycles
- Implement proper memory management
- Optimize for different device capabilities
- Handle background/foreground transitions

### Android Optimizations

- Implement proper lifecycle management
- Use appropriate threading for Cast operations
- Optimize for different screen sizes
- Handle configuration changes gracefully

## 🧪 Testing Strategy

### Platform-Specific Testing

**iOS Testing:**
- XCTest for unit tests
- UI tests for widget functionality
- Memory leak detection with Instruments
- Device compatibility testing

**Android Testing:**
- JUnit for unit tests
- Espresso for UI tests
- Memory profiling with Android Studio
- Multiple API level testing

### Integration Testing

- Flutter integration tests across platforms
- Cast device compatibility testing
- Network condition testing
- Multi-session scenario testing

## 📦 Release Process

### Pre-Release Checklist

- [ ] Both platforms build successfully
- [ ] All tests pass on both platforms
- [ ] Documentation is updated
- [ ] Example app works on both platforms
- [ ] Performance benchmarks meet standards
- [ ] Cast SDK versions are current

### Platform-Specific Release Notes

When releasing, include:
- Google Cast SDK version compatibility
- Minimum platform version requirements
- Platform-specific feature additions
- Known platform limitations

## 🤝 Contributing

### Getting Started

1. **Choose Your Platform**: Start with iOS or Android (or both!)
2. **Read Platform Guide**: Follow the detailed platform-specific guide
3. **Set Up Environment**: Install required tools and dependencies
4. **Pick an Issue**: Look for "good first issue" or "platform-specific" labels
5. **Submit PR**: Include tests and documentation updates

### Code Review Process

1. **Automated Checks**: CI/CD runs platform-specific builds and tests
2. **Platform Review**: Platform experts review native code changes
3. **Cross-Platform Review**: Ensure API consistency across platforms
4. **Integration Testing**: Verify changes work in real Cast scenarios

## 📞 Support

### Getting Help

- **Platform Issues**: File issues with [iOS] or [Android] labels
- **Cross-Platform Issues**: General issue without platform label
- **Documentation**: Issues with [documentation] label
- **Discussion**: Use GitHub Discussions for questions

### Expert Contacts

- **iOS/Swift Questions**: Tag @ios-maintainer
- **Android/Kotlin Questions**: Tag @android-maintainer
- **Cross-Platform Architecture**: Tag @plugin-architect

---

**Happy Coding!** 🎉

Remember: Great native implementations make for an amazing Flutter plugin experience!
