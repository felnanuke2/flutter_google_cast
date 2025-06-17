# Customizable Texts Feature

The `ExpandedGoogleCastPlayerController` widget now supports customizable text content through the `ExpandedGoogleCastPlayerTexts` configuration class. This feature makes it easy to:

- **Localize** the player interface for different languages
- **Customize branding** with your own text labels
- **Maintain consistency** across your app's design language

## Usage

### Basic Usage

```dart
ExpandedGoogleCastPlayerController(
  texts: ExpandedGoogleCastPlayerTexts(
    unknownTitle: 'No Title Available',
    castingToDevice: (deviceName) => 'Playing on $deviceName',
    noCaptionsAvailable: 'No subtitles available',
    captionsOff: 'Turn off captions',
    trackFallback: (trackId) => 'Audio Track $trackId',
  ),
  toggleExpand: () => Navigator.pop(context),
)
```

### Internationalization Example

#### Spanish Localization
```dart
final spanishTexts = ExpandedGoogleCastPlayerTexts(
  unknownTitle: 'Título desconocido',
  castingToDevice: (deviceName) => 'Transmitiendo a $deviceName',
  noCaptionsAvailable: 'Sin subtítulos disponibles',
  captionsOff: 'Desactivar',
  trackFallback: (trackId) => 'Pista $trackId',
);
```

#### French Localization
```dart
final frenchTexts = ExpandedGoogleCastPlayerTexts(
  unknownTitle: 'Titre inconnu',
  castingToDevice: (deviceName) => 'Diffusion vers $deviceName',
  noCaptionsAvailable: 'Aucun sous-titre disponible',
  captionsOff: 'Désactivé',
  trackFallback: (trackId) => 'Piste $trackId',
);
```

### Custom Branding Example

```dart
final customBrandingTexts = ExpandedGoogleCastPlayerTexts(
  unknownTitle: 'Select media to play',
  castingToDevice: (deviceName) => 'Streaming to your $deviceName',
  noCaptionsAvailable: 'No subtitles found',
  captionsOff: 'Hide subtitles',
  trackFallback: (trackId) => 'Subtitle option $trackId',
);
```

## Available Text Properties

| Property | Type | Description | Default Value |
|----------|------|-------------|---------------|
| `unknownTitle` | `String` | Text displayed when media title is unknown | `'Unknown Title'` |
| `castingToDevice` | `String Function(String deviceName)` | Text showing which device is being cast to | `'Casting to $deviceName'` |
| `noCaptionsAvailable` | `String` | Text displayed when no caption tracks exist | `'No captions available'` |
| `captionsOff` | `String` | Text for the option to turn off captions | `'Off'` |
| `trackFallback` | `String Function(int trackId)` | Fallback text for caption track names | `'Track $trackId'` |

## Integration with Flutter Internationalization

You can easily integrate this with Flutter's built-in internationalization system:

```dart
class MyLocalizations {
  static ExpandedGoogleCastPlayerTexts getTexts(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return ExpandedGoogleCastPlayerTexts(
          unknownTitle: 'Título desconocido',
          castingToDevice: (device) => 'Transmitiendo a $device',
          noCaptionsAvailable: 'Sin subtítulos disponibles',
          captionsOff: 'Desactivar',
          trackFallback: (id) => 'Pista $id',
        );
      case 'fr':
        return ExpandedGoogleCastPlayerTexts(
          unknownTitle: 'Titre inconnu',
          castingToDevice: (device) => 'Diffusion vers $device',
          noCaptionsAvailable: 'Aucun sous-titre disponible',
          captionsOff: 'Désactivé',
          trackFallback: (id) => 'Piste $id',
        );
      default:
        return const ExpandedGoogleCastPlayerTexts(); // English defaults
    }
  }
}

// Usage in your widget
ExpandedGoogleCastPlayerController(
  texts: MyLocalizations.getTexts(Localizations.localeOf(context)),
  // ... other properties
)
```

## Notes

- All text properties have sensible English defaults
- Function-based properties allow for dynamic text generation
- The configuration is immutable and can be cached for performance
- Consider also customizing the `ExpandedGoogleCastPlayerTheme` for complete visual control
