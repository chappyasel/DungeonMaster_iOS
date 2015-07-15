//
//  DPad.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/13/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "DPad.h"

@implementation DPad {
    //Display
    SKShapeNode *base;
    SKShapeNode *stick;
    // Touch handling
    BOOL isTouching;
    CFMutableDictionaryRef trackedTouches;
    //Calculation
    CGFloat joystickRadius;
    CGFloat joyStickRadiusSq;
}

- (instancetype)initWithRect:(CGRect)rect {
    if ((self = [super init])) {
        _velocity = CGPointZero;
        joystickRadius = rect.size.width/2;
        joyStickRadiusSq = joystickRadius*joystickRadius;
        // Touch handling
        trackedTouches = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        self.position = rect.origin;
        //Base
        base = [SKShapeNode node];
        base.fillColor = [UIColor grayColor];
        base.strokeColor = [UIColor clearColor];
        base.lineWidth = 0;
        base.path = CGPathCreateWithEllipseInRect(rect, NULL);
        base.alpha = 0.3;
        [self addChild:base];
        //Stick
        stick = [SKShapeNode node];
        stick.fillColor = [UIColor grayColor];
        stick.strokeColor = [UIColor clearColor];
        stick.lineWidth = 0;
        stick.path = CGPathCreateWithEllipseInRect(CGRectInset(rect,CGRectGetWidth(rect)/4, CGRectGetHeight(rect)/4), NULL);
        stick.alpha = 0.6;
        [self addChild:stick];
        // Enable touch
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)updateVelocity:(CGPoint)point {
    // Calculate the distance and angle from center
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat dS = x*x + y*y;
    if (dS <= 400) { //20
        _velocity = CGPointZero;
        [self updateStickPosition:point];
        return;
    }
    else if (dS <= joyStickRadiusSq) {
        _velocity = CGPointMake(x/joystickRadius, y/joystickRadius);
        [self updateStickPosition:point];
        return;
    }
    else { //past boundries
        CGFloat angle = atanf(y/x);
        int sign = (x < 0) ? -1 : 1;
        x = sign*cosf(angle)*joystickRadius;
        y = sign*sinf(angle)*joystickRadius;
        _velocity = CGPointMake(x/joystickRadius, y/joystickRadius);
        [self updateStickPosition:CGPointMake(x, y)];
        return;
    }
}

- (void)updateStickPosition:(CGPoint)point {
    stick.position = CGPointMake(point.x, point.y);
}

#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        // First determine if the touch is within the boundries of the DPad
        UITouch *touch = (UITouch *)obj;
        CGPoint location = [touch locationInNode:self];
        location = CGPointMake(location.x-joystickRadius, location.y-joystickRadius);
        if (!(location.x < -joystickRadius || location.x > joystickRadius ||
              location.y < -joystickRadius || location.y > joystickRadius)) {
            if (joyStickRadiusSq > location.x * location.x + location.y * location.y) {
                CFDictionarySetValue(trackedTouches, (__bridge void *)touch, (__bridge void *)touch);
                isTouching = YES;
                [self updateVelocity:location];
            }
        }
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (isTouching) {
        // Determine if any of the touches are one of those being tracked
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(trackedTouches, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch is being tracked
                CGPoint location = [touch locationInNode:self];
                location = CGPointMake(location.x-joystickRadius, location.y-joystickRadius);
                [self updateVelocity:location];
            }
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (isTouching) {
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(trackedTouches, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch was being tracked
                [self updateVelocity:CGPointZero];
                CFDictionaryRemoveValue(trackedTouches, (__bridge void *)touch);
            }
        }];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

@end
