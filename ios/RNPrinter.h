
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface RNPrinter : NSObject <RCTBridgeModule>

@property(nonatomic, assign) BOOL isPrinting;

@end
  
