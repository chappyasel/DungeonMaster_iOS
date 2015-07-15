//
//  Dungeon.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/14/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Dungeon.h"
#import "DungeonCell.h"

@interface PathFindNode : NSObject
    @property CGPoint coordinate;
    @property int cost;
    @property PathFindNode *parentNode;
    +(id)node;
@end
@implementation PathFindNode
    +(id)node { return [[PathFindNode alloc] init]; }
@end

@interface Dungeon ()
    @property (strong, nonatomic) NSMutableArray *grid;
    @property (strong, nonatomic) NSMutableArray *caverns;
    @property (strong, nonatomic) NSMutableArray *walls;
    @property (strong, nonatomic) NSMutableArray *sectorCount;
@end

@implementation Dungeon

# pragma mark - initialization

- (instancetype)initWithAtlasNamed:(NSString *)name {
    if ((self = [super init])) {
        _atlas = [SKTextureAtlas atlasNamed:name];
        _tileSize = [self determineSizeOfTiles];
        //GENERATION OF DUNGEON
        [self generate];
    }
    return self;
}

- (instancetype)initWithAtlasNamed:(NSString *)name fileName:(NSString *)fileName {
    if ((self = [super init])) {
        _atlas = [SKTextureAtlas atlasNamed:name];
        _tileSize = [self determineSizeOfTiles];
        //GENERATION OF DUNGEON
        [self initializeGridWithFileName:fileName];
    }
    return self;
}

- (void)generate {
    _chanceToBecomeWall = 0.45;
    _numberOfCleanups = 2;
    _floorsToWallChance = 4;
    _wallsToFloorChance = 3;
    
    _dungeonGenSize = CGSizeMake(4, 4);
    _gridSize = CGSizeMake(64, 64);
    _removeExtraWalls = NO;
    
    srandom((int)time(0));
    [self initializeGrid];
    for (int i = 0; i < self.numberOfCleanups; i++) [self cleanupDungeon];
    [self identifyCaverns];
    [self removeDisconnectedCaverns];
    if (_removeExtraWalls) {
        [self countWalls];
        [self removeDisconnectedWalls];
    }
    if ((int)self.gridSize.width % (int)_dungeonGenSize.width != 0 ||
        (int)self.gridSize.height % (int)_dungeonGenSize.height != 0) NSLog(@"Height, Width invalid, skipping generation");
    else {
        [self countSectors];
        [self spawnDungeons];
    }
    [self generateTiles];
}

- (void)initializeGridWithFileName:(NSString *)fileName {
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName
                                                     ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    if (content) {
        NSArray *allLinedStrings = [content componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
        _gridSize.height = allLinedStrings.count+2;
        _gridSize.width = [allLinedStrings[0] componentsSeparatedByString:@" "].count+2;
        self.grid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
        for (int y = 0; y < (int)_gridSize.height; y++) {
            NSArray *cellsX;
            if (y != 0 && y != _gridSize.height-1) cellsX = [allLinedStrings[y-1] componentsSeparatedByString:@" "];
            NSMutableArray *row = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
            for (int x = 0; x < (int)_gridSize.width; x++) {
                CGPoint coordinate = CGPointMake(x, y);
                DungeonCell *cell = [[DungeonCell alloc] initWithCoordinate:coordinate];
                if ([self isEdgeAtGridCoordinate:coordinate]) cell.type = CaveCellTypeWall;
                else {
                    NSString *eval = cellsX[x-1];
                    if ([eval isEqualToString:@"."]) cell.type = CaveCellTypeFloor;
                    else if ([eval isEqualToString:@","]) cell.type = CaveCellTypeDungeonFloor;
                    else if ([eval isEqualToString:@"W"]) cell.type = CaveCellTypeWall;
                    else if ([eval isEqualToString:@"D"]) cell.type = CaveCellTypeDungeonWall;
                    else if ([eval isEqualToString:@"+"]) cell.type = CaveCellTypeDungeonFloorFire;
                    else cell.type = CaveCellTypeInvalid;
                }
                [row addObject:cell];
            }
            [self.grid addObject:row];
        }
        [self generateTiles];
    }
    else {
        NSLog(@"error loading map, regular gen initiating...");
        [self generate];
    }
}

- (void)initializeGrid {
    self.grid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CGPoint coordinate = CGPointMake(x, y);
            DungeonCell *cell = [[DungeonCell alloc] initWithCoordinate:coordinate];
            if ([self isEdgeAtGridCoordinate:coordinate]) cell.type = CaveCellTypeWall;
            else {
                if ((random()/(float)0x7fffffff)<_chanceToBecomeWall) cell.type = CaveCellTypeWall;
                else cell.type = CaveCellTypeFloor;
            }
            [row addObject:cell];
        }
        [self.grid addObject:row];
    }
}

# pragma mark - visual

- (void)generateTiles {
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            DungeonCell *cell = [self caveCellFromGridCoordinate:CGPointMake(x, y)];
            SKSpriteNode *node;
            SKEmitterNode *emitter;
            switch (cell.type) {
                case CaveCellTypeWall: {
                    int rand = arc4random()%3;
                    if (rand == 0) node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_wall_0"]];
                    else if (rand == 1) node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_wall_1"]];
                    else node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_wall_2"]];
                    break;
                }
                case CaveCellTypeFloor: {
                    int rand = arc4random()%100;
                    if (rand == 0) node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_floor_2"]];
                    else if (rand < 10) node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_floor_1"]];
                    else node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_floor_0"]];
                    break;
                }
                case CaveCellTypeDungeonFloor:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_dFloor_0"]]; break;
                case CaveCellTypeDungeonFloorFire: {
                    NSString *burstPath = [[NSBundle mainBundle] pathForResource:@"fire_0" ofType:@"sks"];
                    emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
                    emitter.position = CGPointMake(x*self.tileSize.width+(self.tileSize.width/2), y*self.tileSize.height+(self.tileSize.height/2)-10);
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_dFloor_1"]];
                    break;
                }
                case CaveCellTypeDungeonFloorChest: {
                    SKSpriteNode *chest = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"item_treasure_0"]];
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_dFloor_0"]];
                    [node addChild:chest];
                    break;
                }
                case CaveCellTypeDungeonWall:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_dWall_0"]]; break;
                default:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"item_treasure_0"]]; break;
            }
            node.position = [self positionForGridCoordinate:CGPointMake(x, y)];
            node.blendMode = SKBlendModeReplace;
            node.texture.filteringMode = SKTextureFilteringNearest;
            [self addChild:node];
            if (emitter) [self addChild:emitter];
        }
    }
}

- (CGSize)determineSizeOfTiles {
    return [self.atlas textureNamed:@"tile_wall_0"].size;
}

# pragma mark - dungeon generation

- (void)cleanupDungeon {
    NSMutableArray *newGrid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *newRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CGPoint coordinate = CGPointMake(x, y);
            NSUInteger neighborWallCount = [self countNeighborsFromGridCoordinate:coordinate];
            DungeonCell *oldCell = [self caveCellFromGridCoordinate:coordinate];
            DungeonCell *newCell = [[DungeonCell alloc] initWithCoordinate:coordinate];
            if (oldCell.type == CaveCellTypeWall) {
                newCell.type = (neighborWallCount < self.wallsToFloorChance) ?
                    CaveCellTypeFloor : CaveCellTypeWall;
            }
            else {
                newCell.type = (neighborWallCount > self.floorsToWallChance) ?
                    CaveCellTypeWall : CaveCellTypeFloor;
            }
            [newRow addObject:newCell];
        }
        [newGrid addObject:newRow];
    }
    self.grid = newGrid;
}

- (void)identifyCaverns {
    self.caverns = [NSMutableArray array];
    NSMutableArray *floodFillArray = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *floodFillArrayRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            DungeonCell *cellToCopy = (DungeonCell *)self.grid[y][x];
            DungeonCell *copiedCell = [[DungeonCell alloc] initWithCoordinate:cellToCopy.coordinate];
            copiedCell.type = cellToCopy.type;
            [floodFillArrayRow addObject:copiedCell];
        }
        [floodFillArray addObject:floodFillArrayRow];
    }
    NSInteger fillNumber = CaveCellTypeMax;
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            if (((DungeonCell *)floodFillArray[y][x]).type == CaveCellTypeFloor) {
                [self.caverns addObject:[NSMutableArray array]];
                [self floodFillCavern:floodFillArray fromCoordinate:CGPointMake(x, y) fillNumber:fillNumber];
                fillNumber++;
            }
        }
    }
}

- (void)removeDisconnectedCaverns {
    NSInteger mainCavernIndex = [self mainIndexForArray:self.caverns];
    NSUInteger cavernsCount = self.caverns.count;
    if (cavernsCount > 0) {
        for (NSUInteger i = 0; i < cavernsCount; i++) {
            if (i != mainCavernIndex) {
                NSArray *array = (NSArray *)self.caverns[i];
                for (DungeonCell *cell in array)
                    ((DungeonCell *)self.grid[(int)cell.coordinate.y][(int)cell.coordinate.x]).type = CaveCellTypeWall;
    }   }   }
}

- (void)countSectors {
    int xMult = (int)self.gridSize.width/(int)_dungeonGenSize.width;
    int yMult = (int)self.gridSize.height/(int)_dungeonGenSize.height;
    self.sectorCount = [[NSMutableArray alloc] initWithCapacity:yMult];
    for (int y = 0; y < yMult; y++) {
        NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:xMult];
        for (int x = 0; x < xMult; x++) {
            int count = 0;
            for (int y2 = 0; y2 < (int)_dungeonGenSize.height; y2++)
                for (int x2 = 0; x2 < (int)_dungeonGenSize.width; x2++)
                    if(((DungeonCell *)self.grid[y*(int)_dungeonGenSize.height+y2][x*(int)_dungeonGenSize.width+x2]).type == CaveCellTypeWall) count ++;
            [row addObject:[NSNumber numberWithInt:count]];
        }
        [self.sectorCount addObject:row];
    }
}

- (void)spawnDungeons {
    for (int y = 0; y < self.sectorCount.count; y++) {
        for (int x = 0; x < [self.sectorCount[0] count]; x++) {
            if ([self.sectorCount[y][x] intValue] >= (int)_dungeonGenSize.height*_dungeonGenSize.width-2 &&
                [self.sectorCount[y][x] intValue] < (int)_dungeonGenSize.height*_dungeonGenSize.width && //nearly full block
                x > 0 && x+1 < (int)self.gridSize.width/(int)_dungeonGenSize.width && y > 0 && y+1 < (int)self.gridSize.height/(int)_dungeonGenSize.height) { //not edge
                bool fireSpawned = NO;
                int numChests = 0;
                for (int y2 = -1; y2 < (int)_dungeonGenSize.height+1; y2++) {
                    for (int x2 = -1; x2 < (int)_dungeonGenSize.width+1; x2++) {
                        if (y2 == -1 || y2 == (int)_dungeonGenSize.height || x2 == -1 || x2 == (int)_dungeonGenSize.width) { //surrounding wall check
                            if ([self caveCellFromGridCoordinate:CGPointMake(x*(int)_dungeonGenSize.width+x2, y*(int)_dungeonGenSize.height+y2)].type == CaveCellTypeWall) {
                                ((DungeonCell *)self.grid[y*(int)_dungeonGenSize.height+y2][x*(int)_dungeonGenSize.width+x2]).type = CaveCellTypeDungeonWall;
                            }
                        }
                        else {
                            int type = CaveCellTypeDungeonFloor;
                            if (arc4random()%8 == 0 && !fireSpawned) {
                                type = CaveCellTypeDungeonFloorFire;
                                fireSpawned = YES;
                            }
                            else if (arc4random()%12 == 0 && numChests < 3) {
                                type = CaveCellTypeDungeonFloorChest;
                                numChests ++;
                            }
                            ((DungeonCell *)self.grid[y*(int)_dungeonGenSize.height+y2][x*(int)_dungeonGenSize.width+x2]).type = type;
                        }
                    }
                }
            }
        }
    }
}

- (void)countWalls {
    self.walls = [NSMutableArray array];
    NSMutableArray *floodFillArray = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *floodFillArrayRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            DungeonCell *cellToCopy = (DungeonCell *)self.grid[y][x];
            DungeonCell *copiedCell = [[DungeonCell alloc] initWithCoordinate:cellToCopy.coordinate];
            copiedCell.type = cellToCopy.type;
            [floodFillArrayRow addObject:copiedCell];
        }
        [floodFillArray addObject:floodFillArrayRow];
    }
    NSInteger fillNumber = CaveCellTypeMax;
    for (NSUInteger y = 1; y < self.gridSize.height-1; y++) {
        for (NSUInteger x = 1; x < self.gridSize.width-1; x++) {
            if (((DungeonCell *)floodFillArray[y][x]).type == CaveCellTypeWall) {
                [self.walls addObject:[NSMutableArray array]];
                [self floodFillWalls:floodFillArray fromCoordinate:CGPointMake(x, y) fillNumber:fillNumber];
                fillNumber++;
            }
        }
    }
}

- (void)removeDisconnectedWalls {
    NSInteger mainIndex = [self mainIndexForArray:self.walls];
    NSUInteger count = self.walls.count;
    if (count > 0) {
        for (NSUInteger i = 0; i < count; i++) {
            NSArray *array = (NSArray *)self.walls[i];
            if (i != mainIndex) {
                for (DungeonCell *cell in array)
                    ((DungeonCell *)self.grid[(int)cell.coordinate.y][(int)cell.coordinate.x]).type = CaveCellTypeFloor;
            }   }   }
}

# pragma mark - public methods

- (DungeonCell *)caveCellFromGridCoordinate:(CGPoint)coordinate {
    return (DungeonCell *)self.grid[(int)coordinate.y][(int)coordinate.x];
}

- (CGPoint)gridCoordinateForPosition:(CGPoint)position {
    return CGPointMake((position.x/self.tileSize.width), (position.y/self.tileSize.height));
}

- (CGPoint)positionForGridCoordinate:(CGPoint)coordinate {
    return CGPointMake(coordinate.x*self.tileSize.width+self.tileSize.width/2, coordinate.y*self.tileSize.height+self.tileSize.height/2);
}

- (CGRect)rectFromGridCoordinate:(CGPoint)coordinate {
    CGPoint pos = [self positionForGridCoordinate:coordinate];
    return CGRectMake(pos.x-(self.tileSize.width/2), pos.y-(self.tileSize.height/2), self.tileSize.width, self.tileSize.height);
}

- (BOOL)isValidSpawnGridCoordinate:(CGPoint)coordinate {
    return ([self caveCellFromGridCoordinate:coordinate].canWalkOn);
}

- (NSArray *)pathFindFromGridCoordinate:(CGPoint) c1 toCoordinate:(CGPoint) c2 maxLoops:(int)maxLoops {
    c1 = CGPointMake((int)c1.x, (int)c1.y);
    c2 = CGPointMake((int)c2.x, (int)c2.y);
    CGPoint new = CGPointMake(0, 0);
    CGPoint current = CGPointMake(0, 0);
    NSMutableArray *openList, *closedList;
    if((c1.x == c2.x) && (c1.y == c2.y)) {
        //NSLog(@"Pathfind log: SAME COORD");
        return nil; //already there
    }
    openList = [NSMutableArray array]; //array to hold open nodes
    closedList = [NSMutableArray array]; //array to hold closed nodes
    PathFindNode *currentNode = nil;
    PathFindNode *aNode = nil;
    //create our initial 'starting node', where we begin our search
    PathFindNode *startNode = [PathFindNode node];
    startNode.coordinate = CGPointMake(c1.x, c1.y);
    startNode.parentNode = nil;
    startNode.cost = 0;
    //add it to the open list to be examined
    [openList addObject: startNode];
    int loops = 0;
    while([openList count]) { //while there are nodes to be examined...
        currentNode = [self lowestCostNodeInArray: openList]; //get the lowest cost node so far:
        if((currentNode.coordinate.x == c2.x) && (currentNode.coordinate.y == c2.y)) { //found!!!
            NSMutableArray *array = [[NSMutableArray alloc] init];
            aNode = currentNode.parentNode;
            [array addObject:[NSValue valueWithCGPoint: [self positionForGridCoordinate:c2]]];
            while(aNode.parentNode != nil) {
                [array addObject:[NSValue valueWithCGPoint: [self positionForGridCoordinate:aNode.coordinate]]];
                aNode = aNode.parentNode;
            }
            //NSLog(@"Pathfind log: DONE IN %d",loops);
            return array;
        }
        else {
            [closedList addObject: currentNode];
            [openList removeObject: currentNode];
            current.x = currentNode.coordinate.x;
            current.y = currentNode.coordinate.y;
            //check all the surrounding nodes/tiles:
            for(int y = -1; y <= 1; y++) {
                new.y = current.y + y;
                for(int x= -1; x <= 1; x++) {
                    new.x = current.x + x;
                    if((y || x) &&
                       (new.x>=0)&&(new.y>=0)&&(new.x<self.gridSize.width)&&(new.y<self.gridSize.height) && //in bounds
                       ![self nodeInArray: openList withPoint:new] && //doesnt exist
                       ![self nodeInArray: closedList withPoint:new] && //doesnt exist
                       [self pathIsValidFromPoint:current toPoint:new]) { //valid movement
                        //then add it to our open list and figure out the 'cost':
                        aNode = [PathFindNode node];
                        aNode.coordinate = new;
                        aNode.parentNode = currentNode;
                        aNode.cost = currentNode.cost + 1;
                        //Compute your cost here. This demo app uses a simple manhattan
                        //distance, added to the existing cost
                        aNode.cost += (abs((new.x) - c2.x)+abs((new.y) - c2.y));
                        [openList addObject: aNode];
                    }
                }
            }
        }
        loops ++;
        if (loops >= maxLoops) {
            //NSLog(@"Pathfind error: TOO FAR");
            return nil;
        }
    }
    NSLog(@"Pathfind error: NOT FOUND");
    return nil;
}

- (void)openChestAtGridCoordinate:(CGPoint)coordinate {
    ((DungeonCell *)self.grid[(int)coordinate.y][(int)coordinate.x]).type = CaveCellTypeDungeonFloor;
    SKSpriteNode *node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile_dFloor_0"]];
    node.position = [self positionForGridCoordinate:CGPointMake((int)coordinate.x, (int)coordinate.y)];
    node.blendMode = SKBlendModeReplace;
    node.texture.filteringMode = SKTextureFilteringNearest;
    [self addChild:node];
}

# pragma mark - helper methods

- (NSUInteger)countNeighborsFromGridCoordinate:(CGPoint)coordinate {
    int wallCount = 0;
    for (NSInteger i = -1; i < 2; i++) {
        for (NSInteger j = -1; j < 2; j++) {
            if ( i == 0 && j == 0 ) break; //middle
            CGPoint neighborCoordinate = CGPointMake(coordinate.x + i, coordinate.y + j);
            if (![self isValidGridCoordinate:neighborCoordinate]) wallCount ++;
            else if ([self caveCellFromGridCoordinate:neighborCoordinate].type == CaveCellTypeWall) wallCount ++;
        }
    }
    return wallCount;
}

- (BOOL)isEdgeAtGridCoordinate:(CGPoint)coordinate {
    return ((NSUInteger)coordinate.x == 0 ||
            (NSUInteger)coordinate.x == (NSUInteger)self.gridSize.width - 1 ||
            (NSUInteger)coordinate.y == 0 ||
            (NSUInteger)coordinate.y == (NSUInteger)self.gridSize.height - 1);
}

- (BOOL)isValidGridCoordinate:(CGPoint)coordinate {
    return !(coordinate.x < 0 || coordinate.x >= self.gridSize.width ||
             coordinate.y < 0 || coordinate.y >= self.gridSize.height);
}

- (void)floodFillCavern:(NSMutableArray *)array fromCoordinate:(CGPoint)coordinate fillNumber:(NSInteger)fillNumber {
    if (![self isValidGridCoordinate:coordinate]) return;
    DungeonCell *cell = (DungeonCell *)array[(int)coordinate.y][(int)coordinate.x];
    if (cell.type != CaveCellTypeFloor) return;
    cell.type = fillNumber;
    [[self.caverns lastObject] addObject:cell];
    if (coordinate.x > 0)
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x - 1, coordinate.y) fillNumber:fillNumber];
    if (coordinate.x < self.gridSize.width - 1)
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x + 1, coordinate.y) fillNumber:fillNumber];
    if (coordinate.y > 0)
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y - 1) fillNumber:fillNumber];
    if (coordinate.y < self.gridSize.height - 1)
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y + 1) fillNumber:fillNumber];
}

- (void)floodFillWalls:(NSMutableArray *)array fromCoordinate:(CGPoint)coordinate fillNumber:(NSInteger)fillNumber {
    if (!(coordinate.x >= 1 && coordinate.x <= self.gridSize.width-1 &&
        coordinate.y >= 1 && coordinate.y <= self.gridSize.height-1)) return;
    DungeonCell *cell = (DungeonCell *)array[(int)coordinate.y][(int)coordinate.x];
    if (cell.type != CaveCellTypeWall) return;
    cell.type = fillNumber;
    [[self.walls lastObject] addObject:cell];
    if (coordinate.x > 0)
        [self floodFillWalls:array fromCoordinate:CGPointMake(coordinate.x - 1, coordinate.y) fillNumber:fillNumber];
    if (coordinate.x < self.gridSize.width - 1)
        [self floodFillWalls:array fromCoordinate:CGPointMake(coordinate.x + 1, coordinate.y) fillNumber:fillNumber];
    if (coordinate.y > 0)
        [self floodFillWalls:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y - 1) fillNumber:fillNumber];
    if (coordinate.y < self.gridSize.height - 1)
        [self floodFillWalls:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y + 1) fillNumber:fillNumber];
}
 
- (NSInteger)mainIndexForArray:(NSMutableArray *)array {
    NSInteger mainIndex = -1;
    NSUInteger maxSize = 0;
    for (NSUInteger i = 0; i < array.count; i++) {
        NSArray *caveCells = (NSArray *)array[i];
        NSUInteger count = caveCells.count;
        if (count > maxSize) {
            maxSize = count;
            mainIndex = i;
        }
    }
    return mainIndex;
}

//pathfinding helper methods:

- (BOOL)pathIsValidFromPoint:(CGPoint)start toPoint:(CGPoint)end {
    if (![self caveCellFromGridCoordinate:end].canWalkOn) return NO;
    CGPoint offset = CGPointMake(end.x-start.x, end.y-start.y);
    offset = CGPointMake(offset.x/MAX(fabs(offset.x), fabs(offset.y)), offset.y/MAX(fabs(offset.x), fabs(offset.y)));
    if (fabs(offset.x)+fabs(offset.y)==2.0) { //attempting diag route
        bool u = [self isValidSpawnGridCoordinate:CGPointMake(start.x, start.y+1)];
        bool d = [self isValidSpawnGridCoordinate:CGPointMake(start.x, start.y-1)];
        bool r = [self isValidSpawnGridCoordinate:CGPointMake(start.x+1, start.y)];
        bool l = [self isValidSpawnGridCoordinate:CGPointMake(start.x-1, start.y)];
        if (offset.x == 1.0 && offset.y == 1.0) return (u && r);
        if (offset.x == -1.0 && offset.y == 1.0) return (u && l);
        if (offset.x == 1.0 && offset.y == -1.0) return (d && r);
        if (offset.x == -1.0 && offset.y == -1.0) return (d && l);
    }
    return YES;
}

-(PathFindNode*)nodeInArray:(NSMutableArray*)a withPoint:(CGPoint)p {
    //Quickie method to find a given node in the array with a specific x,y value
    NSEnumerator *e = [a objectEnumerator];
    PathFindNode *n;
    while((n = [e nextObject])) if((n.coordinate.x == p.x) && (n.coordinate.y == p.y)) return n;
    return nil;
}

-(PathFindNode*)lowestCostNodeInArray:(NSMutableArray*)a { //Finds the node in array with lowest cost
    PathFindNode *n, *lowest;
    lowest = nil;
    NSEnumerator *e = [a objectEnumerator];
    while((n = [e nextObject])) {
        if(lowest == nil) lowest = n;
        else if(n.cost < lowest.cost) lowest = n;
    }
    return lowest;
}

@end
