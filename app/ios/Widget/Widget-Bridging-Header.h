// Exposes the shared Rust core's C API (core/include/vnaddr.h, ADR 0002 §9)
// to this target's Swift code. Set as this target's
// "Objective-C Bridging Header" build setting once the real Xcode project
// exists (see app/ios/README.md).
#import "vnaddr.h"
