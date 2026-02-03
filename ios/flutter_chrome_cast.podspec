#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_cast.podspec` to validate before publishing.
#
# This plugin supports both CocoaPods (this file) and Swift Package Manager (Package.swift).
# For SPM support, see Package.swift in this same directory.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast'
  s.version          = '1.2.6'
  s.summary          = 'A comprehensive Flutter plugin for Google Cast SDK integration on iOS and Android.'
  s.description      = <<-DESC
FlutterGoogleCast provides seamless integration with the Google Cast SDK for Flutter applications.
Discover, connect to, and control Chromecast devices and other Google Cast-enabled receivers with
full support for media streaming, playback controls, queue management, and real-time status updates.

This plugin supports both CocoaPods and Swift Package Manager (SPM) for iOS dependency management.
                       DESC
  s.homepage         = 'https://github.com/felnanuke2/flutter_google_cast'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luiz Felipe Alves Lima' => 'https://github.com/felnanuke2' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.ios.deployment_target  = '15.0'
  s.dependency 'google-cast-sdk', '~> 4.8'
  s.dependency 'Protobuf'
  s.static_framework = true

  s.pod_target_xcconfig = { 
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
    'DEFINES_MODULE' => 'YES'
  }
  s.user_target_xcconfig = { 
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES'
  }

  s.swift_version = '5.0'
end
