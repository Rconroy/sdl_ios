//
//  CGPoint_Util.c
//  SmartDeviceLink-iOS
//
//  Created by Muller, Alexander (A.) on 6/14/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#include "CGPoint_Util.h"
#include "math.h"

CGPoint CGPointAverageOfPoints(CGPoint point1, CGPoint point2) {
    CGFloat xAverage = (point1.x + point2.x)/2.0f;
    CGFloat yAverage = (point1.y + point2.y)/2.0f;
    return CGPointMake(xAverage, yAverage);
}

CGPoint CGPointCenterOfPoints(CGPoint point1, CGPoint point2) {
    CGFloat xCenter = (point1.x + point2.x) / 2.0f;
    CGFloat yCenter = (point1.y + point2.y) / 2.0f;
    return CGPointMake(xCenter, yCenter);
}

CGPoint CGPointDisplacementOfPoints(CGPoint point1, CGPoint point2) {
    CGFloat xDisplacement = point1.x - point2.x;
    CGFloat yDisplacement = point1.y - point2.y;
    return CGPointMake(xDisplacement, yDisplacement);
}

CGFloat CGPointDistanceBetweenPoints(CGPoint point1, CGPoint point2) {
    return hypotf(point1.x - point2.x, point1.y - point2.y);
}