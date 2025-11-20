#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_cast.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast'
  s.version          = '1.2.6'
  s.summary          = 'A comprehensive Flutter plugin for Google Cast SDK integration on iOS and Android.'
  s.description      = <<-DESC
FlutterGoogleCast provides seamless integration with the Google Cast SDK for Flutter applications.
Discover, connect to, and control Chromecast devices and other Google Cast-enabled receivers with
full support for media streaming, playback controls, queue management, and real-time status updates.
                       DESC
  s.homepage         = 'https://github.com/felnanuke2/flutter_google_cast'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luiz Felipe Alves Lima' => 'https://github.com/felnanuke2' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.ios.deployment_target  = '12.0'
  s.dependency 'google-cast-sdk', '~> 4.8'
  s.dependency 'Protobuf'
  s.static_framework = true

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'SWIFT_INCLUDE_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/Classes',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }

  s.user_target_xcconfig = {
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }

  s.swift_version = '5.0'
end
