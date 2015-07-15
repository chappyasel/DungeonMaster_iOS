//
//  Person.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/15/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Person : SKSpriteNode

//properties
@property (nonatomic) CGFloat movementSpeed;

//position, collision
@property (assign, nonatomic) CGPoint velocity;
@property (assign, nonatomic) CGPoint personPosition;
@property (readonly, nonatomic) CGRect collisionRect;

//pathfind
@property (nonatomic) NSMutableArray *pathFindQueue;

//animation
@property (copy, nonatomic) NSArray *idleAnimationFrames;
@property (copy, nonatomic) NSArray *walkAnimationFrames;
@property (assign, nonatomic) NSUInteger animationID;//0=idle 1=walk

- (void) resolveAnimationWithID:(NSUInteger)animationID;

@end
