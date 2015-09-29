//  SDLSoftButtonWithHandler.h
//  Copyright (c) 2015 Ford Motor Company. All rights reserved.

#import "SDLSoftButton.h"
#import "SDLManagerDelegate.h"

@interface SDLSoftButtonWithHandler : SDLSoftButton

@property (copy) SDLRPCNotificationHandler onButtonHandler;

@end