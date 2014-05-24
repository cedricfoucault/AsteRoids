//
//  GameObject3D.m
//  ARGame
//
//  Created by Cédric Foucault on 11/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "GameObject3D.h"
#import "PoseMatrixMathHelper.h"
#import "Constants.h"

@interface GameObject3D ()

@end

@implementation GameObject3D

- (id)initWithCollisionWorld:(btCollisionWorld *)collisionWorld {
    self = [super init];
    if (self) {
        _isLoaded = NO;
        _cameraManager = [CameraManager sharedManager];
        // retain references to physics worlds
        _collisionWorld = collisionWorld;
        // copy given matrix
        _cameraFromTargetMatrixAtCreation = (float *) malloc(16 * sizeof(float));
        nglMatrixCopy(_cameraManager.cameraFromTargetMatrix, _cameraFromTargetMatrixAtCreation);
        // load 3D mesh
        [self loadMesh];
    }
    return self;
}

- (void)dealloc {
    free(_cameraFromTargetMatrixAtCreation);
}

- (void)updateFrame {
    // update mesh position
    if (self.translationSpeed > 0) {
        self.mesh.x += self.translationDirection.x * self.translationSpeed;
        self.mesh.y += self.translationDirection.y * self.translationSpeed;
        self.mesh.z += self.translationDirection.z * self.translationSpeed;
    }
    // update mesh rotation
    if (self.rotationSpeed > 0) {
        self.mesh.rotationSpace = NGLRotationSpaceLocal;
        NGLmat4 rotationMatrix;
        getRotationMatrixFromAxisAngle(self.rotationAxis, self.rotationSpeed, rotationMatrix);
        [self.mesh rotateRelativeWithMatrix:rotationMatrix];
    }
    // update collision object position
//    nglMatrixDescribe(*(self.mesh.matrix));
    self.collisionObject->getWorldTransform().setFromOpenGLMatrix(*self.mesh.matrix);
}

- (void)destroy {
    // remove mesh and collision object from both worlds
    [self.cameraManager.camera removeMesh:self.mesh];
    self.collisionWorld->removeCollisionObject(self.collisionObject);
}

- (void)loadMesh {
    // subclass should start loading the 3D mesh here, rest of the initialization will follow
}

- (void)meshLoadingDidFinish:(NGLParsing)parsing {
    // get mesh box width and height
    NGLBoundingBox boundingBox = [self.mesh boundingBox];
    self.meshBoxSizeX = boundingBox.volume[3].x - boundingBox.volume[0].x;
    self.meshBoxSizeY = boundingBox.volume[1].y - boundingBox.volume[0].y;
    self.meshBoxSizeZ = boundingBox.volume[4].z - boundingBox.volume[0].z;
    // init motion properties
    [self initMotionProperties];
    // init physics
    [self initCollisionObject];
    // add mesh and collision objects to both worlds
    [self.cameraManager.camera addMesh:self.mesh];
    self.collisionWorld->addCollisionObject(self.collisionObject);
    // done loading
    self.isLoaded = YES;
}

- (void)initMotionProperties {
    // init translation and rotation direction and speed
    // to be overriden by subclasses
}

- (void)initCollisionObject {
    self.collisionObject = new btCollisionObject();
    // set basis
    btMatrix3x3 basis;
    basis.setIdentity();
    self.collisionObject->getWorldTransform().setBasis(basis);
    self.collisionObject->getWorldTransform().setFromOpenGLMatrix(*self.mesh.matrix);
    // set collision bounding box
    btBoxShape* boxCollisionShape = new btBoxShape(btVector3(self.meshBoxSizeX / 2, self.meshBoxSizeY / 2, self.meshBoxSizeZ));
    //        boxCollisionShape->setMargin(0.004f);
    self.collisionObject->setCollisionShape(boxCollisionShape);
    // set reference from collision to this object
    self.collisionObject->setUserPointer((__bridge void *)self);
}

@end
