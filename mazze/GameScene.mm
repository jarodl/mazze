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
#define kBackgroundColor ccc4(177, 235, 255, 255)
#define PTM_RATIO 50.0f
#define kWorldGravity 10.0f
#define kNumberOfRows 12
#define kNumberOfColumns 8
#define kBackgroundSpriteFrameName @"background.png"
#define kPlayerSpriteFrameName @"player.png"

@interface GameScene ()
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, retain) NSSet *map;
- (void)addWalls;
- (void)addPlayer;
- (CGPoint)gridToWorld:(CGPoint)position;
- (void)orientationChanged:(NSNotification *)notification;
@end

@implementation GameScene

@synthesize map;
@synthesize startPosition;

#pragma mark -
#pragma mark Set up

- (id)init
{
    if ((self = [super init]))
    {
        [[ImageLoader sharedInstance] loadSpriteSheet:kObjectsSpriteSheetName];
        self.contentSize = [Environment sharedInstance].screenSize;
        
        // Physics
        b2Vec2 gravity;
        gravity.Set(0.0f, -kWorldGravity);
        bool doSleep = true;
        world = new b2World(gravity, doSleep);
        world->SetContinuousPhysics(true);
        m_debugDraw = new GLESDebugDraw(PTM_RATIO * CC_CONTENT_SCALE_FACTOR());
        uint32 flags = 0;
//        flags += b2DebugDraw::e_shapeBit;
//        flags += b2DebugDraw::e_jointBit;
//        flags += b2DebugDraw::e_aabbBit;
//        flags += b2DebugDraw::e_pairBit;
//        flags += b2DebugDraw::e_centerOfMassBit;
        m_debugDraw->SetFlags(flags);
        world->SetDebugDraw(m_debugDraw);
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
        
        self.map = [NSSet setWithObjects:
                    [NSValue valueWithCGPoint:ccp(1, 0)],
                    [NSValue valueWithCGPoint:ccp(1, 1)],
                    [NSValue valueWithCGPoint:ccp(1, 2)],
                    [NSValue valueWithCGPoint:ccp(2, 2)],
                    [NSValue valueWithCGPoint:ccp(3, 2)],
                    [NSValue valueWithCGPoint:ccp(4, 2)],
                    [NSValue valueWithCGPoint:ccp(5, 2)],
                    [NSValue valueWithCGPoint:ccp(5, 3)],
                    [NSValue valueWithCGPoint:ccp(5, 4)],
                    [NSValue valueWithCGPoint:ccp(5, 5)],
                    [NSValue valueWithCGPoint:ccp(4, 5)],
                    [NSValue valueWithCGPoint:ccp(3, 5)],
                    [NSValue valueWithCGPoint:ccp(3, 6)],
                    [NSValue valueWithCGPoint:ccp(2, 6)],
                    [NSValue valueWithCGPoint:ccp(1, 6)],
                    [NSValue valueWithCGPoint:ccp(1, 7)],
                    [NSValue valueWithCGPoint:ccp(4, 6)],
                    [NSValue valueWithCGPoint:ccp(4, 7)],
                    [NSValue valueWithCGPoint:ccp(4, 8)],
                    [NSValue valueWithCGPoint:ccp(3, 8)],
                    [NSValue valueWithCGPoint:ccp(2, 8)],
                    [NSValue valueWithCGPoint:ccp(2, 9)],
                    [NSValue valueWithCGPoint:ccp(2, 10)],
                    [NSValue valueWithCGPoint:ccp(1, 10)],
                    [NSValue valueWithCGPoint:ccp(1, 11)],
                    [NSValue valueWithCGPoint:ccp(1, 8)],
                    nil];
        self.startPosition = ccp(1, 11);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
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

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            world->SetGravity(b2Vec2(-kWorldGravity, 0.0f));
            break;
        case UIDeviceOrientationLandscapeRight:
            world->SetGravity(b2Vec2(kWorldGravity, 0.0f));
            break;
        case UIDeviceOrientationPortrait:
            world->SetGravity(b2Vec2(0.0f, -kWorldGravity));
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        default:
            world->SetGravity(b2Vec2(0.0f, kWorldGravity));
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
    [self schedule:@selector(tick:)];
    [self addWalls];
    [self addPlayer];
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
}

- (void)addPlayer
{
    CGPoint start = [self gridToWorld:self.startPosition];
    b2Body *body;
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(start.x / PTM_RATIO, start.y / PTM_RATIO);
    body = world->CreateBody(&bodyDef);
    CCSprite *player = [CCSprite spriteWithSpriteFrameName:kPlayerSpriteFrameName];
    player.scale = 0.5f;
    player.position = start;
    [self addChild:player];
    body->SetUserData((__bridge void *)player);
    b2PolygonShape boxShape;
    boxShape.SetAsBox(38.0f / PTM_RATIO / 2, 38.0f / PTM_RATIO / 2);
    b2FixtureDef playerShapeDef;
    playerShapeDef.shape = &boxShape;
    playerShapeDef.density = 1.0f;
    playerShapeDef.friction = 0.0f;
    playerShapeDef.restitution = 0.0f;
    body->CreateFixture(&playerShapeDef);
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
                CCSprite *wall = [CCSprite spriteWithSpriteFrameName:kBackgroundSpriteFrameName];
                wall.position = ccp((x * cellWidth) + cellWidth / 2, (y * cellWidth) + cellWidth / 2);
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
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    int rows = kNumberOfRows;
    int columns = kNumberOfColumns;
    CGSize screenSize = [[Environment sharedInstance] screenSize];
    float cellHeight = screenSize.height / (float)rows;
    float cellWidth = screenSize.width / (float)columns;
    
    for (int i = 0; i < rows; i++)
        ccDrawLine(ccp(0.0f, i * cellHeight), ccp(screenSize.width, i * cellHeight));
    for (int i = 0; i < columns; i++)
        ccDrawLine(ccp(i * cellWidth, 0.0f), ccp(i * cellWidth, screenSize.height));
}

- (void)dealloc
{
    delete world;
    world = NULL;
        
    delete m_debugDraw;
    
    self.map = nil;
}

@end
