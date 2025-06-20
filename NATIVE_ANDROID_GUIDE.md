# Flutter Chrome Cast - Android Native Implementation Guide

## 🤖 Android Architecture Overview

The Android implementation of the Flutter Chrome Cast plugin is built using **Kotlin** and integrates with **Google Cast SDK for Android**. The architecture follows the Flutter plugin pattern with method channels for bidirectional communication between Dart and native code.

## 📁 File Structure

```
android/
├── build.gradle                           # Plugin build configuration
├── proguard-rules.pro                     # ProGuard rules
├── src/main/
│   ├── AndroidManifest.xml               # Plugin manifest
│   ├── kotlin/com/felnanuke/google_cast/
│   │   ├── GoogleCastPlugin.kt           # Main plugin entry point
│   │   ├── CastContextMethodChannel.kt   # Cast context management
│   │   ├── DiscoveryManagerMethodChannel.kt # Device discovery
│   │   ├── SessionManagerMethodChannel.kt   # Session management
│   │   ├── RemoteMediaClientMethodChannel.kt # Media control
│   │   ├── GoogleCastOptionsProvider.kt  # Cast options provider
│   │   └── extensions/                   # Kotlin extensions
│   │       ├── CastDeviceExtensions.kt
│   │       ├── MediaInfoExtensions.kt
│   │       ├── MediaStatusExtensions.kt
│   │       ├── MetadataExtensions.kt
│   │       ├── SessionExtensions.kt
│   │       └── ...
│   └── res/                              # Android resources
```

## 🚀 Core Components

### 1. GoogleCastPlugin (Main Plugin)

**File**: `GoogleCastPlugin.kt`

The main plugin class that implements Flutter plugin interfaces:

```kotlin
class GoogleCastPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val castContextMethodChannel = CastContextMethodChannel()
    
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result)
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding)
}
```

**Key Properties**:
- `channel`: Main method channel for plugin communication
- `castContextMethodChannel`: Handles Cast context operations

### 2. Method Channels

Each major feature has its dedicated method channel:

#### CastContextMethodChannel
**Purpose**: Manages Google Cast context initialization and configuration
**Channel Name**: `google_cast.context`
**Key Methods**:
- `setSharedInstanceWithOptions`: Initialize Cast context
- `getSharedInstance`: Get current context

#### DiscoveryManagerMethodChannel
**Purpose**: Handles Cast device discovery
**Channel Name**: `google_cast.discovery_manager`
**Key Methods**:
- `startDiscovery`: Begin device scanning
- `stopDiscovery`: Stop device scanning
- `getDiscoveredDevices`: Get available devices

#### SessionManagerMethodChannel
**Purpose**: Manages Cast sessions lifecycle
**Channel Name**: `google_cast.session_manager`
**Key Methods**:
- `startSessionWithDevice`: Connect to Cast device
- `endCurrentSession`: Disconnect from device
- `getCurrentSession`: Get active session info

#### RemoteMediaClientMethodChannel
**Purpose**: Controls media playback and status
**Channel Name**: `google_cast.media_client`
**Key Methods**:
- `loadMedia`: Load media content
- `play`: Start playback
- `pause`: Pause playback
- `seek`: Seek to position
- `setVolume`: Control volume

### 3. GoogleCastOptionsProvider

**File**: `GoogleCastOptionsProvider.kt`

Provides Cast SDK configuration using `OptionsProvider` pattern:

```kotlin
class GoogleCastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        return CastOptions.Builder()
            .setReceiverApplicationId(receiverApplicationId)
            .build()
    }
}
```

## 🔧 Development Setup

### Prerequisites

1. **Android Studio** 4.0 or later
2. **Android SDK** API level 21 (Android 5.0) or later
3. **Kotlin** 1.5.0 or later
4. **Google Cast SDK** (handled by Gradle)
5. **Flutter** SDK

### Building the Android Plugin

```bash
# Navigate to the Android directory
cd android/

# Build the plugin
./gradlew build

# Run tests
./gradlew test
```

### Adding the Plugin to an Android Project

1. **Add to app/build.gradle**:
```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-cast-framework:21.+'
}
```

2. **Configure AndroidManifest.xml**:
```xml
<application>
    <!-- Cast Options Provider -->
    <meta-data
        android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
        android:value="com.felnanuke.google_cast.GoogleCastOptionsProvider" />
</application>
```

3. **Add Network Security Config** (for HTTP content):
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

## 🎯 Key Implementation Details

### Cast Context Initialization

The Android plugin uses the `OptionsProvider` pattern for initialization:

```kotlin
// In GoogleCastOptionsProvider.kt
override fun getCastOptions(context: Context): CastOptions {
    val notificationOptions = NotificationOptions.Builder()
        .setTargetActivityClassName(ExpandedControlsActivity::class.java.name)
        .build()
        
    return CastOptions.Builder()
        .setReceiverApplicationId(receiverApplicationId)
        .setNotificationOptions(notificationOptions)
        .setStopReceiverApplicationWhenEndingSession(true)
        .build()
}
```

### Method Channel Communication

Standard Flutter plugin communication pattern:

```kotlin
override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "methodName" -> {
            try {
                val response = handleMethod(call.arguments)
                result.success(response)
            } catch (e: Exception) {
                result.error("ERROR_CODE", e.message, e.stackTrace)
            }
        }
        else -> result.notImplemented()
    }
}
```

### Extension Functions

The plugin uses Kotlin extensions for clean data conversion:

```kotlin
// Example: CastDeviceExtensions.kt
fun CastDevice.toMap(): Map<String, Any?> {
    return mapOf(
        "deviceId" to deviceId,
        "friendlyName" to friendlyName,
        "deviceType" to deviceType,
        "ipAddress" to ipAddress?.hostAddress,
        "servicePort" to servicePort
    )
}

fun Map<String, Any>.toCastDevice(): CastDevice? {
    // Convert map back to CastDevice
}
```

## 🧩 Extension Points

### Adding Custom Extensions

Create new Kotlin extension files in the `extensions/` directory:

```kotlin
// CustomExtensions.kt
fun MediaInfo.toCustomMap(): Map<String, Any?> {
    return mapOf(
        "customField" to customValue,
        // ... other custom mappings
    )
}
```

### Adding New Method Channels

1. **Create Method Channel Class**:
```kotlin
class NewFeatureMethodChannel : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "google_cast.new_feature")
        channel.setMethodCallHandler(this)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "newMethod" -> handleNewMethod(call.arguments, result)
            else -> result.notImplemented()
        }
    }
}
```

2. **Register in Main Plugin**:
```kotlin
class GoogleCastPlugin : FlutterPlugin {
    private val newFeatureChannel = NewFeatureMethodChannel()
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // ... existing setup
        newFeatureChannel.onAttachedToEngine(flutterPluginBinding)
    }
}
```

## 🐛 Debugging

### Enabling Cast SDK Logging

```kotlin
// In Application class or plugin initialization
CastContext.getSharedInstance(context).logger.setDebugLoggingEnabled(true)
```

### Common Issues

1. **Cast Discovery Not Working**:
```kotlin
// Check if Cast SDK is properly initialized
val castContext = CastContext.getSharedInstance(context)
if (castContext == null) {
    // Cast SDK not initialized
}
```

2. **Session Connection Issues**:
```kotlin
// Verify session manager state
val sessionManager = CastContext.getSharedInstance().sessionManager
val currentSession = sessionManager.currentCastSession
if (currentSession == null || !currentSession.isConnected) {
    // No active session
}
```

3. **Media Loading Problems**:
```kotlin
// Check media load result
val remoteMediaClient = currentSession.remoteMediaClient
remoteMediaClient?.load(mediaInfo)?.setResultCallback { result ->
    if (!result.status.isSuccess) {
        // Handle load failure
        Log.e("Cast", "Media load failed: ${result.status}")
    }
}
```

### ProGuard Configuration

If using ProGuard, add these rules to `proguard-rules.pro`:

```proguard
# Google Cast SDK
-keep class com.google.android.gms.cast.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Plugin classes
-keep class com.felnanuke.google_cast.** { *; }
```

## 🚦 Testing

### Unit Testing

```kotlin
// Example test structure
class GoogleCastPluginTest {
    private lateinit var plugin: GoogleCastPlugin
    private lateinit var mockChannel: MethodChannel
    
    @Before
    fun setUp() {
        plugin = GoogleCastPlugin()
        mockChannel = mock(MethodChannel::class.java)
    }
    
    @Test
    fun testMethodCall() {
        // Test method call handling
    }
}
```

### Integration Testing

```bash
# Run Android instrumentation tests
cd example/
flutter drive --target=test_driver/integration_test.dart
```

## 📚 Resources

- [Google Cast Android SDK Documentation](https://developers.google.com/cast/docs/android_sender)
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [Kotlin Language Guide](https://kotlinlang.org/docs/)
- [Android Development](https://developer.android.com/)

## 🤝 Contributing

When contributing to the Android implementation:

1. Follow Kotlin coding conventions
2. Use null safety and proper error handling
3. Add KDoc comments for public methods
4. Include unit tests for new functionality
5. Update this documentation for new features
6. Test on multiple Android versions and devices

### Code Style Guidelines

```kotlin
// Class naming: PascalCase
class GoogleCastPlugin

// Method naming: camelCase
fun handleMethodCall()

// Constants: SCREAMING_SNAKE_CASE
companion object {
    private const val CHANNEL_NAME = "google_cast"
}

// Null safety
fun safeMethod(param: String?): String {
    return param ?: "default"
}
```

## 📋 Testing Checklist

Before submitting Android changes:

- [ ] Plugin builds successfully with Gradle
- [ ] All method channels respond correctly
- [ ] Null safety is properly implemented
- [ ] Error cases are handled gracefully
- [ ] ProGuard rules are updated if needed
- [ ] Tested on multiple Android versions
- [ ] Unit tests pass
- [ ] Documentation is updated
- [ ] Code follows Kotlin style guidelines
