//
//  SessionMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/06/22.
//

import Flutter
import Foundation

/// Flutter method channel for individual Google Cast session operations
/// 
/// This class handles method calls related to individual Cast session operations,
/// such as device-specific controls during an active session. It provides a
/// bridge between Flutter's session control API and the native Google Cast SDK
/// session functionality.
///
/// Key features:
/// - Individual session device controls
/// - Session-specific volume management
/// - Real-time session operation handling
/// - Extensible for additional session-level operations
///
/// This class complements the `FGCSessionManagerMethodChannel` by focusing on
/// operations that occur within an established session, rather than session
/// lifecycle management.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class FGCSessionMethodChannel: UIResponder, FlutterPlugin{
    
    // MARK: - Flutter Plugin Registration
    
    /// Registers the session method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for individual session operation communication.
    /// The channel name is "google_cast.session" and handles session-specific
    /// method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        _ = registrar
    }
}
