//
//  GameScene.h
//  mazze
//
//  Created by Jarod Luebbert on 10/19/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "CCScene.h"
#import "GLES-Render.h"

@interface GameScene : CCScene
{
    b2World *world;
    b2World *secondWorld;
    GLESDebugDraw *m_debugDraw;
    b2MouseJoint *mouseJoint;
    b2Body *groundBody;
    b2Body *playerOneBody;
    b2Body *playerTwoBody;
}

@end
