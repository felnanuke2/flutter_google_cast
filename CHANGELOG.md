## 1.0.4
### Bug Fixes
- **Code Quality**: Fixed Dart formatting issues across the entire codebase
- **Static Analysis**: Resolved formatting warnings to improve pub.dev package score
- **Formatted Files**: Applied Dart formatter to 115 files ensuring compliance with Dart style guidelines
  - Fixed formatting in `android_discovery_manager.dart`
  - Fixed formatting in `ios_cast_session_manager.dart`
  - Applied consistent formatting across all library files

## 1.0.3
### Breaking Changes
- **Enum Naming Convention Update**: All enums have been updated from UPPER_SNAKE_CASE to lowerCamelCase for better Dart conventions
  - `GoogleCastConnectState.ConnectionStateConnected` → `GoogleCastConnectState.connected`
  - `CastMediaStreamType.BUFFERED` → `CastMediaStreamType.buffered`
  - `TrackType.TEXT` → `TrackType.text`
  - `TextTrackType.SUBTITLES` → `TextTrackType.subtitles`
  - `RFC5646_LANGUAGE` → `Rfc5646Language`
  - And many more enum updates across the codebase

### Android Build System Modernization
- **Gradle Update**: Updated from 7.x to 8.4 for better compatibility
- **Android Gradle Plugin**: Updated from 7.x to 8.3.0
- **Kotlin**: Updated from 1.6.10 to 1.9.10
- **Java Compatibility**: Updated to Java 11
- **Android SDK**: Updated compile SDK to 35, target SDK to 34
- **Dependencies**: Updated Google Cast Framework (21.0.1 → 21.5.0), AndroidX libraries, and other Android dependencies

### Enhanced UI/UX
- **Completely Redesigned Mini Controller**: 
  - Modern Material Design with floating card style
  - Marquee text scrolling for long titles and subtitles
  - Better visual hierarchy and improved touch targets
  - Theme-aware styling with customizable colors and typography
- **Enhanced Expanded Player**:
  - Drag-to-dismiss gesture support with smooth animations
  - Better media image handling with fallbacks
  - Improved controls layout with backdrop blur effects
  - Caption/subtitle track selection
  - Seek forward/backward 30 seconds functionality
  - Volume control integration
- **Theme Support**: Added comprehensive theming with `ExpandedGoogleCastPlayerTheme`
- **Internationalization**: Added `ExpandedGoogleCastPlayerTexts` for customizable text content

### Bug Fixes
- **Device Discovery**: Fixed duplicate device detection in Android discovery manager
- **Error Handling**: Improved error handling and removed debug print statements
- **Import Issues**: Fixed missing imports and dependency issues
- **Memory Leaks**: Better disposal of animation controllers and stream subscriptions
- **UI Stability**: Fixed various layout and rendering issues

### New Features
- **Marquee Text Support**: Added `marquee` package dependency for scrolling text
- **Customizable Texts**: Complete internationalization support with example
- **Advanced Theming**: Comprehensive theme customization options
- **Better Examples**: Added `customizable_texts_example.dart` and documentation
- **Enhanced Documentation**: Added `CUSTOMIZABLE_TEXTS.md` with usage examples

### Developer Experience
- **Improved Code Quality**: Better type safety, null safety compliance
- **Documentation**: Enhanced inline documentation and examples
- **File Organization**: Better separation of concerns and cleaner imports

### Migration Guide
If you're upgrading from previous versions, you'll need to update enum usage:
```dart
// Before
GoogleCastConnectState.ConnectionStateConnected
CastMediaStreamType.BUFFERED
TrackType.TEXT

// After  
GoogleCastConnectState.connected
CastMediaStreamType.buffered
TrackType.text
```

## 1.0.2
- Improved README.md with better documentation and examples
- Enhanced setup instructions and usage guidelines
- Updated documentation formatting and clarity

## 0.0.1

* TODO: Describe initial release.


## 0.0.3
allow change subtitle tracks and audio tracks

## 0.0.4
add license to pubspec.yaml

## 0.0.5
add repository to pubspec.yaml

## 0.0.6
generate dart doc with dartdoc

## 0.0.7
update package name in podpec

## 0.0.8
fix GoogleCastPlugin.m file

## 0.0.9
fix /android/app/src/main/AndroidManifest.xml and add
```xml
<meta-data
           android:name=
               "com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
           android:value="com.felnanuke.google_cast.GoogleCastOptionsProvider" />
```

## 0.0.10
- Now supports Flutter 3.22.0, thanks to contributions from fmsidoe.

## 0.0.11
- fix issue on that crash app when session is disconnected
- add to doc and example new properties required to work on android api 34+

## 1.0.0
- Update plugin to support Flutter v3.24.3.
- Bump version and update dependency versions in pubspec.yaml.
- Update SDK constraints in both main and example pubspec files for compatibility with latest Flutter.
- Add conditional namespace configuration in android/build.gradle for compatibility with the latest Gradle and Android Studio.

## 1.0.1
- Update README example to use fully qualified provider class name for Android manifest integration
- Clarify the android:value meta-data entry with complete package path to prevent ambiguity when registering the options provider
