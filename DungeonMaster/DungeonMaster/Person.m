//
//  Person.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/15/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Person.h"

@implementation Person

- (instancetype)initWithTexture:(SKTexture *)texture {
    if ((self = [super initWithTexture:texture])) {
        self.personPosition = self.position;
        self.pathFindQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (CGRect)collisionRect {
    return CGRectMake(self.personPosition.x - (CGRectGetWidth(self.frame)/2),
                      self.personPosition.y - (CGRectGetHeight(self.frame)/2),
                      self.frame.size.width, self.frame.size.height);
}

- (void)resolveAnimationWithID:(NSUInteger)animationID {
    NSString *animationKey = nil;
    NSArray *animationFrames = nil;
    CGFloat animationSpeed = 0;
    switch (animationID) {
        case 0: // Idle
            animationKey = @"anim_idle";
            animationFrames = self.idleAnimationFrames;
            animationSpeed = 20;
            break;
        default: // Walk
            animationKey = @"anim_walk";
            animationFrames = self.walkAnimationFrames;
            animationSpeed = 5;
            break;
    }
    SKAction *animAction = [self actionForKey:animationKey];
    // If this animation is already running or there are no frames we exit
    if (animAction || [animationFrames count] < 1) return;
    animAction = [SKAction animateWithTextures:animationFrames timePerFrame:animationSpeed/60.0f resize:YES restore:NO];
    [self runAction:animAction withKey:animationKey];
}

@end
