## 1.2.1 - Documentation & Testing Improvements
### 📚 Documentation Enhancements
- **Expanded API Documentation**: Added comprehensive documentation for public members across all Dart classes
- **Improved Public API Coverage**: Enhanced doc comments for better IDE support and developer experience
- **Coverage Badge**: Added test coverage badge to track and display code coverage metrics

### 🧪 Testing Infrastructure
- **Test Suite Initialization**: Started implementing comprehensive test coverage for the application
- **Testing Foundation**: Established testing framework and initial test cases for core functionality
- **Quality Assurance**: Improved code reliability through systematic testing approach

### 🔧 Code Quality
- **Documentation Standards**: Ensured all public class members have proper documentation
- **Code Coverage Tracking**: Implemented coverage monitoring for better code quality insights
- **Developer Experience**: Enhanced IDE support with better API documentation

## 1.2.0 - API Documentation & Quality Release
### 📚 Documentation & API Improvements
- **Extensive API Documentation**: Added or improved doc comments for nearly all public classes, methods, enums, and fields across the codebase.
- **Public API Coverage**: Significantly increased public API documentation coverage for better IDE support and pub.dev health.
- **README & Example Updates**: Improved usage examples, customization guides, and documentation for easier integration.
- **Linter Rule**: Enabled `public_member_api_docs` lint to enforce documentation for all public members.
- **No Breaking Changes**: This is a safe update with no breaking API changes.

### 🛠️ Internal & Quality
- Improved code comments and structure for maintainability.
- All previous features and fixes from 1.1.1 included.

## 1.1.1 - Perfect Package Score Achievement
### 🏆 Quality Improvements
- **Perfect Pana Score**: Achieved 160/160 points in package analysis
  - ✅ **File Conventions (30/30)**: Valid `pubspec.yaml`, `README.md`, `CHANGELOG.md`, and OSI-approved BSD-3-Clause license
  - ✅ **Documentation (20/20)**: 31.5% of public API documented (above 20% requirement) with comprehensive example
  - ✅ **Platform Support (20/20)**: Full iOS and Android support
  - ✅ **Static Analysis (50/50)**: Zero errors, warnings, lints, or formatting issues
  - ✅ **Dependencies (40/40)**: All dependencies up-to-date and compatible with constraint lower bounds

### 🔧 Technical Improvements
- **Code Formatting**: Applied `dart format` to ensure consistent code style across all files
- **Static Analysis**: Resolved all linting and formatting issues for perfect static analysis score
- **Dependency Compatibility**: Verified compatibility with latest stable Dart and Flutter SDKs
- **Package Health**: Optimized for pub.dev publication with excellent package health metrics

### 📊 Package Metrics
- **API Documentation Coverage**: 234 out of 744 API elements documented (31.5%)
- **Platform Coverage**: iOS ✅ Android ✅
- **License**: BSD-3-Clause (OSI-approved)
- **Dependencies**: All current and compatible
- **Static Analysis**: Perfect score with zero issues

## 1.1.0 - Modular Import System
### ✨ New Features
- **Modular Import System**: Introduced a new flexible import structure for better performance and cleaner code
  - Added `flutter_chrome_cast.dart` as the main entry point (imports everything)
  - Added selective imports: `cast_context.dart`, `discovery.dart`, `session.dart`, `media.dart`, `widgets.dart`, etc.
  - Each module exports only related functionality for optimized bundle size

### 📦 Import Options
- **Complete Import**: `import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';` (recommended for getting started)
- **Selective Imports**: Import only what you need for production apps
  ```dart
  import 'package:flutter_chrome_cast/cast_context.dart';  // Core functionality
  import 'package:flutter_chrome_cast/media.dart';         // Media control
  import 'package:flutter_chrome_cast/widgets.dart';       // UI widgets
  ```

### 📈 Benefits
- **Smaller Bundle Size**: Only include the functionality you actually use
- **Faster Compilation**: Less code to analyze and compile
- **Cleaner Namespace**: Avoid importing unused classes
- **Better IDE Support**: More precise auto-completion and error detection

### 🔄 Migration Guide
- **Old**: `import 'package:flutter_chrome_cast/lib.dart';` (still works but deprecated)
- **New**: Choose between complete import or selective imports based on your needs

### 📚 Documentation
- Updated README with comprehensive import strategy guide
- Added import comparison table showing what each module includes
- Added migration examples and best practices

### ⚠️ Deprecations
- `lib.dart` is now deprecated in favor of the new import system (still functional for backward compatibility)

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
