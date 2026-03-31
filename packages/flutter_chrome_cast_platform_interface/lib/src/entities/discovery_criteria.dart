/// Represents criteria for discovering Google Cast devices.
abstract class GoogleCastDiscoveryCriteria {
  /// Initializes discovery criteria with the provided configuration.
  static GoogleCastDiscoveryCriteriaInitialize initialize(
    GoogleCastDiscoveryCriteriaInitialize initializeWith,
  ) => initializeWith;

  /// this command is useful to native execute a custom command

  /// Default application ID for Cast devices.
  static const String kDefaultApplicationId = 'CC1AD845';

  /// Set of application IDs to discover.
  Set<String>? get applicationIds;

  /// Whether application IDs are set.
  bool? get hasApplicationIds;

  /// Set of namespaces to discover.
  Set<String>? get namespaces;

  /// Whether namespaces are set.
  bool? get hasNamespaces;

  /// Set of all subtypes.
  Set<String>? get allSubtypes;
}

/// Provides initialization options for Google Cast discovery criteria.
class GoogleCastDiscoveryCriteriaInitialize {
  /// Creates a new [GoogleCastDiscoveryCriteriaInitialize] with typed fields.
  const GoogleCastDiscoveryCriteriaInitialize._({
    required this.method,
    this.applicationID,
    this.namespaces,
  });

  /// The initialization method that should be used on native side.
  final GoogleCastDiscoveryCriteriaInitMethod method;

  /// Optional application ID used by [GoogleCastDiscoveryCriteriaInitMethod.initWithApplicationID].
  final String? applicationID;

  /// Optional namespaces used by [GoogleCastDiscoveryCriteriaInitMethod.initWithNamespaces].
  final Set<String>? namespaces;

  /// Backward-compatible view used by existing integrations.
  Map<String, dynamic> get data => <String, dynamic>{
    'method': method.name,
    'applicationID': applicationID,
    'namespaces': namespaces,
  };

  /// Initializes with an application ID.
  factory GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
    String applicationID,
  ) {
    _DiscoveryCriteriaAssert.requireValidApplicationId(applicationID);
    return GoogleCastDiscoveryCriteriaInitialize._(
      method: GoogleCastDiscoveryCriteriaInitMethod.initWithApplicationID,
      applicationID: applicationID,
    );
  }

  /// Initializes with a set of namespaces.
  factory GoogleCastDiscoveryCriteriaInitialize.initWithNamespaces(
    Set<String> namespaces,
  ) {
    _DiscoveryCriteriaAssert.requireValidNamespaces(namespaces);
    return GoogleCastDiscoveryCriteriaInitialize._(
      method: GoogleCastDiscoveryCriteriaInitMethod.initWithNamespaces,
      namespaces: namespaces,
    );
  }
}

class _DiscoveryCriteriaAssert {
  static void requireValidApplicationId(String applicationID) {
    assert(
      applicationID.trim().isNotEmpty,
      'initWithApplicationID requires a non-empty applicationID.',
    );
  }

  static void requireValidNamespaces(Set<String> namespaces) {
    assert(
      namespaces.isNotEmpty,
      'initWithNamespaces requires at least one namespace.',
    );
    assert(
      namespaces.every((namespace) => namespace.trim().isNotEmpty),
      'initWithNamespaces does not allow empty namespace values.',
    );
  }
}

/// Supported initialization methods for Google Cast discovery criteria.
enum GoogleCastDiscoveryCriteriaInitMethod {
  /// Initialize discovery criteria from a single application ID.
  initWithApplicationID,

  /// Initialize discovery criteria from a set of namespaces.
  initWithNamespaces,
}
