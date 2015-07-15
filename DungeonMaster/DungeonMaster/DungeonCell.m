//
//  DungeonCell.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/14/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "DungeonCell.h"

@implementation DungeonCell

- (instancetype)initWithCoordinate:(CGPoint)coordinate {
    if ((self = [super init])) {
        _coordinate = coordinate;
        _type = CaveCellTypeInvalid;
    }
    return self;
}

- (BOOL)canWalkOn {
    if (self.type == CaveCellTypeDungeonWall ||
        self.type == CaveCellTypeWall) return NO;
    return YES;
}

@end
