//
//  DiscoveryManagerMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Foundation
import GoogleCast

/// Flutter method channel for Google Cast device discovery operations
/// 
/// This class manages the discovery of Google Cast devices on the local network.
/// It implements the Google Cast discovery manager listener protocol to receive
/// updates about Cast device availability and communicates these updates back
/// to the Flutter side via method channels.
///
/// Key features:
/// - Automatic device discovery management
/// - Real-time device list updates to Flutter
/// - Device indexing for Flutter-side device selection
/// - Singleton pattern for consistent state management
///
/// The class maintains a dictionary of discovered devices indexed by their
/// discovery position, enabling Flutter to reference devices by index when
/// initiating Cast sessions.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class FGCDiscoveryManagerMethodChannel : UIResponder, GCKDiscoveryManagerListener, FlutterPlugin{
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = FGCDiscoveryManagerMethodChannel.init()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared FGCDiscoveryManagerMethodChannel instance
    static var instance : FGCDiscoveryManagerMethodChannel {
        _instance
    }
    
    // MARK: - Properties
    
    /// Reference to the Google Cast discovery manager
    /// - Returns: The discovery manager from the shared Cast context
    private var discoveryManager: GCKDiscoveryManager{
        GCKCastContext.sharedInstance().discoveryManager
    }
    
    /// Dictionary storing discovered Cast devices indexed by their discovery position
    /// The key represents the device index in the discovery list, and the value
    /// is the corresponding GCKDevice object
    var devices : [UInt : GCKDevice] = [:]
    
    /// Flutter method channel for communicating device discovery events
    /// Used to send device list updates back to the Flutter side
    var channel : FlutterMethodChannel?
    
    // MARK: - Flutter Plugin Registration
    
    /// Registers the discovery manager method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for device discovery communication.
    /// The channel name is "google_cast.discovery_manager" and handles
    /// device discovery related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        
        instance.channel = FlutterMethodChannel.init(name: "google_cast.discovery_manager", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        
    }
    
    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// Currently, this class primarily operates through the discovery manager
    /// listener callbacks rather than explicit method calls. The discovery
    /// process is started automatically when the Cast context is initialized.
    ///
    /// - Parameters:
    ///   - call: The Flutter method call
    ///   - result: Callback to return results to Flutter
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Most discovery operations are handled automatically
        // Additional methods can be added here as needed
    }
    
    // MARK: - Google Cast Discovery Manager Listener
    
    /// Called when a Cast device is updated in the discovery list
    /// 
    /// This method is invoked by the Cast SDK when an existing device's
    /// information is updated (e.g., name change, capability updates).
    ///
    /// - Parameters:
    ///   - device: The updated Cast device
    ///   - index: The index position of the device in the discovery list
    public func didUpdate(_ device: GCKDevice, at index: UInt) {
        devices[index] = device
    }
    
    /// Called when a new Cast device is discovered
    /// 
    /// This method is invoked when a new Cast device becomes available
    /// on the network. The device is added to the internal devices dictionary.
    ///
    /// - Parameters:
    ///   - device: The newly discovered Cast device
    ///   - index: The index position assigned to the device
    public func didInsert(_ device: GCKDevice, at index: UInt) {
        devices[index] = device
    }
    
    /// Called when a Cast device is removed from discovery
    /// 
    /// This method is invoked when a Cast device is no longer available
    /// (e.g., device goes offline, network changes). The device is removed
    /// from the internal devices dictionary.
    ///
    /// - Parameters:
    ///   - device: The Cast device that was removed
    ///   - index: The index position of the removed device
    public func didRemove(_ device: GCKDevice, at index: UInt) {
        devices.removeValue(forKey: index)
    }
    
    /// Called when the device list changes
    /// 
    /// This method is invoked whenever there are changes to the discovery
    /// device list. It sends the updated device list to Flutter via the
    /// method channel, allowing the Flutter side to update its UI accordingly.
    ///
    /// The device list is sorted by index and converted to a format suitable
    /// for Flutter consumption, with each device represented as a dictionary
    /// containing device information and its discovery index.
    public func didUpdateDeviceList() {
        
        channel!.invokeMethod("onDevicesChanged" , arguments: devices.sorted{
            a,b in
            return a.key > b.key
        }.map{
            device in
            var dict =  device.value.toDict()
            dict["index"] = device.key
            return dict
        })
    }
    
}
