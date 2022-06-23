import 'package:google_cast/discovery_criteria.dart/discovery_criteria.dart';
import 'package:google_cast/google_cast_options/cast_options.dart';

class IOSGoogleCastOptions extends AFlutterGoogleCastOptions {
  GoogleCastDiscoveryCriteriaInitialize _discoveryCriteria;

  IOSGoogleCastOptions(this._discoveryCriteria);

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll(
        {
          'discoveryCriteria': _discoveryCriteria.toMap(),
        },
      );
  }
}
