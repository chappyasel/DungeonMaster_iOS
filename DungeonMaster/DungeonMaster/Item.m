//
//  Item.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Item.h"

@implementation Item

- (instancetype)initWithTexture:(SKTexture *)texture {
    if ((self = [super initWithTexture:texture])) {
        self.itemType = ItemTypeInvalid;
    }
    return self;
}

@end
