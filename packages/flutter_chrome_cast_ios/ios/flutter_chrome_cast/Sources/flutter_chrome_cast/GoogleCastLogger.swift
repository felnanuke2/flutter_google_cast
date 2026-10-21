import Foundation

/// Log levels shared with the Dart logging API.
enum FlutterGoogleCastLogLevel: String {
    case none
    case error
    case warning
    case info
    case verbose

    var rank: Int {
        switch self {
        case .none: return 0
        case .error: return 1
        case .warning: return 2
        case .info: return 3
        case .verbose: return 4
        }
    }
}

/// Central logger for messages emitted by the iOS side of this plugin.
enum FlutterGoogleCastLogger {
    /// `nil` means that the app did not opt in and legacy output is retained.
    private(set) static var configuredLevel: FlutterGoogleCastLogLevel?

    static func configure(_ wireValue: String?) {
        configuredLevel = wireValue.flatMap(FlutterGoogleCastLogLevel.init(rawValue:))
    }

    static func error(_ message: @autoclosure () -> String) {
        log(.error, message())
    }

    static func warning(_ message: @autoclosure () -> String) {
        log(.warning, message())
    }

    static func info(_ message: @autoclosure () -> String) {
        log(.info, message())
    }

    static func verbose(_ message: @autoclosure () -> String) {
        log(.verbose, message())
    }

    static func log(
        _ messageLevel: FlutterGoogleCastLogLevel,
        _ message: @autoclosure () -> String
    ) {
        if let selectedLevel = configuredLevel,
           selectedLevel == .none || messageLevel.rank > selectedLevel.rank {
            return
        }

        print(message())
    }
}
