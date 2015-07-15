//
//  Scene.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/13/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Scene.h"
#import "DPad.h"
#import "Player.h"
#import "Enemy.h"
#import "Dungeon.h"
#import "DungeonCell.h"
#import "ItemBar.h"
#import "Spell.h"
#import "Projectile.h"
#import "InteractionMessage.h"

@interface Scene()
@property (assign, nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (strong, nonatomic) SKNode *world;
@property (strong, nonatomic) SKNode *hud;
@property (strong, nonatomic) Player *player;
@property (strong, nonatomic) NSMutableArray *enemies;
@property (strong, nonatomic) NSMutableArray *projectiles;
@property (strong, nonatomic) DPad *dPad;
@property (strong, nonatomic) ItemBar *itemBar;
@property (assign, nonatomic) BOOL isExitingLevel;
@property (strong, nonatomic) Dungeon *dungeon;
@property (nonatomic) InteractionMessage *interactionMessage;
//Touch tracking
@property (nonatomic) CFMutableDictionaryRef trackedTouchesPl;
@property (nonatomic) CFMutableDictionaryRef trackedTouchesSc;
@end

@implementation Scene

- (instancetype)initWithSize:(CGSize)size fileName:(NSString *)fileName {
    if ((self = [super initWithSize:size])) {
        self.backgroundColor = [SKColor colorWithRed:58.0f/255.0f green:60.0f/255.0f blue:73.0f/255.0f alpha:1.0f];
        // WORLD
        self.world = [SKNode node];
        self.world.name = @"WORLD";
        // DUNGEON
        if (fileName) _dungeon = [[Dungeon alloc] initWithAtlasNamed:@"images" fileName:(NSString *)fileName];
        else _dungeon = [[Dungeon alloc] initWithAtlasNamed:@"images"];
        _dungeon.name = @"CAVE";
        [_world addChild:_dungeon];
        // TOUCH TRACKING
        _trackedTouchesPl = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _trackedTouchesSc = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        // PLAYER
        self.player = [Player spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"player_idle_0"]];
        self.player.name = @"PLAYER";
        self.player.personPosition = [self determineValidSpawn];
        self.player.position = self.player.personPosition;
        [_world addChild:self.player];
        // ENEMIES
        self.enemies = [[NSMutableArray alloc] init];
        for (int i = 0; i < 20; i++) {
            Enemy *enemy = [Enemy spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"enemy_idle_0"]];
            enemy.name = @"ENEMY";
            enemy.personPosition = [self determineValidSpawn];
            enemy.position = enemy.personPosition;
            [self.enemies addObject:enemy];
            [_world addChild:enemy];
        }
        // HUD
        self.hud = [SKNode node];
        self.hud.name = @"HUD";
        self.dPad = [[DPad alloc] initWithRect:CGRectMake(0, 0, 120, 120)];
        self.dPad.name = @"DPAD";
        self.dPad.position = CGPointMake(30,30);
        self.itemBar = [[ItemBar alloc] initWithRect:CGRectMake(200, 0, self.frame.size.width-300, 60)];
        self.itemBar.name = @"ITEMBAR";
        [self.hud addChild:self.itemBar];
        [self.hud addChild:self.dPad];
        [self addChild:self.world];
        [self addChild:self.hud];
        self.userInteractionEnabled = YES; //for determining onscreen presses
        // ITEM TEST
        [self.itemBar addItem:[[Spell alloc] initWithSpellType:SpellTypeFreeze]];
        [self.itemBar addItem:[[Spell alloc] initWithSpellType:SpellTypeFire]];
        // PROJECTILE INIT
        self.projectiles = [[NSMutableArray alloc] init];
    }
    return self;
}

bool godMode = NO;

- (void)update:(CFTimeInterval)currentTime {
    // Calculate the time since last update
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) {timeSinceLast = 1.0/60.0; self.lastUpdateTimeInterval = currentTime;}
    // Movement
    if (self.dPad.velocity.x != 0.0 && self.dPad.velocity.y != 0.0) self.player.pathFindQueue = nil;
    self.player.velocity = self.dPad.velocity; //velocity from dPad to Player (player only)
    [self updatePersonPositionForPerson:self.player WithTimeInvterval:timeSinceLast]; //suggested player movement
    // Collision detection (player only)
    NSArray *cells = [self getCaveCellsFromRect:self.player.collisionRect];
    for (DungeonCell *cell in cells) {
        CGPoint repel = [self repelDistanceForRect:self.player.collisionRect andRect:[self.dungeon rectFromGridCoordinate:cell.coordinate]];
        if (!godMode) self.player.personPosition = CGPointMake(self.player.personPosition.x + repel.x, self.player.personPosition.y + repel.y);
    }
    [self updateVisualsForPerson:self.player];
    // Enemies
    for (Enemy *e in self.enemies) {
        if ([self distanceBetweenPerson:e andPerson:self.player] <= 40) { //within 6.3-ish
            e.pathFindQueue = [self.dungeon pathFindFromGridCoordinate: [self.dungeon gridCoordinateForPosition:e.position]
                                                          toCoordinate: [self.dungeon gridCoordinateForPosition:self.player.position]
                                                              maxLoops: 50];
        }
        else if (e.pathFindQueue.count != 0) e.pathFindQueue = nil; //forget about player if too far
        [self updatePersonPositionForPerson:e WithTimeInvterval:timeSinceLast];
        [self updateVisualsForPerson:e];
    }
    // Chest check
    if ([self.dungeon caveCellFromGridCoordinate:[self.dungeon gridCoordinateForPosition:self.player.position]].type == CaveCellTypeDungeonFloorChest) {
        if (!self.interactionMessage) {
            self.interactionMessage = [[InteractionMessage alloc] initWithRect:CGRectMake(0, 0, 110, 25)];
            [_world addChild:self.interactionMessage];
        }
        self.interactionMessage.position = CGPointMake(self.player.position.x, self.player.position.y+15);
        self.interactionMessage.hidden = NO;
        if (self.interactionMessage.touched) {
            [self openChestAtWorldPosition:self.player.position];
            self.interactionMessage.touched = NO;
        }
    }
    else self.interactionMessage.hidden = YES;
    // Projectiles
    for (int i = 0; i < self.projectiles.count; i++) {
        Projectile *p = self.projectiles[i];
        if (!p.isVisible) {
            [self.world addChild:p];
            p.isVisible = YES;
        }
        if (p.shouldDespawn) {
            p.hidden = YES;
            [self.projectiles removeObject:p];
        }
        else { //normal loop
            [p updateWithTimeInterval:timeSinceLast];
            // Collision detection
            if (p.isFlying) {
                NSArray *cells = [self getCaveCellsFromRect:p.collisionRect];
                for (DungeonCell *cell in cells) {
                    CGPoint repel = [self repelDistanceForRect:p.collisionRect andRect:[self.dungeon rectFromGridCoordinate:cell.coordinate]];
                    if (repel.x != 0.0 || repel.y != 0.0) p.isFlying = NO;
                }
                [p applyMovements];
                for (Enemy *e in [self enemiesInRect:p.collisionRect]) {
                    p.isFlying = NO;
                    [p removeFromParent];
                    if (e.xScale == 1) p.position = CGPointMake((p.position.x-e.position.x), (p.position.y-e.position.y));
                    else {
                        p.position = CGPointMake(-(p.position.x-e.position.x), (p.position.y-e.position.y));
                        p.xScale = -1;
                    }
                    [e addChild:p];
                    e.color = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
                    e.colorBlendFactor = 0.8;
                    break;
                }
            }
        }
    }
    // ItemBar check
    if (self.itemBar.slotSelected) {
        self.itemBar.slotSelected = NO;
        if (self.itemBar.selectedItem.itemType == ItemTypeSpell) {
            if (((Spell *)self.itemBar.selectedItem).spellType == SpellTypeFreeze) {
                NSString *burstPath = [[NSBundle mainBundle] pathForResource:@"spell_freeze" ofType:@"sks"];
                SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
                emitter.position = self.player.position;
                [_world addChild:emitter];
                for (Enemy *e in [self enemiesInRect:CGRectMake(self.player.position.x-50, self.player.position.y-50, 100, 100)]) {
                    e.color = [SKColor colorWithRed:0.0 green:0.8 blue:1 alpha:1];
                    e.colorBlendFactor = 0.7;
                    e.movementSpeed = 0;
                }
            }
            if (((Spell *)self.itemBar.selectedItem).spellType == SpellTypeFire) {
                NSString *burstPath = [[NSBundle mainBundle] pathForResource:@"spell_fire" ofType:@"sks"];
                SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
                emitter.position = CGPointMake(self.player.position.x+5, self.player.position.y-5);
                [_world addChild:emitter];
                for (Enemy *e in [self enemiesInRect:CGRectMake(self.player.position.x-5, self.player.position.y-15, 120, 30)]) {
                    e.color = [SKColor colorWithRed:1 green:0.1 blue:0.1 alpha:1];
                    e.colorBlendFactor = 0.8;
                }
            }
        }
    }
    // Camera
    self.world.position = CGPointMake(-self.player.position.x + CGRectGetMidX(self.frame), -self.player.position.y + CGRectGetMidY(self.frame));
}

# pragma mark - hepler methods

- (void) updatePersonPositionForPerson:(Person *)p WithTimeInvterval:(CFTimeInterval)tInterval {
    if (p.pathFindQueue.count != 0) { //pathfinding
        CGPoint dest = [(NSValue *)p.pathFindQueue.lastObject CGPointValue];
        CGPoint offset = CGPointMake(dest.x-p.position.x, dest.y-p.position.y);
        p.velocity = CGPointMake(offset.x/MAX(fabs(offset.x), fabs(offset.y)), offset.y/MAX(fabs(offset.x), fabs(offset.y)));
        CGPoint pPos = [self.dungeon gridCoordinateForPosition:p.position];
        CGPoint tPos = [self.dungeon gridCoordinateForPosition:dest];
        if ((int)pPos.x == (int)tPos.x && (int)pPos.y == (int)tPos.y)
            [p.pathFindQueue removeLastObject];
    }
    else if (![p.name isEqual:@"PLAYER"])p.velocity = CGPointZero;
    p.personPosition = CGPointMake(p.position.x + p.velocity.x * tInterval * p.movementSpeed, p.position.y + p.velocity.y * tInterval * p.movementSpeed);
}

- (void)updateVisualsForPerson:(Person *)p {
    if (p.personPosition.x != p.position.x ||
        p.personPosition.y != p.position.y) p.animationID = 1; //anim determination
    else p.animationID = 0;
    p.xScale = (p.velocity.x < 0) ? -1: 1;//direction
    [p resolveAnimationWithID:p.animationID]; //animation
    p.position = p.personPosition; //actual movement
}

- (NSMutableArray *)enemiesInRect:(CGRect)rect {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (Enemy *e in self.enemies) if (CGRectIntersectsRect(rect, e.collisionRect)) [arr addObject:e];
    return arr;
}

- (CGFloat)distanceBetweenPerson:(Person *)p1 andPerson:(Person *)p2 { //returns distance squared
    CGPoint pt1 = [self.dungeon gridCoordinateForPosition:p1.position];
    CGPoint pt2 = [self.dungeon gridCoordinateForPosition:p2.position];
    return fabs((pt2.x-pt1.x)*(pt2.x-pt1.x))+fabs((pt2.y-pt1.y)*(pt2.y-pt1.y));
}

- (NSArray *)getCaveCellsFromRect:(CGRect)rect { //for collision detection
    NSMutableArray *array = [NSMutableArray array];
    DungeonCell *topLeft = [self.dungeon caveCellFromGridCoordinate: [self.dungeon gridCoordinateForPosition:rect.origin]];
    DungeonCell *topRight = [self.dungeon caveCellFromGridCoordinate: [self.dungeon gridCoordinateForPosition:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))]];
    DungeonCell *bottomLeft = [self.dungeon caveCellFromGridCoordinate: [self.dungeon gridCoordinateForPosition:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))]];
    DungeonCell *bottomRight = [self.dungeon caveCellFromGridCoordinate: [self.dungeon gridCoordinateForPosition:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))]];
    if (topLeft && !topLeft.canWalkOn) [array addObject:topLeft];
    if (topRight && !topRight.canWalkOn && ![array containsObject:topRight]) [array addObject:topRight];
    if (bottomLeft && !bottomLeft.canWalkOn && ![array containsObject:bottomLeft]) [array addObject:bottomLeft];
    if (bottomRight && !bottomRight.canWalkOn && ![array containsObject:bottomRight]) [array addObject:bottomRight];
    return array;
}

- (CGPoint)repelDistanceForRect:(CGRect)playerRect andRect:(CGRect)cellRect {
    if (CGRectIntersectsRect(playerRect, cellRect)) {
        NSInteger signX = CGRectGetMaxX(playerRect) > CGRectGetMaxX(cellRect) ? 1 : -1;
        NSInteger signY = CGRectGetMaxY(playerRect) > CGRectGetMaxY(cellRect) ? 1 : -1;
        CGRect intersectionRect = CGRectIntersection(playerRect, cellRect);
        if (CGRectGetWidth(intersectionRect) < CGRectGetHeight(intersectionRect))
            return CGPointMake(CGRectGetWidth(intersectionRect) * signX, 0.0f);
        else if (CGRectGetWidth(intersectionRect) > CGRectGetHeight(intersectionRect))
            return CGPointMake(0.0f, CGRectGetHeight(intersectionRect) * signY);
        else return CGPointMake(CGRectGetWidth(intersectionRect) * signX, CGRectGetHeight(intersectionRect) * signY);
    }
    return CGPointZero;
}

- (CGPoint)determineValidSpawn {
    while (YES) {
        int x = arc4random() % (int)self.dungeon.gridSize.width;
        int y = arc4random() % (int)self.dungeon.gridSize.height;
        if ([_dungeon isValidSpawnGridCoordinate:CGPointMake(x, y)]) return CGPointMake((x+0.5)*self.dungeon.tileSize.width, (y+0.5)*self.dungeon.tileSize.height);
    }
}

- (void)openChestAtWorldPosition:(CGPoint)position {
    [self.dungeon openChestAtGridCoordinate:[self.dungeon gridCoordinateForPosition:self.player.position]];
    SKSpriteNode *node = [[SKSpriteNode alloc] initWithTexture:[[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"item_treasure_0"]];
    node.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    [self addChild:node];
    SKAction *enlarge = [SKAction scaleTo:10 duration:2.0];
    enlarge.timingMode = SKActionTimingEaseOut;
    [node runAction:enlarge completion:^{
        node.texture = [[SKTextureAtlas atlasNamed:@"images"] textureNamed:@"item_treasure_1"];
        SKAction *wait = [SKAction waitForDuration:2.0];
        SKAction *fade = [SKAction fadeAlphaTo:0 duration:1.0];
        SKAction *ret = [SKAction scaleTo:1 duration:1.0];
        SKAction *retur = [SKAction group:@[fade, ret]];
        retur.timingMode = SKActionTimingEaseIn;
        [node runAction:[SKAction sequence:@[wait, retur]]];
    }];
}

# pragma mark - scene touch events

bool isTouchingPlayer;
bool isTouchingScene;
SKShapeNode *line;
CGPoint diff;

- (void)lineFromPoint:(CGPoint)s toPoint:(CGPoint)e {
    if (!line) {
        line = [SKShapeNode node];
        line.lineCap = kCGLineCapRound;
        [self addChild:line];
    }
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDraw, NULL, s.x, s.y);
    CGPathAddLineToPoint(pathToDraw, NULL, e.x, e.y);
    line.path = pathToDraw;
    float dist = log2(sqrtf((s.x-e.x)*(s.x-e.x)+(s.y-e.y)*(s.y-e.y)));
    line.lineWidth = dist;
    [line setStrokeColor:[UIColor colorWithRed:1-(dist-6)/2 green:(dist-6)/2 blue:0 alpha:1]];
    line.alpha = 0.5;
    diff = CGPointMake(s.x-e.x, s.y-e.y);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        // First determine if the touch is within the boundries of the DPad
        UITouch *touch = (UITouch *)obj;
        CGPoint location = [touch locationInNode:self.world];
        CGPoint locationLocal = [touch locationInNode:self];
        if (CGRectContainsPoint(self.player.collisionRect, location)) {
            CFDictionarySetValue(_trackedTouchesPl, (__bridge void *)touch, (__bridge void *)touch);
            isTouchingPlayer = YES;
            line.alpha = 1;
            [self lineFromPoint:locationLocal toPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
        }
        else {
            CFDictionarySetValue(_trackedTouchesSc, (__bridge void *)touch, (__bridge void *)touch);
            isTouchingScene = YES;
        }
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (isTouchingPlayer) {
        // Determine if any of the touches are one of those being tracked
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(_trackedTouchesPl, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch is being tracked
                CGPoint locationLocal = [touch locationInNode:self];
                [self lineFromPoint:locationLocal toPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
            }
        }];
    }
    if (isTouchingScene) {
        // Determine if any of the touches are one of those being tracked
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(_trackedTouchesSc, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch is being tracked
                isTouchingScene = NO;
            }
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (isTouchingPlayer) {
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(_trackedTouchesPl, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch was being tracked
                line.alpha = 0;
                [self.projectiles addObject:[[Projectile alloc] initWithPosition:self.player.position velocity:CGPointMake(-diff.x, -diff.y)]];
                isTouchingPlayer = NO;
                CFDictionaryRemoveValue(_trackedTouchesPl, (__bridge void *)touch);
            }
        }];
    }
    if (isTouchingScene) {
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            UITouch *touch = (UITouch *) CFDictionaryGetValue(_trackedTouchesSc, (__bridge void *)(UITouch *)obj);
            if (touch != NULL) { // This touch was being tracked
                CGPoint offset = self.world.position;
                CGPoint tch = [[[event allTouches] anyObject] locationInNode:self.world];
                //NSLog(@"%f %f, %f %f",-offset.x,-offset.y,touch.x,self.view.frame.size.height-touch.y);
                CGPoint location = [self.dungeon gridCoordinateForPosition:CGPointMake(-offset.x+tch.x, -offset.y+self.view.frame.size.height-tch.y)];
                if (location.x>=0 && location.x <= self.dungeon.gridSize.width && location.y>=0 && location.y <= self.dungeon.gridSize.height) {
                    if (![self.dungeon isValidSpawnGridCoordinate:location]) return;
                    self.player.pathFindQueue = [self.dungeon pathFindFromGridCoordinate: [self.dungeon gridCoordinateForPosition:self.player.position] toCoordinate:location maxLoops:10000];
                }
                isTouchingScene = NO;
                CFDictionaryRemoveValue(_trackedTouchesSc, (__bridge void *)touch);
            }
        }];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

@end
