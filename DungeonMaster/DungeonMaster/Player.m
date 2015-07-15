//
//  Player.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/13/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Player.h"

@implementation Player

- (instancetype)initWithTexture:(SKTexture *)texture {
    if ((self = [super initWithTexture:texture])) {
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"images"];
        self.idleAnimationFrames = @[[atlas textureNamed:@"player_idle_0"],
                                           [atlas textureNamed:@"player_idle_1"]];
        self.walkAnimationFrames = @[[atlas textureNamed:@"player_walk_0"],
                                           [atlas textureNamed:@"player_walk_1"],
                                           [atlas textureNamed:@"player_walk_2"],
                                           [atlas textureNamed:@"player_walk_3"]];
        self.movementSpeed = 100;
    }
    return self;
}

@end
