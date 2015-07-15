//
//  Spell.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "Spell.h"

@implementation Spell

- (instancetype)initWithSpellType:(SpellType)type {
    if ((self = [super init])) {
        self.itemType = ItemTypeSpell;
        self.spellType = type;
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"images"];
        if (self.spellType == SpellTypeFreeze) self.texture = [atlas textureNamed:@"item_spell_freeze"];
        else if (self.spellType == SpellTypeFire) self.texture = [atlas textureNamed:@"item_spell_fire"];
    }
    return self;
}

@end
