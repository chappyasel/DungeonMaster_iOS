//
//  Dungeon.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/14/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class DungeonCell;

@interface Dungeon : SKNode

// Texture atlas
@property (strong, nonatomic, readonly) SKTextureAtlas *atlas;

// Info
@property (assign, nonatomic, readonly) CGSize gridSize;
@property (assign, nonatomic, readonly) CGSize tileSize;

// Properties
@property (assign, nonatomic, readonly) CGFloat chanceToBecomeWall;
@property (assign, nonatomic) int numberOfCleanups;
@property (assign, nonatomic) int floorsToWallChance;
@property (assign, nonatomic) int wallsToFloorChance;
@property (assign, nonatomic) CGSize dungeonGenSize; //size of dungeons
@property (assign, nonatomic) bool removeExtraWalls; //clean up extra walls

// Initializes a new instance of the cave class with a given texture atlas and grid size
- (instancetype)initWithAtlasNamed:(NSString *)name;
- (instancetype)initWithAtlasNamed:(NSString *)name fileName:(NSString *)fileName;

- (DungeonCell *)caveCellFromGridCoordinate:(CGPoint)coordinate;
- (CGPoint)gridCoordinateForPosition:(CGPoint)position;
- (CGPoint)positionForGridCoordinate:(CGPoint) coordinate;
- (CGRect)rectFromGridCoordinate:(CGPoint)coordinate;
- (BOOL)isValidSpawnGridCoordinate:(CGPoint)coordinate;
- (NSMutableArray *)pathFindFromGridCoordinate:(CGPoint) c1 toCoordinate:(CGPoint) c2 maxLoops:(int)maxLoops;
- (void)openChestAtGridCoordinate:(CGPoint)coordinate;

@end
