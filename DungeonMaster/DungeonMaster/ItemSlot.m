//
//  ItemSlot.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "ItemSlot.h"
#import "Item.h"

@implementation ItemSlot {
    SKShapeNode *slot;
}

- (instancetype)initWithRect:(CGRect)rect {
    if ((self = [super init])) {
        self.position = CGPointMake(rect.origin.x, rect.origin.y);
        //background
        slot = [SKShapeNode node];
        slot.fillColor = [UIColor lightGrayColor];
        slot.strokeColor = [UIColor blackColor];
        slot.lineWidth = 1;
        slot.path = CGPathCreateWithRect(CGRectMake(0, 0, rect.size.width, rect.size.height), NULL);
        [self addChild:slot];
        //item display
        self.item = [[Item alloc] initWithTexture:nil];
    }
    return self;
}

- (BOOL)containsPoint:(CGPoint)p {
    return CGRectContainsPoint(CGRectMake(self.position.x, self.position.y, 40, 40), p);
}

- (void)setItem:(Item *)item {
    _item = item;
    _item.position = CGPointMake(20, 20);
    _item.size = CGSizeMake(40, 40);
    [self addChild:_item];
}

@end
