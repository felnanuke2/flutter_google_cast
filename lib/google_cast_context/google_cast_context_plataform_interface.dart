import 'package:google_cast/discovery_session/cast_discovery_manager.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/google_cast_options/cast_options.dart';
import 'package:google_cast/session_manager/cast_session_manager.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AGoogleCastContextPlatformInterface extends PlatformInterface {
  AGoogleCastContextPlatformInterface() : super(token: Object());

  AGoogleCastSessionManagerPlatformInterface get sessionManager;

  AGoogleCastDiscoveryManager get discoveryManager;

//MARK: - CONTEXT
  Future<bool> setSharedInstanceWithOptions(
      AFlutterGoogleCastOptions castOptions);

//MARK: - DISCOVERY MANAGER

  Future<bool> startSessionWithDevice(GoogleCastDevice device);

//MARK: - SESSION MANAGER

}
