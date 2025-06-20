# Swift Documentation Style Guide

## 📝 Overview

This guide provides the documentation standards for Swift files in the Flutter Google Cast plugin. All Swift code should follow these documentation conventions to ensure consistency and maintainability.

## 🎯 Documentation Standards

### File Header Documentation

Every Swift file should start with a comprehensive header:

```swift
//
//  FileName.swift
//  google_cast
//
//  Created by AUTHOR NAME on DD/MM/YY.
//

import Foundation
import GoogleCast

/// Brief description of the file's purpose
/// 
/// Detailed description explaining:
/// - What this file/class does
/// - Key features and responsibilities
/// - How it fits into the overall plugin architecture
/// - Integration points with other components
///
/// Key features:
/// - Feature 1 explanation
/// - Feature 2 explanation
/// - Feature 3 explanation
///
/// Usage patterns or important notes about the implementation.
///
/// - Author: AUTHOR NAME
/// - Since: iOS 10.0+
```

### Class Documentation

```swift
/// Brief description of the class
/// 
/// Detailed explanation of the class's purpose, responsibilities,
/// and role within the plugin architecture. Include:
/// - Main functionality
/// - Design patterns used (singleton, delegate, etc.)
/// - Integration with Google Cast SDK
/// - Communication with Flutter
///
/// Key features:
/// - List major capabilities
/// - Explain important behaviors
/// - Note any constraints or limitations
///
/// - Author: AUTHOR NAME
/// - Since: iOS 10.0+
class ExampleClass: UIResponder, FlutterPlugin {
```

### Method Documentation

```swift
/// Brief description of what the method does
/// 
/// Detailed explanation including:
/// - Purpose and behavior
/// - When it's called
/// - Side effects or state changes
/// - Error conditions
///
/// Supported operations:
/// - `operation1`: Description of operation 1
/// - `operation2`: Description of operation 2
///
/// - Parameters:
///   - param1: Description of parameter 1
///   - param2: Description of parameter 2
/// - Returns: Description of return value
/// - Throws: Description of possible exceptions
/// - Note: Important implementation details
/// - Warning: Critical warnings for users
func exampleMethod(param1: String, param2: Int) -> Bool {
    // Implementation
}
```

### Property Documentation

```swift
/// Brief description of the property
/// 
/// Detailed explanation including:
/// - What the property represents
/// - When it's updated
/// - How it's used
///
/// - Returns: Description of what the property returns
/// - Note: Important usage information
var exampleProperty: String? {
    // Implementation
}
```

### Extension Documentation

```swift
/// Extension description explaining the additional functionality
/// 
/// Detailed explanation of:
/// - Purpose of the extension
/// - What capabilities it adds
/// - How it integrates with the base type
/// - Flutter-specific concerns
///
/// The extension provides functionality for:
/// - Capability 1
/// - Capability 2
///
/// - Author: AUTHOR NAME
/// - Since: iOS 10.0+
extension GCKSomeClass {
```

## 🏷️ Documentation Tags

### Required Tags

- `/// Brief description`: One-line summary (required for all public APIs)
- `- Author:`: Creator of the code
- `- Since:`: Minimum iOS version supported

### Optional but Recommended Tags

- `- Parameters:`: Parameter descriptions
- `- Returns:`: Return value description  
- `- Throws:`: Exception information
- `- Note:`: Important implementation details
- `- Warning:`: Critical warnings
- `- Example:`: Usage examples
- `- SeeAlso:`: Related APIs

### Example with Multiple Tags

```swift
/// Initializes a Cast session with the specified device
/// 
/// Attempts to establish a connection to a Cast device using the
/// Google Cast SDK. This method handles device validation and
/// connection setup automatically.
///
/// The connection process includes:
/// - Device availability verification
/// - Network connectivity checks
/// - Cast SDK session initialization
///
/// - Parameters:
///   - deviceIndex: The index of the device in discovery list
///   - options: Optional connection parameters
/// - Returns: `true` if connection initiated successfully
/// - Throws: `CastError` if device is unavailable
/// - Note: Actual connection status reported via delegate callbacks
/// - Warning: Only call when discovery is active
/// - Example:
///   ```swift
///   let success = startSession(deviceIndex: 0, options: nil)
///   ```
/// - SeeAlso: `endSession()`, `GCKSessionManagerDelegate`
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
func startSession(deviceIndex: Int, options: CastOptions?) throws -> Bool {
    // Implementation
}
```

## 🔄 Flutter-Specific Documentation

### Method Channel Handlers

```swift
/// Handles method calls from the Flutter side
/// 
/// Processes incoming method calls for [specific functionality].
/// Each method corresponds to a specific Cast operation.
///
/// Supported methods:
/// - `methodName1`: Description of what it does
/// - `methodName2`: Description of what it does
/// - `methodName3`: Description of what it does
///
/// - Parameters:
///   - call: The Flutter method call containing method name and arguments
///   - result: Callback to return results or errors to Flutter
func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
```

### Listener/Delegate Methods

```swift
/// Called when [event] occurs
/// 
/// This delegate method is invoked by the Cast SDK when [condition].
/// It updates Flutter with the new state and handles any necessary
/// cleanup or state management.
///
/// - Parameters:
///   - manager: The manager instance that triggered the event
///   - data: The event data from the Cast SDK
/// - Note: This method automatically notifies Flutter of state changes
public func delegateMethod(_ manager: GCKManager, data: SomeType) {
```

### Data Conversion Methods

```swift
/// Converts [SourceType] to a Flutter-compatible dictionary
/// 
/// This method serializes [source] properties into a dictionary
/// format suitable for transmission to Flutter via method channels.
/// All properties are safely converted to Flutter-compatible types.
///
/// Dictionary keys include:
/// - `key1`: Description of key1
/// - `key2`: Description of key2
/// - `key3`: Description of key3
///
/// - Returns: Dictionary containing all properties for Flutter consumption
/// - Note: All properties are safely unwrapped and type-converted
func toDict() -> Dictionary<String, Any> {
```

## 📋 Code Organization

### MARK Comments

Use MARK comments to organize code sections:

```swift
// MARK: - Singleton Implementation
// MARK: - Properties  
// MARK: - Flutter Plugin Registration
// MARK: - Flutter Method Call Handling
// MARK: - Google Cast SDK Integration
// MARK: - Delegate Methods
// MARK: - Helper Methods
// MARK: - Data Conversion
```

### Section Documentation

Document major sections:

```swift
// MARK: - Google Cast Session Manager Listener

/// Implementation of GCKSessionManagerListener protocol
/// 
/// These methods are called by the Google Cast SDK when session
/// events occur. Each method updates the Flutter side with current
/// session state and handles any necessary state management.
```

## ✅ Documentation Checklist

Before submitting Swift code, ensure:

- [ ] File has comprehensive header documentation
- [ ] All public classes have class-level documentation
- [ ] All public methods have complete documentation
- [ ] All parameters and return values are documented
- [ ] Flutter-specific concerns are explained
- [ ] Google Cast SDK integration is documented
- [ ] Error conditions are noted
- [ ] Code sections are organized with MARK comments
- [ ] Examples are provided for complex methods
- [ ] Related APIs are cross-referenced

## 🎯 Quality Standards

### Good Documentation Example

```swift
/// Flutter method channel for Google Cast device discovery operations
/// 
/// This class manages the discovery of Google Cast devices on the local network.
/// It implements the Google Cast discovery manager listener protocol to receive
/// updates about Cast device availability and communicates these updates back
/// to the Flutter side via method channels.
///
/// Key features:
/// - Automatic device discovery management
/// - Real-time device list updates to Flutter
/// - Device indexing for Flutter-side device selection
/// - Singleton pattern for consistent state management
///
/// The class maintains a dictionary of discovered devices indexed by their
/// discovery position, enabling Flutter to reference devices by index when
/// initiating Cast sessions.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class FGCDiscoveryManagerMethodChannel : UIResponder, GCKDiscoveryManagerListener, FlutterPlugin {
```

### Poor Documentation Example (Avoid)

```swift
// Discovery manager class
class FGCDiscoveryManagerMethodChannel : UIResponder, GCKDiscoveryManagerListener, FlutterPlugin {
    
    // Channel
    var channel: FlutterMethodChannel?
    
    // Handle calls
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Do something
    }
}
```

## 🔍 Documentation Tools

### Xcode Integration

- Use Xcode's Quick Help (⌥ + Click) to verify documentation appears correctly
- Documentation comments should appear in autocomplete
- Ensure proper formatting in Quick Help popup

### Validation

Run documentation validation:
```bash
# Check documentation coverage
swift package test-documentation

# Generate documentation
swift package generate-documentation
```

This documentation style ensures that all Swift code in the Flutter Google Cast plugin is well-documented, maintainable, and accessible to both current and future contributors.
