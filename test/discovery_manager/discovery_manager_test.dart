import 'package:flutter_chrome_cast/discovery_manager/discovery_manager.dart';
import 'package:flutter_chrome_cast/discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeDiscoveryManager extends GoogleCastDiscoveryManagerPlatformInterface
    with MockPlatformInterfaceMixin {
  _FakeDiscoveryManager(this._devices);

  final List<GoogleCastDevice> _devices;

  @override
  List<GoogleCastDevice> get devices => _devices;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream => Stream.value(_devices);

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) async {
    return deviceCategory == 'cast';
  }

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}
}

void main() {
  group('GoogleCastDiscoveryManager facade', () {
    test('delegates to registered platform implementation', () async {
      final fake = _FakeDiscoveryManager([
        GoogleCastDevice(
          deviceID: 'id-1',
          friendlyName: 'Living Room TV',
          modelName: 'Chromecast',
          statusText: 'Ready',
          deviceVersion: '1.0',
          isOnLocalNetwork: true,
          category: 'cast',
          uniqueID: 'unique-1',
        ),
      ]);

      GoogleCastDiscoveryManagerPlatformInterface.instance = fake;

      final instance = GoogleCastDiscoveryManager.instance;
      expect(instance, same(fake));
      expect(instance.devices.single.friendlyName, 'Living Room TV');
      expect(await instance.isDiscoveryActiveForDeviceCategory('cast'), isTrue);
    });
  });
}
