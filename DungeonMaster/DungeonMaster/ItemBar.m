//
//  itemBar.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "ItemBar.h"
#import "ItemSlot.h"
#import "Item.h"

@implementation ItemBar  {
    //Display
    SKShapeNode *base;
    NSMutableArray *itemSlots;
    //Touch tracking
    BOOL isTouching;
    CFMutableDictionaryRef trackedTouches;
}

- (instancetype)initWithRect:(CGRect)rect {
    if ((self = [super init])) {
        // Touch handling
        trackedTouches = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        self.position = rect.origin;
        //Base
        base = [SKShapeNode node];
        base.fillColor = [UIColor lightGrayColor];
        base.strokeColor = [UIColor blackColor];
        base.lineWidth = 1;
        base.path = CGPathCreateWithRect(CGRectMake(0, 0, rect.size.width, rect.size.height), NULL);
        base.alpha = 0.8;
        [self addChild:base];
        //Presets
        _slotSelected = NO;
        //Slots
        itemSlots = [[NSMutableArray alloc] init];
        for (int i = 0; i < 5; i++) {
            float c = rect.size.width/5;
            ItemSlot *itemSlot = [[ItemSlot alloc] initWithRect:CGRectMake(i*c+(c-40)/2, 10, 40, 40)];
            itemSlot.index = i;
            [itemSlots addObject:itemSlot];
            [base addChild:itemSlot];
        }
        //Enable touch
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)slotTouched:(int)slot {
    _slotSelected = YES;
    _selectedItem = [self itemAtIndex:slot];
}

- (void)setItem:(Item *)item AtIndex:(int)index {
    ((ItemSlot *)itemSlots[index]).item = item;
}

#pragma mark - public methods

- (Item *)itemAtIndex:(int)index {
    return ((ItemSlot *)itemSlots[index]).item;
}

- (BOOL)addItem:(Item *) item {
    for (int i = 0; i < itemSlots.count; i++) {
        if ([self itemAtIndex:i].itemType == ItemTypeInvalid) {
            [self setItem:item AtIndex:i];
            return YES;
        }
    }
    return NO;
}

#pragma mark - touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        // First determine if the touch is within the boundries of the DPad
        UITouch *touch = (UITouch *)obj;
        CFDictionarySetValue(trackedTouches, (__bridge void *)touch, (__bridge void *)touch);
        isTouching = YES;
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch *) CFDictionaryGetValue(trackedTouches, (__bridge void *)(UITouch *)obj);
        if (touch != NULL) { // This touch is being tracked
            CGPoint location = [touch locationInNode:base];
            for (ItemSlot *s in itemSlots) {
                if([s containsPoint:location]) [self slotTouched:s.index];
            }
        }
    }];
    if (isTouching) {
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(trackedTouches, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) CFDictionaryRemoveValue(trackedTouches, (__bridge void *)touch);
        }];
    }
}

@end
