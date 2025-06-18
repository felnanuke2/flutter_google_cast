# Flutter Google Cast Example

This example demonstrates how to use the `flutter_chrome_cast` plugin to discover, connect to, and cast media to Google Cast devices (Chromecast, Nest Hub, etc.) from a Flutter app.

## How to Run

1. Ensure you have a Chromecast or Google Cast-enabled device on your network.
2. In this directory, run:
   
   ```bash
   flutter pub get
   flutter run
   ```

## Features Demonstrated

- Device discovery and connection
- Listing available Cast devices
- Connecting/disconnecting from devices
- Casting video with metadata and subtitles
- Media queue management (add, play, insert items)
- Customizable player themes and texts (English, Spanish, French, custom branding)
- Mini controller widget integration

## Example Usage

Below is a minimal snippet to start device discovery and connect to a device:

```dart
// Start device discovery
GoogleCastDiscoveryManager.instance.startDiscovery();

// Listen for available devices
StreamBuilder<List<GoogleCastDevice>>(
  stream: GoogleCastDiscoveryManager.instance.devicesStream,
  builder: (context, snapshot) {
    final devices = snapshot.data ?? [];
    // ... display devices and connect
  },
);

// Connect to a device
await GoogleCastSessionManager.instance.startSessionWithDevice(device);
```

For a full-featured example, see `lib/main.dart` in this folder.

## More Information

See the main [README](../README.md) for full documentation, advanced usage, and troubleshooting.
