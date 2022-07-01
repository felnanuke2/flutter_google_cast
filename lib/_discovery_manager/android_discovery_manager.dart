import 'package:google_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:google_cast/entities/cast_device.dart';

class GoogleCastDiscoveryManagerMethodChannelAndroid
    implements GoogleCastDiscoveryManagerPlatformInterface {
  @override
  // TODO: implement devices
  List<GoogleCastDevice> get devices => throw UnimplementedError();

  @override
  // TODO: implement devicesStream
  Stream<List<GoogleCastDevice>> get devicesStream =>
      throw UnimplementedError();

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) {
    // TODO: implement isDiscoveryActiveForDeviceCategory
    throw UnimplementedError();
  }

  @override
  Future<void> startDiscovery() {
    // TODO: implement startDiscovery
    throw UnimplementedError();
  }

  @override
  Future<void> stopDiscovery() {
    // TODO: implement stopDiscovery
    throw UnimplementedError();
  }
}
