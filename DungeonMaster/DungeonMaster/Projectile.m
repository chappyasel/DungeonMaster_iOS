//
//  Projectile.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Projectile.h"

@implementation Projectile {
    CGFloat height; //in seconds
    CGPoint velocity;
    CGFloat despawnTime; //in seconds
    SKSpriteNode *shadow;
}

- (instancetype)initWithPosition:(CGPoint)pos velocity:(CGPoint)vel {
    if (self = [super initWithTexture:[[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"arrow_0"]]) {
        self.position = pos;
        shadow = [[SKSpriteNode alloc] initWithTexture:[[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"shadow"]];
        shadow.xScale = 0.8;
        shadow.yScale = 0.4;
        //[self addChild:shadow];
        velocity = vel;
        height = 1;
        despawnTime = 10;
        self.shouldDespawn = NO;
        self.isVisible = NO;
        self.isFlying = YES;
        CGFloat angle = atan2f(vel.y,vel.x);
        self.zRotation = angle;
        shadow.zRotation = -angle;
    }
    return self;
}

- (CGRect)collisionRect {
    return CGRectMake(self.projectilePosition.x - (CGRectGetWidth(self.frame)/2),
                      self.projectilePosition.y - (CGRectGetHeight(self.frame)/2),
                      self.frame.size.width, self.frame.size.height);
}

- (void)updateWithTimeInterval:(CFTimeInterval)tInterval {
    if (height > 0) {
        self.projectilePosition = CGPointMake(self.position.x+velocity.x*tInterval*1.5,self.position.y+velocity.y*tInterval*1.5);
        height -= tInterval;
        //self.xScale = 1+height/3;
        //self.yScale = 1+height/3;
        shadow.alpha = 0.6-height/2;
        shadow.position = CGPointMake(0, 2-height*10);
    }
    despawnTime -= tInterval;
    if (despawnTime <= 0) {
        self.shouldDespawn = YES;
    }
}

- (void)applyMovements {
    self.position = self.projectilePosition;
}

@end
