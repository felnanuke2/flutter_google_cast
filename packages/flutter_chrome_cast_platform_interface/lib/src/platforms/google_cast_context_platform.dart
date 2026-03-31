import 'package:flutter_chrome_cast_platform_interface/src/entities/cast_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Google Cast context functionality.
///
/// This abstract class defines the contract that platform-specific implementations
/// must follow for initializing and managing the Google Cast context.
abstract class GoogleCastContextPlatformInterface extends PlatformInterface {
  static final Object _token = Object();

  /// Creates a new instance of the platform interface.
  GoogleCastContextPlatformInterface() : super(token: _token);

  static GoogleCastContextPlatformInterface? _instance;

  /// The current registered platform implementation.
  ///
  /// Platform-specific packages set this in their [registerWith] method.
  /// Throws [UnimplementedError] if no implementation has been registered.
  static GoogleCastContextPlatformInterface get instance {
    return _instance ??
        (throw UnimplementedError(
          'No implementation registered for GoogleCastContextPlatformInterface. '
          'Make sure to include a platform implementation package such as '
          'flutter_chrome_cast_android or flutter_chrome_cast_ios.',
        ));
  }

  /// Registers a platform-specific implementation.
  ///
  /// Called by endorsed platform packages in their [registerWith] method.
  /// Verifies the token to prevent `implements`-based registration bypasses.
  static set instance(GoogleCastContextPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  //MARK: - CONTEXT
  /// Initializes the shared Google Cast context with the provided options.
  ///
  /// [castOptions] contains the configuration options for the Cast context.
  /// Returns true if the initialization was successful, false otherwise.
  Future<bool> setSharedInstanceWithOptions(GoogleCastOptions castOptions);
}
