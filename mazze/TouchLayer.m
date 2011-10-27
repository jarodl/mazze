//
//  TouchLayer.m
//  MindSnacks
//
//  Created by Jarod Luebbert on 10/25/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "TouchLayer.h"
#import "UITouch+compareAddress.h"

#define kDefaultNumberOfAllowedTouches 5

@implementation TouchLayer

@synthesize delegate;
@synthesize touchPositions;
@synthesize allowedTouches;
@synthesize activeTouches;

+ (TouchLayer *)touchLayerWithContentSize:(CGSize)size
{
    return [[self alloc] initWithContentSize:size];
}

- (id)initWithContentSize:(CGSize)size
{
    if ((self = [super init]))
    {
        self.isTouchEnabled = YES;
        self.contentSize = size;
        self.allowedTouches = kDefaultNumberOfAllowedTouches;
        activeTouches = 0;
    }
    
    return self;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] + activeTouches <= self.allowedTouches)
    {
        for (UITouch *touch in touches)
        {
            CGPoint position = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
            int tag = (int)touch;
            [delegate touchBegan:position withTag:tag];
            activeTouches++;
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *sortedTouches = [[touches allObjects] sortedArrayUsingSelector:@selector(compareAddress:)];
    for (int i = 0; i < [sortedTouches count]; i++)
    {
        UITouch *touch = [sortedTouches objectAtIndex:i];
        int tag = (int)touch;
        CGPoint position = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
        [delegate touchMovedTo:position forObjectWithTag:tag];
    }
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *sortedTouches = [[touches allObjects] sortedArrayUsingSelector:@selector(compareAddress:)];
    for (int i = 0; i < [sortedTouches count]; i++)
    {
        UITouch *touch = [sortedTouches objectAtIndex:i];
        int tag = (int)touch;
        [delegate touchCancelledForObjectWithTag:tag];
        activeTouches--;
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *sortedTouches = [[touches allObjects] sortedArrayUsingSelector:@selector(compareAddress:)];
    for (int i = 0; i < [sortedTouches count]; i++)
    {
        UITouch *touch = [sortedTouches objectAtIndex:i];
        int tag = (int)touch;
        [delegate touchEndedForObjectWithTag:tag];
        activeTouches--;
    }
}

@end
