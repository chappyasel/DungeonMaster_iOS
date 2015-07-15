//
//  DPad.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/13/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface DPad : SKNode

@property (assign, nonatomic, readonly) CGPoint velocity;

- (instancetype)initWithRect:(CGRect)rect;

@end
