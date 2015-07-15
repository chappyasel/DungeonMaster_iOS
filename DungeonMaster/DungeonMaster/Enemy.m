//
//  Enemy.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/16/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Enemy.h"

@implementation Enemy

- (instancetype)initWithTexture:(SKTexture *)texture {
    if ((self = [super initWithTexture:texture])) {
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"images"];
        self.idleAnimationFrames = @[[atlas textureNamed:@"enemy_idle_0"],
                                           [atlas textureNamed:@"enemy_idle_1"]];
        self.walkAnimationFrames = @[[atlas textureNamed:@"enemy_walk_0"],
                                           [atlas textureNamed:@"enemy_walk_1"],
                                           [atlas textureNamed:@"enemy_walk_2"],
                                           [atlas textureNamed:@"enemy_walk_3"]];
        self.movementSpeed = 30+arc4random()%50;
    }
    return self;
}

@end
