//
//  ItemSlot.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class Item;

@interface ItemSlot : SKNode

@property int index;
@property (retain, nonatomic) Item *item;

- (instancetype)initWithRect:(CGRect)rect;

@end
