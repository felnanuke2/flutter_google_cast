import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/widgets/expanded_player.dart';

/// Example demonstrating how to customize texts in the ExpandedGoogleCastPlayerController
class CustomizableTextsExample extends StatelessWidget {
  const CustomizableTextsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customizable Texts Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: English (default)
            ElevatedButton(
              onPressed: () => _showPlayer(context, _englishTexts),
              child: const Text('Show Player (English)'),
            ),
            const SizedBox(height: 16),
            
            // Example 2: Spanish
            ElevatedButton(
              onPressed: () => _showPlayer(context, _spanishTexts),
              child: const Text('Show Player (Spanish)'),
            ),
            const SizedBox(height: 16),
            
            // Example 3: French
            ElevatedButton(
              onPressed: () => _showPlayer(context, _frenchTexts),
              child: const Text('Show Player (French)'),
            ),
            const SizedBox(height: 16),
            
            // Example 4: Custom branding
            ElevatedButton(
              onPressed: () => _showPlayer(context, _customBrandingTexts),
              child: const Text('Show Player (Custom Branding)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayer(BuildContext context, ExpandedGoogleCastPlayerTexts texts) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpandedGoogleCastPlayerController(
          texts: texts,
          toggleExpand: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Default English texts
  static const _englishTexts = ExpandedGoogleCastPlayerTexts();

  // Spanish localization
  static const _spanishTexts = ExpandedGoogleCastPlayerTexts(
    unknownTitle: 'Título desconocido',
    castingToDevice: _spanishCastingToDevice,
    noCaptionsAvailable: 'Sin subtítulos disponibles',
    captionsOff: 'Desactivar',
    trackFallback: _spanishTrackFallback,
  );

  static String _spanishCastingToDevice(String deviceName) => 'Transmitiendo a $deviceName';
  static String _spanishTrackFallback(int trackId) => 'Pista $trackId';

  // French localization
  static const _frenchTexts = ExpandedGoogleCastPlayerTexts(
    unknownTitle: 'Titre inconnu',
    castingToDevice: _frenchCastingToDevice,
    noCaptionsAvailable: 'Aucun sous-titre disponible',
    captionsOff: 'Désactivé',
    trackFallback: _frenchTrackFallback,
  );

  static String _frenchCastingToDevice(String deviceName) => 'Diffusion vers $deviceName';
  static String _frenchTrackFallback(int trackId) => 'Piste $trackId';

  // Custom branding example
  static const _customBrandingTexts = ExpandedGoogleCastPlayerTexts(
    unknownTitle: 'No media selected',
    castingToDevice: _customCastingToDevice,
    noCaptionsAvailable: 'No subtitles found',
    captionsOff: 'Hide subtitles',
    trackFallback: _customTrackFallback,
  );

  static String _customCastingToDevice(String deviceName) => 'Streaming to your $deviceName';
  static String _customTrackFallback(int trackId) => 'Subtitle option $trackId';
}
