# Kotlin Documentation Style Guide

## 📝 Overview

This guide provides the documentation standards for Kotlin files in the Flutter Google Cast plugin. All Kotlin code should follow these documentation conventions to ensure consistency and maintainability across the Android implementation.

## 🎯 Documentation Standards

### File Header Documentation

Every Kotlin file should start with a comprehensive header:

```kotlin
package com.felnanuke.google_cast

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
// ... other imports

/**
 * Brief description of the file's purpose
 * 
 * Detailed description explaining:
 * - What this file/class does
 * - Key features and responsibilities
 * - How it fits into the overall plugin architecture
 * - Integration points with other components
 * - Android-specific considerations
 *
 * Key features:
 * - Feature 1 explanation
 * - Feature 2 explanation
 * - Feature 3 explanation
 *
 * Architecture:
 * Explanation of how this component fits into the larger system,
 * its dependencies, and integration patterns.
 *
 * Usage patterns or important notes about the implementation.
 *
 * @author AUTHOR NAME
 * @since Android API 21 (Android 5.0)
 */
```

### Class Documentation

```kotlin
/**
 * Brief description of the class
 * 
 * Detailed explanation of the class's purpose, responsibilities,
 * and role within the plugin architecture. Include:
 * - Main functionality and behavior
 * - Design patterns used (singleton, factory, etc.)
 * - Integration with Google Cast SDK
 * - Communication with Flutter
 * - Android lifecycle considerations
 *
 * Key responsibilities:
 * - List major capabilities
 * - Explain important behaviors
 * - Note any constraints or limitations
 * - Describe state management
 *
 * Architecture:
 * Explain how this class integrates with:
 * - Other method channels
 * - Google Cast SDK components
 * - Android system services
 * - Flutter communication layer
 *
 * Lifecycle:
 * Describe any important lifecycle considerations,
 * especially for Android components.
 *
 * @param constructor_param Description of constructor parameter
 * @author AUTHOR NAME
 * @since Android API 21 (Android 5.0)
 */
class ExampleClass(constructor_param: Type) : FlutterPlugin, MethodChannel.MethodCallHandler {
```

### Method Documentation

```kotlin
/**
 * Brief description of what the method does
 * 
 * Detailed explanation including:
 * - Purpose and behavior
 * - When and how it's called
 * - Side effects or state changes
 * - Error conditions and handling
 * - Thread safety considerations
 * - Android-specific behavior
 *
 * Supported operations (for handlers):
 * - `operation1`: Description of operation 1
 * - `operation2`: Description of operation 2
 *
 * Process flow:
 * 1. Step 1 description
 * 2. Step 2 description
 * 3. Step 3 description
 *
 * @param param1 Description of parameter 1, including type constraints
 * @param param2 Description of parameter 2, including nullability
 * @return Description of return value, including possible null conditions
 * @throws ExceptionType Description of when this exception is thrown
 * @see RelatedClass Reference to related functionality
 * @since Android API 21 (Android 5.0)
 * 
 * Example usage:
 * ```kotlin
 * val result = exampleMethod(param1, param2)
 * ```
 */
fun exampleMethod(param1: String, param2: Int?): Boolean {
    // Implementation
}
```

### Property Documentation

```kotlin
/**
 * Brief description of the property
 * 
 * Detailed explanation including:
 * - What the property represents
 * - When and how it's updated
 * - Lifecycle considerations
 * - Thread safety information
 * - Nullability implications
 *
 * @return Description of what the property returns, including null conditions
 * @see RelatedProperty Reference to related properties
 * @since Android API 21 (Android 5.0)
 */
val exampleProperty: String?
    get() = computeValue()

/**
 * Description of lateinit property
 * 
 * Explanation of initialization timing and usage.
 * Note any thread safety or lifecycle considerations.
 *
 * @since Android API 21 (Android 5.0)
 */
private lateinit var channel: MethodChannel
```

### Extension Function Documentation

```kotlin
/**
 * Extension function description explaining the additional functionality
 * 
 * Detailed explanation of:
 * - Purpose of the extension
 * - What capabilities it adds to the receiver type
 * - How it integrates with existing functionality
 * - Flutter-specific concerns and data conversion
 * - Performance considerations
 *
 * The extension provides functionality for:
 * - Capability 1
 * - Capability 2
 *
 * Data conversion details:
 * Explain the mapping between source properties and target format,
 * including any type conversions or data transformations.
 *
 * @return Description of return value and format
 * @receiver ReceiverType The type this extension operates on
 * @since Android API 21 (Android 5.0)
 * 
 * Example usage:
 * ```kotlin
 * val device: CastDevice = getDevice()
 * val deviceMap = device.toMap()
 * ```
 */
fun ReceiverType.extensionFunction(): ReturnType {
    // Implementation
}
```

## 🏷️ Documentation Tags

### Required Tags

- `/** Brief description */`: One-line summary (required for all public APIs)
- `@author`: Creator of the code
- `@since`: Minimum Android API level supported

### Recommended Tags

- `@param`: Parameter descriptions with type and nullability info
- `@return`: Return value description including null conditions
- `@throws`: Exception information
- `@see`: Related classes, methods, or external references
- `@receiver`: For extension functions, describes the receiver type
- `@suppress`: For suppressing specific warnings with explanation

### Android-Specific Tags

- `@RequiresApi`: When method requires specific API level
- `@TargetApi`: When targeting specific API level behavior
- `@SuppressLint`: When suppressing lint warnings (with explanation)

### Example with Multiple Tags

```kotlin
/**
 * Initializes a Cast session with the specified device
 * 
 * Attempts to establish a connection to a Cast device using the Google Cast
 * SDK for Android. This method handles device validation, network connectivity
 * checks, and Cast SDK session initialization automatically.
 *
 * The connection process includes:
 * - Device availability verification
 * - Network connectivity validation
 * - Cast SDK session initialization
 * - Session state monitoring setup
 *
 * Process flow:
 * 1. Validate device ID format and availability
 * 2. Request route selection via MediaRouter
 * 3. Monitor connection status via SessionManagerListener
 * 4. Report connection status to Flutter
 *
 * @param deviceId The unique identifier of the Cast device to connect to
 * @param options Optional connection parameters for session customization
 * @return `true` if connection initiation was successful, `false` otherwise
 * @throws IllegalArgumentException if deviceId is null or invalid format
 * @throws SecurityException if required permissions are not granted
 * @see SessionManagerListener for connection status updates
 * @see MediaRouter for device selection implementation
 * @since Android API 21 (Android 5.0)
 * 
 * Example usage:
 * ```kotlin
 * val success = startSession("device_123", null)
 * if (success) {
 *     // Monitor SessionManagerListener for actual connection status
 * }
 * ```
 */
@Throws(IllegalArgumentException::class, SecurityException::class)
fun startSession(deviceId: String, options: CastOptions?): Boolean {
    // Implementation
}
```

## 🔄 Flutter-Specific Documentation

### Method Channel Handlers

```kotlin
/**
 * Handles method calls from the Flutter side
 * 
 * Processes incoming method calls for [specific functionality area].
 * Each method corresponds to a specific Cast operation with proper
 * error handling and result reporting back to Flutter.
 *
 * Supported methods:
 * - `methodName1`: Description of what it does and expected parameters
 * - `methodName2`: Description of what it does and expected parameters
 * - `methodName3`: Description of what it does and expected parameters
 *
 * Error handling:
 * All method calls include proper error handling with standardized
 * error codes and messages returned to Flutter for consistent
 * error reporting across the plugin.
 *
 * @param call The Flutter method call containing method name and arguments
 * @param result Callback to return results, success, or errors to Flutter
 * @since Android API 21 (Android 5.0)
 */
override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
```

### Listener/Callback Methods

```kotlin
/**
 * Called when [specific event] occurs in the Cast SDK
 * 
 * This callback method is invoked by the Google Cast SDK when [condition].
 * It processes the event, updates internal state as needed, and notifies
 * Flutter of the state change for UI updates.
 *
 * Event processing:
 * 1. Validate event data and session state
 * 2. Update internal component state
 * 3. Convert event data to Flutter-compatible format
 * 4. Notify Flutter via method channel invocation
 *
 * @param manager The Cast SDK manager instance that triggered the event
 * @param data The event data from the Cast SDK
 * @since Android API 21 (Android 5.0)
 */
override fun onEventCallback(manager: CastManager, data: EventData) {
```

### Data Conversion Methods

```kotlin
/**
 * Converts [SourceType] to a Flutter-compatible Map
 * 
 * This extension function serializes [source type] properties into a Map
 * format suitable for transmission to Flutter via method channels. All
 * properties are safely converted to Flutter-compatible types with proper
 * null handling.
 *
 * Map structure:
 * - `key1`: Description of key1 and its data type
 * - `key2`: Description of key2 and its data type
 * - `key3`: Description of key3 and its data type
 *
 * Type conversions:
 * - Explain any special type conversions
 * - Note handling of null values
 * - Describe enum to string conversions
 *
 * @return Map containing all properties for Flutter consumption
 * @receiver SourceType The Cast SDK object to convert
 * @since Android API 21 (Android 5.0)
 */
fun SourceType.toMap(): Map<String, Any?> {
```

## 📋 Code Organization

### Package-Level Documentation

```kotlin
/**
 * Google Cast plugin extensions for Android
 * 
 * This package contains extension functions that provide Flutter-compatible
 * data conversion for Google Cast SDK objects. These extensions ensure
 * consistent data representation across the Flutter-Android bridge.
 *
 * Key extensions:
 * - CastDevice.toMap(): Device information conversion
 * - MediaInfo.toMap(): Media metadata conversion
 * - Session.toMap(): Session state conversion
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
package com.felnanuke.google_cast.extensions
```

### Section Documentation

```kotlin
// MARK: - Flutter Plugin Lifecycle

/**
 * Flutter plugin lifecycle methods
 * 
 * These methods handle the attachment and detachment of the plugin
 * to the Flutter engine, ensuring proper resource management and
 * cleanup to prevent memory leaks.
 */

// MARK: - Google Cast SDK Integration

/**
 * Google Cast SDK integration methods
 * 
 * These methods interface directly with the Google Cast SDK for Android,
 * handling Cast-specific operations and translating between Cast SDK
 * data structures and Flutter-compatible formats.
 */
```

## ✅ Documentation Checklist

Before submitting Kotlin code, ensure:

- [ ] File has comprehensive header documentation
- [ ] All public classes have detailed class-level documentation
- [ ] All public methods have complete documentation
- [ ] All parameters and return values are documented
- [ ] Nullability is clearly documented
- [ ] Flutter-specific concerns are explained
- [ ] Google Cast SDK integration is documented
- [ ] Error conditions and exceptions are noted
- [ ] Thread safety considerations are mentioned
- [ ] Android API level requirements are specified
- [ ] Code sections are organized with comments
- [ ] Examples are provided for complex methods
- [ ] Related APIs are cross-referenced

## 🎯 Quality Standards

### Good Documentation Example

```kotlin
/**
 * Flutter method channel for Google Cast device discovery operations
 * 
 * This class manages the discovery of Google Cast devices on the local network using
 * Android's MediaRouter framework. It handles device discovery lifecycle, maintains
 * discovered device state, and communicates device availability changes to Flutter.
 *
 * Key responsibilities:
 * - Cast device discovery management (start/stop)
 * - Real-time device availability monitoring
 * - Device state synchronization with Flutter
 * - Integration with Android MediaRouter framework
 *
 * Architecture:
 * The class uses Android's MediaRouter system to discover Cast devices:
 * - MediaRouter: Core Android component for device discovery
 * - MediaRouteSelector: Defines criteria for Cast device discovery
 * - DiscoveryRouterCallback: Handles device discovery events
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {
```

### Poor Documentation Example (Avoid)

```kotlin
// Discovery manager
class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {
    
    // Channel
    lateinit var channel: MethodChannel
    
    // Handle calls
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Do something
    }
}
```

## 🔍 Documentation Tools

### Android Studio Integration

- Use Android Studio's Quick Documentation (Ctrl+Q) to verify documentation appears correctly
- Documentation comments should appear in autocomplete
- Ensure proper formatting in Quick Documentation popup

### Validation

```bash
# Generate documentation (if using Dokka)
./gradlew dokkaHtml

# Run lint checks
./gradlew lint

# Check code style
./gradlew ktlintCheck
```

### KDoc Standards

Follow KDoc conventions:
- Use `/**` for documentation comments
- Use `@param`, `@return`, `@throws` for structured documentation
- Include `@since` for API level requirements
- Use `@see` for cross-references
- Provide code examples in triple backticks

## 🚀 Best Practices

### Kotlin-Specific Documentation

1. **Null Safety**: Clearly document nullable types and null handling
2. **Extension Functions**: Document receiver type and extension purpose
3. **Coroutines**: Document suspend functions and threading behavior
4. **Data Classes**: Document property meanings and constraints
5. **Sealed Classes**: Document all possible subclasses and use cases

### Android-Specific Considerations

1. **Lifecycle**: Document Android lifecycle dependencies
2. **Permissions**: Note required permissions and runtime requests
3. **Threading**: Specify which thread methods should be called on
4. **Memory**: Document memory management and leak prevention
5. **API Levels**: Specify minimum and target API requirements

This documentation style ensures that all Kotlin code in the Flutter Google Cast plugin is professionally documented, maintainable, and accessible to both current and future contributors working on the Android implementation.
