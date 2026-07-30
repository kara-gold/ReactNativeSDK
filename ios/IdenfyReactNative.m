#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(IdenfyReactNative, RCTEventEmitter)

RCT_EXTERN_METHOD(
    start:(NSDictionary *)config
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject
)

RCT_EXTERN_METHOD(
    startFaceReAuth:(NSDictionary *)config
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject
)

RCT_EXTERN_METHOD(
    startRequestUpdate:(NSDictionary *)config
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject
)

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
