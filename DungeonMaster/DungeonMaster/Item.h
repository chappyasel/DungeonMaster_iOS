//
//  Item.h
//  DungeonMaster
//
//  Created by Chappy Asel on 2/17/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSInteger, ItemType) {
    ItemTypeInvalid = -1,
    ItemTypeConsumable,
    ItemTypeWearable,
    ItemTypeWeapon,
    ItemTypeSpell
};

//Item
//  Consumable (heal, mana, strength...)
//  Wearable (chest, head)
//  Weapon (norm, ranged)
//  Spell (freeze, fire...)

@interface Item : SKSpriteNode

@property (assign, nonatomic) ItemType itemType;

@end
