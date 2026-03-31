import 'package:flutter_chrome_cast_platform_interface/src/entities/cast_device.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Google Cast device discovery functionality.
///
/// This abstract class defines the contract that platform-specific implementations
/// must follow. It manages the device discovery process and maintains a collection
/// of currently discovered Google Cast devices.
///
/// The framework automatically starts the discovery process when the application
/// moves to the foreground and suspends it when the application moves to the background.
/// It is generally not necessary for the application to manually start and stop discovery,
/// except as an optimization measure to reduce network traffic and CPU utilization.
///
/// Based on the Google Cast iOS SDK's GCKDiscoveryManager class.
abstract class GoogleCastDiscoveryManagerPlatformInterface
    extends PlatformInterface {
  static final Object _token = Object();

  /// Creates a new [GoogleCastDiscoveryManagerPlatformInterface].
  GoogleCastDiscoveryManagerPlatformInterface() : super(token: _token);

  static GoogleCastDiscoveryManagerPlatformInterface? _instance;

  /// The current registered platform implementation.
  ///
  /// Throws [UnimplementedError] if no implementation has been registered.
  static GoogleCastDiscoveryManagerPlatformInterface get instance {
    return _instance ??
        (throw UnimplementedError(
          'No implementation registered for GoogleCastDiscoveryManagerPlatformInterface. '
          'Make sure to include a platform implementation package such as '
          'flutter_chrome_cast_android or flutter_chrome_cast_ios.',
        ));
  }

  /// Registers a platform-specific implementation.
  ///
  /// Called by endorsed platform packages in their [registerWith] method.
  static set instance(GoogleCastDiscoveryManagerPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the list of currently discovered devices.
  List<GoogleCastDevice> get devices;

  /// Returns a stream of the currently discovered devices.
  Stream<List<GoogleCastDevice>> get devicesStream;

  /// Starts the discovery process.
  /// strongly recommended to call this method when the application is show cast devices dialog
  /// because the battery consumption is high when the discovery process is running.
  Future<void> startDiscovery();

  ///Stops the discovery process.
  /// strongly recommended to call this method when the application close the show cast devices dialog
  /// for reduce battery consumption.
  Future<void> stopDiscovery();

  ///Tests whether discovery is currently active for the given device category.
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory);
}
