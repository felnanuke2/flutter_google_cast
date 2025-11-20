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

  # IMPORTANT: Architecture exclusion for iOS Simulator builds
  # 
  # The Google Cast SDK (versions 4.7.x - 4.8.x) contains pre-compiled binaries that only
  # include device architectures (arm64 for iOS devices). When building for simulator,
  # the SDK's arm64 slice is for devices, not simulators, causing linker errors:
  # "Building for 'iOS-simulator', but linking in object file built for 'iOS'"
  #
  # This exclusion forces simulator builds to use x86_64 architecture (Intel),
  # which works on both Intel Macs natively and Apple Silicon Macs via Rosetta 2.
  #
  # Excluded architectures:
  # - arm64: Excluded for simulator to avoid linking device binaries
  # - i386: 32-bit architecture, deprecated since iOS 11
  #
  # CI/CD Note: Apple Silicon runners must use arch -x86_64 or similar to build x86_64
  s.pod_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
    'DEFINES_MODULE' => 'YES'
  }
  s.user_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES'
  }

  s.swift_version = '5.0'
end
