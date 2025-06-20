# Flutter Chrome Cast - iOS Native Implementation Guide

## 🍎 iOS Architecture Overview

The iOS implementation of the Flutter Chrome Cast plugin is built using **Swift** and integrates with **Google Cast SDK for iOS**. The architecture follows the Flutter plugin pattern with method channels for communication between Dart and native code.

## 📁 File Structure

```
ios/
├── Classes/
│   ├── SwiftGoogleCastPlugin.swift          # Main plugin entry point
│   ├── GoogleCastPlugin.h                   # Objective-C header
│   ├── GoogleCastPlugin.m                   # Objective-C implementation
│   ├── DiscoveryManagerMethodChannel.swift  # Device discovery
│   ├── RemoteMediaClienteMethodChannel.swift # Media control
│   ├── SessionManagerMethodChannel.swift    # Session management
│   ├── SessionMethodChannel.swift           # Individual session
│   └── Extensions/                          # Swift extensions
├── Assets/                                  # Plugin assets
└── flutter_chrome_cast.podspec            # CocoaPods specification
```

## 🚀 Core Components

### 1. SwiftGoogleCastPlugin (Main Plugin)

**File**: `SwiftGoogleCastPlugin.swift`

The main plugin class that inherits from `GCKCastContext` and implements multiple protocols:
- `FlutterPlugin`: Flutter plugin interface
- `GCKLoggerDelegate`: Google Cast logging
- `UIApplicationDelegate`: iOS app lifecycle

```swift
public class SwiftGoogleCastPlugin: GCKCastContext, GCKLoggerDelegate, FlutterPlugin, UIApplicationDelegate
```

**Key Properties**:
- `sessionManager`: Overrides GCK session manager
- `discoveryManager`: Overrides GCK discovery manager
- `channel`: Flutter method channel for communication

**Main Methods**:
- `register(with:)`: Registers the plugin and all method channels
- `handle(_:result:)`: Handles method calls from Flutter
- `setSharedInstanceWithOption`: Initializes Google Cast context

### 2. Method Channels

Each major feature has its own method channel for organized communication:

#### DiscoveryManagerMethodChannel
**Purpose**: Handles device discovery functionality
**Channel Name**: `google_cast.discovery_manager`

#### SessionManagerMethodChannel  
**Purpose**: Manages cast sessions (start, end, status)
**Channel Name**: `google_cast.session_manager`

#### SessionMethodChannel
**Purpose**: Controls individual session operations
**Channel Name**: `google_cast.session`

#### RemoteMediaClientMethodChannel
**Purpose**: Controls media playback, volume, seeking
**Channel Name**: `google_cast.media_client`

## 🔧 Development Setup

### Prerequisites

1. **Xcode** 12.0 or later
2. **iOS** 10.0 or later
3. **Google Cast SDK** (handled by CocoaPods)
4. **Flutter** SDK

### Building the iOS Plugin

```bash
# Navigate to the iOS directory
cd ios/

# Install dependencies
pod install

# Open workspace in Xcode
open Runner.xcworkspace
```

### Adding the Plugin to an iOS Project

1. **Add to Podfile**:
```ruby
pod 'flutter_chrome_cast', :path => '../'
```

2. **Configure Info.plist**:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses Cast Connect to discover Cast devices on your WiFi network.</string>
```

3. **Import Google Cast SDK**:
The plugin automatically includes the Google Cast SDK via CocoaPods.

## 🎯 Key Implementation Details

### Google Cast Context Initialization

The plugin initializes the Google Cast context with custom options:

```swift
func setSharedInstanceWithOption(arguments: Dictionary<String, Any>, result: @escaping FlutterResult) {
    // Parse options from Flutter
    let options = parseGoogleCastOptions(arguments)
    
    // Initialize Cast context
    GCKCastContext.setSharedInstanceWith(options)
    
    // Set up logging if enabled
    if kDebugLoggingEnabled {
        GCKLogger.sharedInstance().delegate = self
    }
}
```

### Method Channel Communication

Communication between Flutter and iOS follows this pattern:

1. **Flutter → iOS**: Method calls via `MethodChannel`
2. **iOS → Flutter**: Results via `FlutterResult` callback
3. **iOS → Flutter**: Events via `EventChannel` (for listeners)

### Error Handling

The plugin implements comprehensive error handling:

```swift
// Example error handling pattern
guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else {
    result(FlutterError(code: "NO_SESSION", message: "No active cast session", details: nil))
    return
}
```

## 🧩 Extension Points

### Custom Extensions Directory

The `Extensions/` directory contains Swift extensions that enhance the plugin's functionality. You can add custom extensions for:

- Custom media metadata handling
- Additional Cast SDK features
- Custom UI components

### Adding New Features

To add a new feature to the iOS implementation:

1. **Create Method Channel**:
```swift
class NewFeatureMethodChannel: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "google_cast.new_feature", binaryMessenger: registrar.messenger())
        let instance = NewFeatureMethodChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}
```

2. **Register in Main Plugin**:
```swift
public static func register(with registrar: FlutterPluginRegistrar) {
    // ... existing registrations
    NewFeatureMethodChannel.register(with: registrar)
}
```

3. **Implement Feature Logic**:
```swift
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "newFeatureMethod":
        handleNewFeature(call.arguments, result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

## 🐛 Debugging

### Enabling Cast SDK Logging

```swift
let kDebugLoggingEnabled = true  // Set to true for debugging

// In initialization
if kDebugLoggingEnabled {
    GCKLogger.sharedInstance().delegate = self
    GCKLogger.sharedInstance().loggingLevel = .verbose
}
```

### Common Issues

1. **Cast Discovery Not Working**:
   - Check network permissions in Info.plist
   - Ensure devices are on same network
   - Verify Cast SDK initialization

2. **Session Connection Fails**:
   - Check app ID configuration
   - Verify receiver app is running
   - Check firewall settings

3. **Media Playback Issues**:
   - Validate media URL accessibility
   - Check CORS settings for web content
   - Verify media format compatibility

## 📚 Resources

- [Google Cast iOS SDK Documentation](https://developers.google.com/cast/docs/ios_sender)
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [Swift Language Guide](https://docs.swift.org/swift-book/)

## 🤝 Contributing

When contributing to the iOS implementation:

1. Follow Swift coding conventions
2. Add comprehensive documentation for new methods
3. Include error handling for all Cast SDK calls
4. Test on multiple iOS versions and devices
5. Update this documentation for new features

## 📋 Testing Checklist

Before submitting iOS changes:

- [ ] Plugin builds successfully in Xcode
- [ ] All method channels respond correctly
- [ ] Error cases are handled gracefully
- [ ] Memory leaks are checked with Instruments
- [ ] Tested on multiple iOS versions
- [ ] Documentation is updated
