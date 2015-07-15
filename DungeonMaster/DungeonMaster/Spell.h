//
//  Spell.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Item.h"

typedef NS_ENUM(NSInteger, SpellType) {
    SpellTypeInvalid = -1,
    SpellTypeFreeze,
    SpellTypeFire
};

@interface Spell : Item

@property (assign, nonatomic) SpellType spellType;

- (instancetype)initWithSpellType:(SpellType)type;
    
@end
