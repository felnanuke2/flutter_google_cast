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
