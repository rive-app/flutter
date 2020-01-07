#import "CursorPlugin.h"
#if __has_include(<cursor/cursor-Swift.h>)
#import <cursor/cursor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cursor-Swift.h"
#endif

@implementation CursorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCursorPlugin registerWithRegistrar:registrar];
}
@end
