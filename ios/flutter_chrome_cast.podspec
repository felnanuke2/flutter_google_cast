#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_cast.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast'
  s.version          = '0.0.2'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.ios.deployment_target  = '12.0'
  s.dependency 'google-cast-sdk', '~> 4.7'
  s.dependency 'Protobuf'
  s.static_framework = true 

  # IMPORTANT: Architecture exclusion for iOS Simulator builds
  # 
  # The Google Cast SDK (version 4.7.0) contains pre-compiled binaries that cause
  # linking errors when building for iOS Simulator on Apple Silicon Macs.
  # Error: "Building for 'iOS-simulator', but linking in object file built for 'iOS'"
  #
  # This exclusion prevents the linker from trying to use arm64 binaries when
  # building for the simulator, which requires x86_64 architecture.
  #
  # Note: This only affects simulator builds - real device builds work correctly.
  # This workaround should be removed once Google releases a Cast SDK version
  # that fully supports Apple Silicon simulators.
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.swift_version = '5.0'
end
