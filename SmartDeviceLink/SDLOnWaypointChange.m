//  SDLOnWaypointChange.m
//

#import "SDLOnWaypointChange.h"

#import "SDLNames.h"

@implementation SDLOnWaypointChange

- (instancetype)init {
    if (self = [super initWithName:SDLNameOnWaypointChange]) {
    }
    return self;
}

- (void)setWaypoints:(NSArray<SDLLocationDetails *> *)waypoints {
    if (waypoints != nil) {
        parameters[SDLNameWaypoints] = waypoints;
    } else {
        [parameters removeObjectForKey:SDLNameWaypoints];
    }
}

- (NSArray<SDLLocationDetails *> *)waypoints {
    return parameters[SDLNameWaypoints];
}

@end