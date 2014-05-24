//
//  GameObject3D.h
//  ARGame
//
//  Created by Cédric Foucault on 11/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

// This should be subclassed by individual objects

#import <Foundation/Foundation.h>
#import <NinevehGL/NinevehGL.h>
#import "btBulletCollisionCommon.h"
#import "CameraManager.h"

@interface GameObject3D : NSObject <NGLMeshDelegate>

@property (strong, nonatomic) NGLMesh *mesh; // representation of the object in the 3D graphics engine
@property (nonatomic) btCollisionObject *collisionObject; // representation of the object in the physics engine

@property (nonatomic) BOOL isLoaded; // true when object has been loaded into the game world

// motion properties
@property (nonatomic) NGLvec3 translationDirection;
@property (nonatomic) float translationSpeed;
@property (nonatomic) NGLvec3 rotationAxis;
@property (nonatomic) float rotationSpeed;

// references to the physics world
@property (nonatomic) btCollisionWorld* collisionWorld;
@property (weak, nonatomic) CameraManager *cameraManager;

// cameraFromTargetMatrix as it was when the object was created
@property (nonatomic) float *cameraFromTargetMatrixAtCreation;

// bounding box sizes
@property (nonatomic) float meshBoxSizeX;
@property (nonatomic) float meshBoxSizeY;
@property (nonatomic) float meshBoxSizeZ;

//- (id)initWithCamera:(NGLCamera *)camera cameraFromTargetMatrix:(float *)cameraFromTargetMatrix
//      collisionWorld:(btCollisionWorld *)collisionWorld;
- (id)initWithCollisionWorld:(btCollisionWorld *)collisionWorld;
- (void)loadMesh; // to be overriden
- (void)initMotionProperties; // to be overriden
- (void)updateFrame;
- (void)destroy;


@end
