// Test runner that imports and runs all test suites for the flutter_chrome_cast
// federated plugin. Each suite is in its own file; adding a new suite here
// ensures it is picked up by `flutter test test/test_runner.dart`.

import 'package:flutter_test/flutter_test.dart';

// Google Cast context
import '_google_cast_context/google_cast_context_test.dart'
    as cast_context_tests;
import '_google_cast_context/android_google_cast_context_method_channel_test.dart'
    as android_context_tests;
import '_google_cast_context/ios_google_cast_context_method_channel_test.dart'
    as ios_context_tests;

// Discovery manager
import '_discovery_manager/discovery_manager_test.dart'
    as discovery_manager_tests;
import '_discovery_manager/android_discovery_manager_test.dart'
    as android_discovery_tests;
import '_discovery_manager/ios_discovery_manager_test.dart'
    as ios_discovery_tests;

// Remote media client
import '_remote_media_client/android_remote_media_client_method_channel_test.dart'
    as android_media_client_tests;
import '_remote_media_client/ios_remote_media_client_method_channel_test.dart'
    as ios_media_client_tests;

// Models
import 'models/ios_cast_options_test.dart' as ios_cast_options_tests;
import 'models/ios_media_information_test.dart' as ios_media_info_tests;
import 'models/ios_metadata_test.dart' as ios_metadata_tests;

// Common
import 'common/image_test.dart' as image_tests;
import 'common/break_clips_test.dart' as break_clips_tests;

// Widgets
import 'widgets/mini_controller_test.dart' as mini_controller_tests;
import 'widgets/expanded_player_test.dart' as expanded_player_tests;

void main() {
  group('Flutter Chrome Cast – Full Test Suite', () {
    group('Cast Context (facade)', cast_context_tests.main);
    group('Cast Context – Android method channel', android_context_tests.main);
    group('Cast Context – iOS method channel', ios_context_tests.main);

    group('Discovery Manager (facade)', discovery_manager_tests.main);
    group('Discovery Manager – Android method channel',
        android_discovery_tests.main);
    group('Discovery Manager – iOS method channel', ios_discovery_tests.main);

    group('Remote Media Client – Android method channel',
        android_media_client_tests.main);
    group('Remote Media Client – iOS method channel',
        ios_media_client_tests.main);

    group('Models – iOS Cast Options', ios_cast_options_tests.main);
    group('Models – iOS Media Information', ios_media_info_tests.main);
    group('Models – iOS Metadata', ios_metadata_tests.main);

    group('Common – GoogleCastImage', image_tests.main);
    group('Common – CastBreakClips', break_clips_tests.main);

    group('Widgets – MiniController', mini_controller_tests.main);
    group('Widgets – ExpandedPlayer', expanded_player_tests.main);
  });
}
