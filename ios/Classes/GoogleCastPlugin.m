#import "GoogleCastPlugin.h"
#if __has_include(<google_cast/google_cast-Swift.h>)
#import <google_cast/google_cast-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "google_cast-Swift.h"
#endif

@implementation GoogleCastPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGoogleCastPlugin registerWithRegistrar:registrar];
}
@end
