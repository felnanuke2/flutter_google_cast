# Cast Context Pigeon Native Test Scaffold

## Android (Kotlin/JUnit)
- Verify CastContextHostApi.setSharedInstanceWithOptions maps appId correctly.
- Verify stopCastingOnAppTerminated is persisted into GoogleCastOptionsProvider.
- Verify CAST_ERROR FlutterError is returned when appId is missing.

## iOS (Swift/XCTest)
- Verify GoogleCastContextHostApi forwards options to setSharedInstanceWithOption.
- Verify stopCastingOnAppTerminated is stored from incoming map.
- Verify malformed options map produces FlutterError with CAST_ERROR.

## Notes
- This file is a scaffold for Stage 3 native tests.
- Add concrete tests when CI includes Android unit + Swift package test jobs.
