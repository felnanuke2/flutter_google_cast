#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_chrome_cast_ios.podspec` to validate before publishing.
#
# This plugin supports both CocoaPods (this file) and Swift Package Manager (Package.swift).
# For SPM support, see flutter_chrome_cast/Package.swift.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast_ios'
  s.version          = '1.4.4'
  s.summary          = 'iOS implementation of the flutter_chrome_cast plugin.'
  s.description      = <<-DESC
Flutter Google Cast iOS platform implementation.
This pod contains the native iOS bridge used by the federated flutter_chrome_cast plugin.
                       DESC
  s.homepage         = 'https://github.com/felnanuke2/flutter_google_cast'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luiz Felipe Alves Lima' => 'https://github.com/felnanuke2' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_chrome_cast/Sources/flutter_chrome_cast/**/*.swift'
  s.exclude_files    = 'flutter_chrome_cast/Sources/flutter_chrome_cast/GoogleCastPlugin.h', 'flutter_chrome_cast/Sources/flutter_chrome_cast/GoogleCastPlugin.m'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.ios.deployment_target = '15.0'
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
