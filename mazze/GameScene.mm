//
//  GameScene.m
//  mazze
//
//  Created by Jarod Luebbert on 10/19/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "GameScene.h"
#import "ImageLoader.h"
#import "Environment.h"
#import "Box2DNode.h"

#define kObjectsSpriteSheetName @"Objects"
#define kBackgroundColor ccc4(255,244,217, 255)
#define PTM_RATIO 50.0f
#define kWorldGravity 10.0f
#define kNumberOfRows 12
#define kNumberOfColumns 8
#define kBoxSpriteFrameName @"box.png"
#define kStarSpriteFrameName @"star.png"
#define kPlayerColor ccc3(156,177,179)
#define kMapColor ccc3(247,214,136)
#define kSecondMapColor ccc3(146,63,63)
#define kFadeColor ccc4(156,177,179, 255)
#define kStarColor ccc3(247,136,146)

@interface GameScene ()
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, assign) CGPoint secondStartPosition;
@property (nonatomic, assign) CGPoint goalPosition;
@property (nonatomic, retain) NSSet *map;
@property (nonatomic, retain) NSSet *secondMap;
@property (nonatomic, retain) CCSprite *playerOne;
@property (nonatomic, retain) CCSprite *playerTwo;
@property (nonatomic, retain) CCLayerColor *fadeLayer;
@property (nonatomic, retain) CCSprite *star;
- (void)addWalls;
- (void)addSecondWalls;
- (void)addPlayer;
- (void)addSecondPlayer;
- (CGPoint)gridToWorld:(CGPoint)position;
- (void)orientationChanged:(NSNotification *)notification;
- (void)checkForWin;
- (CGPoint)worldToGrid:(CGPoint)position;
- (void)restartGame;
@end

@implementation GameScene

@synthesize map;
@synthesize secondMap;
@synthesize startPosition;
@synthesize secondStartPosition;
@synthesize playerOne;
@synthesize playerTwo;
@synthesize fadeLayer;
@synthesize goalPosition;
@synthesize star;

#pragma mark -
#pragma mark Set up

- (id)init
{
    if ((self = [super init]))
    {
        [[ImageLoader sharedInstance] loadSpriteSheet:kObjectsSpriteSheetName];
        self.contentSize = [Environment sharedInstance].screenSize;
        
        CCLayerColor *bg = [CCLayerColor layerWithColor:kBackgroundColor];
        bg.contentSize = self.contentSize;
        [self addChild:bg];
        
        self.fadeLayer = [CCLayerColor layerWithColor:kFadeColor];
        self.fadeLayer.contentSize = self.contentSize;
        self.star = [CCSprite spriteWithSpriteFrameName:kStarSpriteFrameName];
        self.star.color = kStarColor;
        self.star.visible = NO;
        star.position = ccp(fadeLayer.contentSize.width / 2, fadeLayer.contentSize.height / 1.5);
        [fadeLayer addChild:star];
        [self.fadeLayer setOpacity:0];
        [self addChild:fadeLayer z:5];
        
        // Physics
        b2Vec2 gravity;
        gravity.Set(0.0f, -kWorldGravity);
        bool doSleep = true;
        world = new b2World(gravity, doSleep);
        world->SetContinuousPhysics(true);
        secondWorld = new b2World(gravity, doSleep);
        secondWorld->SetContinuousPhysics(true);
        m_debugDraw = new GLESDebugDraw(PTM_RATIO * CC_CONTENT_SCALE_FACTOR());
        uint32 flags = 0;
//        flags += b2DebugDraw::e_shapeBit;
//        flags += b2DebugDraw::e_jointBit;
//        flags += b2DebugDraw::e_aabbBit;
//        flags += b2DebugDraw::e_pairBit;
//        flags += b2DebugDraw::e_centerOfMassBit;
        m_debugDraw->SetFlags(flags);
        world->SetDebugDraw(m_debugDraw);
        secondWorld->SetDebugDraw(m_debugDraw);
        // ground body
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0, 0);
        groundBody = world->CreateBody(&groundBodyDef);
        // ground box shape
        b2PolygonShape groundBox;
        // left
        groundBox.SetAsEdge(b2Vec2(0, self.contentSize.height / PTM_RATIO), b2Vec2_zero);
        groundBody->CreateFixture(&groundBox, 0);
        // right
        groundBox.SetAsEdge(b2Vec2(self.contentSize.width / PTM_RATIO,
                                   self.contentSize.height / PTM_RATIO),
                            b2Vec2(self.contentSize.width / PTM_RATIO, 0));
        groundBody->CreateFixture(&groundBox, 0);
        // bottom
        groundBox.SetAsEdge(b2Vec2_zero,
                            b2Vec2(self.contentSize.width / PTM_RATIO, 0));
        groundBody->CreateFixture(&groundBox, 0);
        // top
        groundBox.SetAsEdge(b2Vec2(0, self.contentSize.height / PTM_RATIO),
                            b2Vec2(self.contentSize.width / PTM_RATIO, self.contentSize.height / PTM_RATIO));
        groundBody->CreateFixture(&groundBox, 0);
        
        groundBody = secondWorld->CreateBody(&groundBodyDef);
        // ground box shape
        // left
        groundBox.SetAsEdge(b2Vec2(0, self.contentSize.height / PTM_RATIO), b2Vec2_zero);
        groundBody->CreateFixture(&groundBox, 0);
        // right
        groundBox.SetAsEdge(b2Vec2(self.contentSize.width / PTM_RATIO,
                                   self.contentSize.height / PTM_RATIO),
                            b2Vec2(self.contentSize.width / PTM_RATIO, 0));
        groundBody->CreateFixture(&groundBox, 0);
        // bottom
        groundBox.SetAsEdge(b2Vec2_zero,
                            b2Vec2(self.contentSize.width / PTM_RATIO, 0));
        groundBody->CreateFixture(&groundBox, 0);
        // top
        groundBox.SetAsEdge(b2Vec2(0, self.contentSize.height / PTM_RATIO),
                            b2Vec2(self.contentSize.width / PTM_RATIO, self.contentSize.height / PTM_RATIO));
        groundBody->CreateFixture(&groundBox, 0);
        
        self.map = [NSSet setWithObjects:
                    [NSValue valueWithCGPoint:ccp(3, 0)],
                    [NSValue valueWithCGPoint:ccp(3, 1)],
                    [NSValue valueWithCGPoint:ccp(3, 2)],
                    [NSValue valueWithCGPoint:ccp(3, 3)],
                    [NSValue valueWithCGPoint:ccp(3, 4)],
                    [NSValue valueWithCGPoint:ccp(3, 5)],
                    [NSValue valueWithCGPoint:ccp(3, 9)],
                    [NSValue valueWithCGPoint:ccp(2, 4)],
                    [NSValue valueWithCGPoint:ccp(2, 5)],
                    [NSValue valueWithCGPoint:ccp(2, 9)],
                    [NSValue valueWithCGPoint:ccp(2, 10)],
                    [NSValue valueWithCGPoint:ccp(2, 11)],
                    [NSValue valueWithCGPoint:ccp(1, 4)],
                    [NSValue valueWithCGPoint:ccp(1, 5)],
                    [NSValue valueWithCGPoint:ccp(1, 9)],
                    [NSValue valueWithCGPoint:ccp(0, 4)],
                    [NSValue valueWithCGPoint:ccp(0, 5)],
                    [NSValue valueWithCGPoint:ccp(0, 6)],
                    [NSValue valueWithCGPoint:ccp(0, 7)],
                    [NSValue valueWithCGPoint:ccp(0, 8)],
                    [NSValue valueWithCGPoint:ccp(0, 9)],
                    [NSValue valueWithCGPoint:ccp(4, 9)],
                    [NSValue valueWithCGPoint:ccp(5, 0)],
                    [NSValue valueWithCGPoint:ccp(5, 1)],
                    [NSValue valueWithCGPoint:ccp(5, 2)],
                    [NSValue valueWithCGPoint:ccp(5, 3)],
                    [NSValue valueWithCGPoint:ccp(5, 9)],
                    [NSValue valueWithCGPoint:ccp(6, 3)],
                    [NSValue valueWithCGPoint:ccp(6, 4)],
                    [NSValue valueWithCGPoint:ccp(6, 5)],
                    [NSValue valueWithCGPoint:ccp(6, 9)],
                    [NSValue valueWithCGPoint:ccp(7, 5)],
                    [NSValue valueWithCGPoint:ccp(7, 6)],
                    [NSValue valueWithCGPoint:ccp(7, 7)],
                    [NSValue valueWithCGPoint:ccp(7, 8)],
                    [NSValue valueWithCGPoint:ccp(7, 9)],
                    nil];
        self.secondMap = [NSSet setWithObjects:
                          [NSValue valueWithCGPoint:ccp(1, 2)],
                          [NSValue valueWithCGPoint:ccp(1, 3)],
                          [NSValue valueWithCGPoint:ccp(1, 4)],                          
                          [NSValue valueWithCGPoint:ccp(1, 5)],                          
                          [NSValue valueWithCGPoint:ccp(1, 6)],                          
                          [NSValue valueWithCGPoint:ccp(1, 7)],                          
                          [NSValue valueWithCGPoint:ccp(1, 8)],                          
                          [NSValue valueWithCGPoint:ccp(1, 9)],
                          [NSValue valueWithCGPoint:ccp(1, 10)],
                          [NSValue valueWithCGPoint:ccp(2, 2)],
                          [NSValue valueWithCGPoint:ccp(2, 10)],                          
                          [NSValue valueWithCGPoint:ccp(3, 0)],  
                          [NSValue valueWithCGPoint:ccp(3, 2)],                          
                          [NSValue valueWithCGPoint:ccp(3, 10)],                          
                          [NSValue valueWithCGPoint:ccp(4, 0)],
                          [NSValue valueWithCGPoint:ccp(4, 1)],                          
                          [NSValue valueWithCGPoint:ccp(4, 2)],                          
                          [NSValue valueWithCGPoint:ccp(4, 3)],                          
                          [NSValue valueWithCGPoint:ccp(4, 4)],                          
                          [NSValue valueWithCGPoint:ccp(4, 5)],                          
                          [NSValue valueWithCGPoint:ccp(4, 6)],                         
                          [NSValue valueWithCGPoint:ccp(4, 7)],
                          [NSValue valueWithCGPoint:ccp(4, 10)],                          
                          [NSValue valueWithCGPoint:ccp(5, 2)],
                          [NSValue valueWithCGPoint:ccp(5, 7)],
                          [NSValue valueWithCGPoint:ccp(5, 10)],                          
                          [NSValue valueWithCGPoint:ccp(5, 11)],                          
                          [NSValue valueWithCGPoint:ccp(6, 2)],                          
                          [NSValue valueWithCGPoint:ccp(6, 6)],                          
                          [NSValue valueWithCGPoint:ccp(6, 7)],                          
                          [NSValue valueWithCGPoint:ccp(6, 8)],                          
                          [NSValue valueWithCGPoint:ccp(6, 9)],                          
                          [NSValue valueWithCGPoint:ccp(6, 10)],                          
                          [NSValue valueWithCGPoint:ccp(7, 0)],                          
                          [NSValue valueWithCGPoint:ccp(7, 1)],
                          [NSValue valueWithCGPoint:ccp(7, 2)],
                          [NSValue valueWithCGPoint:ccp(7, 6)],
                          [NSValue valueWithCGPoint:ccp(7, 7)],                          
                          nil];
        self.startPosition = ccp(2, 11);
        self.secondStartPosition = ccp(5, 11);
        self.goalPosition = ccp(3, 0);
        CCSprite *goalStar = [CCSprite spriteWithSpriteFrameName:kStarSpriteFrameName];
        goalStar.position = [self gridToWorld:goalPosition];
        goalStar.color = kStarColor;
        goalStar.scale = 0.25f;
        [self addChild:goalStar z:4];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)checkForWin
{
    CGPoint p1 = [self worldToGrid:playerOne.position];
    CGPoint p2 = [self worldToGrid:playerTwo.position];
    if ((int)round(p1.x) == (int)goalPosition.x && (int)round(p1.y) == (int)goalPosition.y &&
        (int)round(p2.x) == (int)goalPosition.x && (int)round(p2.y) == (int)goalPosition.y)
    {
        [TestFlight passCheckpoint:@"Reached the end of the maze"];
        [self unscheduleAllSelectors];
        [self.fadeLayer runAction:[CCSequence actions:
                                   [CCFadeIn actionWithDuration:0.5f],
                                   [CCCallBlock actionWithBlock:^
                                    {
                                        self.star.visible = YES;
                                        [self restartGame];
                                    }],
                                   [CCDelayTime actionWithDuration:1.5f],
//                                   [CCFadeOut actionWithDuration:0.5f],
//                                   [CCCallBlock actionWithBlock:^
//                                    {
//                                        self.star.visible = NO; 
//                                    }],
                                   nil]];
    }
}

#pragma mark -
#pragma mark Helper

- (CGPoint)gridToWorld:(CGPoint)position
{
    CGSize screenSize = [[Environment sharedInstance] screenSize];
    float cellHeight = screenSize.height / kNumberOfRows;
    float cellWidth = screenSize.width / kNumberOfColumns;
    return ccp((position.x * cellWidth) + cellWidth / 2,
               (position.y * cellHeight) + cellHeight / 2);
}

- (CGPoint)worldToGrid:(CGPoint)position
{
    CGSize screenSize = [[Environment sharedInstance] screenSize];
    float cellHeight = screenSize.height / kNumberOfRows;
    float cellWidth = screenSize.width / kNumberOfColumns;
    return ccp((position.x - cellWidth / 2) / cellWidth,
               (position.y - cellWidth / 2) / cellHeight);
}

- (void)orientationChanged:(NSNotification *)notification
{
    [TestFlight passCheckpoint:@"Tilted the device"];
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            world->SetGravity(b2Vec2(-kWorldGravity, 0.0f));
            secondWorld->SetGravity(b2Vec2(-kWorldGravity, 0.0f));
            break;
        case UIDeviceOrientationLandscapeRight:
            world->SetGravity(b2Vec2(kWorldGravity, 0.0f));
            secondWorld->SetGravity(b2Vec2(kWorldGravity, 0.0f));            
            break;
        case UIDeviceOrientationPortrait:
            world->SetGravity(b2Vec2(0.0f, -kWorldGravity));
            secondWorld->SetGravity(b2Vec2(0.0f, -kWorldGravity));            
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        default:
            world->SetGravity(b2Vec2(0.0f, kWorldGravity));
            secondWorld->SetGravity(b2Vec2(0.0f, kWorldGravity));
            break;
    }
}

#pragma mark -
#pragma mark Clean up

- (void)onExit
{
    [super onExit];
}

#pragma mark -
#pragma mark Update

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    [self addWalls];
    [self addSecondWalls];
    [self addPlayer];
    [self addSecondPlayer];
    [self schedule:@selector(tick:)];
    [self schedule:@selector(checkForWin)];
//    [self restartGame];
}

- (void)restartGame
{
//    [self addPlayer];
//    [self addSecondPlayer];
//    [self schedule:@selector(tick:)];
//    [self schedule:@selector(checkForWin)];
}

#pragma mark -
#pragma mark Accelerometer


#pragma mark -
#pragma mark Physics

- (void)tick:(ccTime)dt
{
    int32 velocityIterations = 10;
    int32 positionIterations = 10;
    
    world->Step(dt, velocityIterations, positionIterations);
    secondWorld->Step(dt, velocityIterations, positionIterations);
    
    for (b2Body *b = world->GetBodyList(); b; b = b->GetNext())
    {
        b->ApplyForce(b2Vec2(world->GetGravity().x, world->GetGravity().y), b->GetPosition());
        if (b->GetUserData() != NULL)
        {
            CCSprite *sprite = (__bridge CCSprite *)b->GetUserData();
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
//            Box2DNode *body = (__bridge Box2DNode*)b->GetUserData();
//            [body updatePhysics:dt];
        }
    }
    for (b2Body *b = secondWorld->GetBodyList(); b; b = b->GetNext())
    {
        b->ApplyForce(b2Vec2(secondWorld->GetGravity().x, secondWorld->GetGravity().y), b->GetPosition());
        if (b->GetUserData() != NULL)
        {
            CCSprite *sprite = (__bridge CCSprite *)b->GetUserData();
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
            //            Box2DNode *body = (__bridge Box2DNode*)b->GetUserData();
            //            [body updatePhysics:dt];
        }
    }
}

- (void)addPlayer
{
    if (playerOneBody != NULL)
    {
        world->DestroyBody(playerOneBody);
        [self.playerOne removeFromParentAndCleanup:YES];
    }
    CGPoint start = [self gridToWorld:self.startPosition];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(start.x / PTM_RATIO, start.y / PTM_RATIO);
    playerOneBody = world->CreateBody(&bodyDef);
    CCSprite *player = [CCSprite spriteWithSpriteFrameName:kBoxSpriteFrameName];
    player.color = kPlayerColor;
    player.position = start;
    [self addChild:player];
    self.playerOne = player;
    playerOneBody->SetUserData((__bridge void *)player);
    b2PolygonShape boxShape;
    boxShape.SetAsBox(38.0f / PTM_RATIO / 2, 38.0f / PTM_RATIO / 2);
    b2FixtureDef playerShapeDef;
    playerShapeDef.shape = &boxShape;
    playerShapeDef.density = 1.0f;
    playerShapeDef.friction = 0.0f;
    playerShapeDef.restitution = 0.0f;
    playerOneBody->CreateFixture(&playerShapeDef);
}

- (void)addSecondPlayer
{
    if (playerTwoBody != NULL)
    {
        world->DestroyBody(playerTwoBody);
        [self.playerOne removeFromParentAndCleanup:YES];
    }
    CGPoint start = [self gridToWorld:self.secondStartPosition];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(start.x / PTM_RATIO, start.y / PTM_RATIO);
    playerTwoBody = secondWorld->CreateBody(&bodyDef);
    CCSprite *player = [CCSprite spriteWithSpriteFrameName:kBoxSpriteFrameName];
    player.color = kPlayerColor;
    player.position = start;
    [self addChild:player];
    self.playerTwo = player;
    playerTwoBody->SetUserData((__bridge void *)player);
    b2PolygonShape boxShape;
    boxShape.SetAsBox(38.0f / PTM_RATIO / 2, 38.0f / PTM_RATIO / 2);
    b2FixtureDef playerShapeDef;
    playerShapeDef.shape = &boxShape;
    playerShapeDef.density = 1.0f;
    playerShapeDef.friction = 0.0f;
    playerShapeDef.restitution = 0.0f;
    playerTwoBody->CreateFixture(&playerShapeDef);
}

- (void)addWalls
{
    CGSize screenSize = [[Environment sharedInstance] screenSize];
    float cellHeight = screenSize.height / kNumberOfRows;
    float cellWidth = screenSize.width / kNumberOfColumns;

    for (int x = 0; x < kNumberOfColumns; x++)
    {
        for (int y = 0; y < kNumberOfRows; y++)
        {
            if ([map member:[NSValue valueWithCGPoint:ccp((float)x, (float)y)]] == nil)
            {
                b2Body *body;
                b2BodyDef bodyDef;
                bodyDef.type = b2_staticBody;
                bodyDef.position.Set(((x * cellWidth) + cellWidth / 2) / PTM_RATIO,
                                     ((y * cellHeight) + cellWidth / 2) / PTM_RATIO);
                body = world->CreateBody(&bodyDef);
                b2PolygonShape boxShape;
                boxShape.SetAsBox(cellWidth / PTM_RATIO / 2, cellHeight / PTM_RATIO / 2);
                b2FixtureDef cellShapeDef;
                cellShapeDef.shape = &boxShape;
                body->CreateFixture(&cellShapeDef);
            }
            else
            {
                CCSprite *wall = [CCSprite spriteWithSpriteFrameName:kBoxSpriteFrameName];
                wall.position = ccp(round((x * cellWidth) + cellWidth / 2), round((y * cellWidth) + cellWidth / 2));
                wall.color = kMapColor;
                [self addChild:wall];
            }
        }
    }
}

- (void)addSecondWalls
{
    CGSize screenSize = [[Environment sharedInstance] screenSize];
    float cellHeight = screenSize.height / kNumberOfRows;
    float cellWidth = screenSize.width / kNumberOfColumns;
    
    for (int x = 0; x < kNumberOfColumns; x++)
    {
        for (int y = 0; y < kNumberOfRows; y++)
        {
            if ([secondMap member:[NSValue valueWithCGPoint:ccp((float)x, (float)y)]] == nil)
            {
                b2Body *body;
                b2BodyDef bodyDef;
                bodyDef.type = b2_staticBody;
                bodyDef.position.Set(((x * cellWidth) + cellWidth / 2) / PTM_RATIO,
                                     ((y * cellHeight) + cellWidth / 2) / PTM_RATIO);
                body = secondWorld->CreateBody(&bodyDef);
                b2PolygonShape boxShape;
                boxShape.SetAsBox(cellWidth / PTM_RATIO / 2, cellHeight / PTM_RATIO / 2);
                b2FixtureDef cellShapeDef;
                cellShapeDef.shape = &boxShape;
                body->CreateFixture(&cellShapeDef);
//                CCSprite *wall = [CCSprite spriteWithSpriteFrameName:kBackgroundSpriteFrameName];
//                wall.position = ccp((x * cellWidth) + cellWidth / 2, (y * cellWidth) + cellWidth / 2);
//                [self addChild:wall];
            }
            else
            {
                CCSprite *wall = [CCSprite spriteWithSpriteFrameName:kBoxSpriteFrameName];
                wall.position = ccp(round((x * cellWidth) + cellWidth / 2), round((y * cellWidth) + cellWidth / 2));
                wall.color = kSecondMapColor;
                if ([map member:[NSValue valueWithCGPoint:ccp((float)x, (float)y)]])
                    wall.opacity = 150.0f;
                [self addChild:wall];
            }
        }
    }
}

#pragma mark -
#pragma mark Debug draw

- (void)draw
{
    [super draw];
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    world->DrawDebugData();
    secondWorld->DrawDebugData();
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
//    int rows = kNumberOfRows;
//    int columns = kNumberOfColumns;
//    CGSize screenSize = [[Environment sharedInstance] screenSize];
//    float cellHeight = screenSize.height / (float)rows;
//    float cellWidth = screenSize.width / (float)columns;
//    
//    for (int i = 0; i < rows; i++)
//        ccDrawLine(ccp(0.0f, i * cellHeight), ccp(screenSize.width, i * cellHeight));
//    for (int i = 0; i < columns; i++)
//        ccDrawLine(ccp(i * cellWidth, 0.0f), ccp(i * cellWidth, screenSize.height));
}

- (void)dealloc
{
    [self removeAllChildrenWithCleanup:YES];
    delete world;
    world = NULL;
    delete secondWorld;
    secondWorld = NULL;
        
    delete m_debugDraw;
    
    self.map = nil;
}

@end
