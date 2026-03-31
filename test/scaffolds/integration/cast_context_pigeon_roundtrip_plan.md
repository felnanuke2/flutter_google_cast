# Cast Context Integration Test Scaffold

## Scenario
1. Launch example app.
2. Build GoogleCastOptionsAndroid or IOSGoogleCastOptions.
3. Call setSharedInstanceWithOptions from Dart.
4. Assert no PlatformException is thrown.
5. Assert discovery manager can be queried after initialization.

## Coverage Goal
- Validates Pigeon channel is wired end-to-end.
- Ensures fallback MethodChannel path remains compatible.

## Suggested Location
- example/integration_test/cast_context_init_test.dart

## Blocking Setup
- Add integration_test dependency and CI target for device/emulator execution.
