//
//  SDLDialNumberResponse.h
//  SmartDeviceLink-iOS

#import <SmartDeviceLink/SmartDeviceLink.h>

/**
 Indicates the result, success, or failure of the SDLDialNumber request.
 
 @since SDL 4.0
 */
@interface SDLDialNumberResponse : SDLRPCResponse

- (instancetype)init;
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

@end
