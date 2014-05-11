//
//  Beam.h
//  ARGame
//
//  Created by Cédric Foucault on 10/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NinevehGL/NinevehGL.h>
#import "btBulletCollisionCommon.h"

@interface Beam : NSObject

@property (strong, nonatomic) NGLMesh *mesh;
@property (nonatomic) BOOL meshHasLoaded;

- (id)initWithMesh:(NGLMesh *)mesh camera:(NGLCamera *)camera collisionWorld:(btCollisionWorld *)collisionWorld
            cameraFromTargetMatrix:(float *)cameraFromTargetMatrix;
- (void)updateFrame;

@end
