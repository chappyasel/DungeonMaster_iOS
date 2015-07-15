//
//  InteractionMessage.m
//  DungeonMaster
//
//  Created by Chappy Asel on 2/18/15.
//  Copyright (c) 2015 CD. All rights reserved.
//

#import "InteractionMessage.h"

@implementation InteractionMessage {
    SKLabelNode *text;
    SKShapeNode *background;
    bool isTouching;
}

- (instancetype)initWithRect:(CGRect)rect {
    if ((self = [super init])) {
        self.position = CGPointMake(rect.origin.x, rect.origin.y);
        //background
        background = [SKShapeNode node];
        background.fillColor = [UIColor lightGrayColor];
        background.strokeColor = [UIColor blackColor];
        background.lineWidth = 1;
        background.path = CGPathCreateWithRect(CGRectMake(-rect.size.width/2, 0, rect.size.width, rect.size.height), NULL);
        background.alpha = 0.8;
        [self addChild:background];
        //text
        text = [SKLabelNode labelNodeWithText:@"Interact"];
        text.position = CGPointMake(0, 5);
        text.fontColor = [UIColor blackColor];
        text.fontSize = 18.0;
        text.fontName = @"AvenirNext-Bold";
        [self addChild:text];
        //interaction
        self.userInteractionEnabled = YES;
        self.touched = NO;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    isTouching = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    isTouching = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (isTouching) self.touched = YES;
}

@end
