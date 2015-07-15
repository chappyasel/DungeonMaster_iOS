//
//  DungeonCell.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/14/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, CaveCellType) {
    CaveCellTypeInvalid = -1,
    CaveCellTypeWall,
    CaveCellTypeFloor,
    CaveCellTypeDungeonWall,
    CaveCellTypeDungeonFloor,
    CaveCellTypeDungeonFloorFire,
    CaveCellTypeDungeonFloorChest,
    CaveCellTypeMax
};

@interface DungeonCell : NSObject

@property (assign, nonatomic) CGPoint coordinate;
@property (assign, nonatomic) CaveCellType type;
@property (assign, nonatomic) bool canWalkOn;

- (instancetype)initWithCoordinate:(CGPoint)coordinate;

@end
