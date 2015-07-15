//
//  itemBar.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class Item;

@interface ItemBar : SKNode

@property (nonatomic) bool slotSelected;
@property (nonatomic) Item *selectedItem;

- (instancetype)initWithRect:(CGRect)rect;

- (Item *)itemAtIndex:(int)index;
- (BOOL)addItem:(Item *) item;

@end
