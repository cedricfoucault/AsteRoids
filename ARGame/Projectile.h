//
//  Projectile.h
//  ARGame
//
//  Created by Cédric Foucault on 20/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NinevehGL/NinevehGL.h>
#import "btBulletCollisionCommon.h"

@interface Projectile : NSObject <NGLMeshDelegate>

@property (strong, nonatomic) NGLMesh *mesh;
@property (nonatomic) btCollisionObject *collisionObject;
@property (nonatomic) NGLvec3 direction;
@property (nonatomic) float speed;
@property (nonatomic) BOOL meshHasLoaded;

@property (weak, nonatomic) NGLCamera *camera;
@property (nonatomic) btCollisionWorld* collisionWorld;

- (id)initWithMesh:(NGLMesh *)mesh camera:(NGLCamera *)camera collisionWorld:(btCollisionWorld *)collisionWorld rebase:(NGLmat4)rebaseMatrix;
- (void)updateFrame;
- (void)destroy;

@end
