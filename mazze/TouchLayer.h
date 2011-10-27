//
//  TouchLayer.h
//  MindSnacks
//
//  Created by Jarod Luebbert on 10/25/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "cocos2d.h"

@protocol TouchDelegate;
@interface TouchLayer : CCLayer
@property (nonatomic, assign) id<TouchDelegate>delegate;
@property (nonatomic, assign) CFMutableDictionaryRef touchPositions;
@property (nonatomic, assign) int allowedTouches;
@property (nonatomic, readonly) int activeTouches;

+ (TouchLayer *)touchLayerWithContentSize:(CGSize)size;
- (id)initWithContentSize:(CGSize)size;
@end

@protocol TouchDelegate <NSObject>

- (void)touchBegan:(CGPoint)position withTag:(int)tag;
- (void)touchMovedTo:(CGPoint)position forObjectWithTag:(int)tag;
- (void)touchCancelledForObjectWithTag:(int)tag;
- (void)touchEndedForObjectWithTag:(int)tag;

@end