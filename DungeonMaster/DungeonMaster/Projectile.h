//
//  Projectile.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Projectile : SKSpriteNode

@property (nonatomic) bool shouldDespawn;
@property (nonatomic) bool isVisible;
@property (nonatomic) bool isFlying;
//collision, positioning
@property (readonly, nonatomic) CGRect collisionRect;
@property (assign, nonatomic) CGPoint projectilePosition;

- (instancetype)initWithPosition:(CGPoint)pos velocity:(CGPoint)vel;

- (void)updateWithTimeInterval:(CFTimeInterval)tInterval;

- (void)applyMovements;

@end
