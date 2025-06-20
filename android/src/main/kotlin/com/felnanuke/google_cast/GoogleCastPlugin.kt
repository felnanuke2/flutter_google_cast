package com.felnanuke.google_cast

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Main Google Cast plugin for Android implementation
 * 
 * This class serves as the primary entry point for the Flutter Google Cast plugin on Android.
 * It implements the FlutterPlugin interface to integrate with the Flutter framework and
 * coordinates the initialization of all Cast-related method channels.
 *
 * The plugin manages:
 * - Flutter plugin lifecycle (attachment/detachment)
 * - Registration of specialized method channels for Cast features
 * - Integration with the Google Cast SDK for Android
 * - Coordination between different Cast functionality components
 *
 * Architecture:
 * The main plugin acts as a coordinator, delegating specific Cast operations to
 * specialized method channels:
 * - CastContextMethodChannel: Handles Cast context initialization and configuration
 * - DiscoveryManagerMethodChannel: Manages device discovery operations
 * - SessionManagerMethodChannel: Controls Cast session lifecycle
 * - RemoteMediaClientMethodChannel: Handles media playback operations
 *
 * The plugin follows Android's component lifecycle patterns and ensures proper
 * resource management when the Flutter engine is attached or detached.
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class GoogleCastPlugin : FlutterPlugin, MethodCallHandler {
    
    /**
     * Flutter method channel for basic plugin communication
     * 
     * This channel handles general plugin operations and serves as the main
     * communication bridge between Flutter and the native Android implementation.
     * It's primarily used for plugin lifecycle management and basic queries.
     */
    private lateinit var channel: MethodChannel
    
    /**
     * Cast context method channel for Google Cast SDK operations
     * 
     * This specialized channel handles all Cast context-related operations,
     * including SDK initialization, configuration, and context management.
     * It's automatically initialized and managed by this main plugin class.
     */
    private val castContextMethodChannel = CastContextMethodChannel()

    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     * 
     * This method is invoked by the Flutter framework when the plugin is being
     * initialized. It sets up all necessary method channels and prepares the
     * plugin for communication with the Flutter side.
     *
     * Setup operations performed:
     * - Creates the main method channel for plugin communication
     * - Registers this class as the method call handler
     * - Initializes and attaches the Cast context method channel
     * - Prepares all Cast SDK integration components
     *
     * @param flutterPluginBinding The binding that provides access to Flutter engine resources
     */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "google_cast")
        channel.setMethodCallHandler(this)
        castContextMethodChannel.onAttachedToEngine(flutterPluginBinding)
    }

    /**
     * Handles method calls from the Flutter side
     * 
     * Processes incoming method calls from Flutter and routes them to appropriate
     * handlers. The main plugin currently handles basic platform queries, while
     * Cast-specific operations are delegated to specialized method channels.
     *
     * Supported methods:
     * - `getPlatformVersion`: Returns the current Android version information
     *
     * @param call The method call from Flutter containing method name and arguments
     * @param result The result callback to return responses or errors to Flutter
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Called when the Flutter plugin is detached from the Flutter engine
     * 
     * This method is invoked by the Flutter framework when the plugin is being
     * cleaned up. It ensures proper resource cleanup and prevents memory leaks
     * by removing method call handlers and releasing resources.
     *
     * Cleanup operations performed:
     * - Removes the method call handler from the main channel
     * - Allows garbage collection of plugin resources
     * - Ensures no lingering references that could cause memory leaks
     *
     * @param binding The Flutter plugin binding being detached
     */
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
