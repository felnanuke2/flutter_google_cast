#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_cast.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast'
  s.version          = '1.2.6'
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

  # IMPORTANT: Architecture configuration for iOS Simulator builds
  # 
  # Google Cast SDK (version 4.7.0+) supports both Intel and Apple Silicon simulators.
  # We only exclude i386 as it's truly deprecated and no longer supported.
  # 
  # - i386: 32-bit Intel architecture (deprecated since iOS 11)
  # - x86_64: 64-bit Intel architecture (for Intel Mac simulators)
  # - arm64: Apple Silicon architecture (for M1/M2/M3 Mac simulators and devices)
  #
  # This configuration allows building for both Intel (x86_64) and Apple Silicon (arm64)
  # simulators, as well as arm64 devices.
  s.pod_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
    'DEFINES_MODULE' => 'YES'
  }
  s.user_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES'
  }

  s.swift_version = '5.0'
end
