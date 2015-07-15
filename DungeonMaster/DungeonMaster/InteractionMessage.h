//
//  InteractionMessage.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/18/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface InteractionMessage : SKNode

@property (nonatomic) bool touched;

- (instancetype)initWithRect:(CGRect)rect;

@end
