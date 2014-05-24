//
//  Beam.m
//  ARGame
//
//  Created by Cédric Foucault on 10/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Beam.h"
#import "Constants.h"
#import "PoseMatrixMathHelper.h"

@interface Beam ()

@property (strong, nonatomic) NGLMesh *billboardMesh;
@property (nonatomic) float *cameraFromTargetMatrixCurrent;

@end


@implementation Beam

- (id)initWithCamera:(NGLCamera *)camera cameraFromTargetMatrix:(float *)cameraFromTargetMatrix collisionWorld:(btCollisionWorld *)collisionWorld {
    self = [super initWithCamera:camera cameraFromTargetMatrix:cameraFromTargetMatrix collisionWorld:collisionWorld];
    if (self) {
        // retain reference to the up-to-date cameraFromTargetMatrix
        _cameraFromTargetMatrixCurrent = cameraFromTargetMatrix;
    }
    return self;
}

- (void)loadMesh {
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                              [NSString stringWithFormat:@"%f", BEAM_CORE_SCALE], kNGLMeshKeyNormalize,
                              nil];
    // load core mesh
    self.mesh = [[NGLMesh alloc] initWithFile:BEAM_CORE_MESH_FILENAME settings:settings delegate:self];
    self.mesh.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_CORE_FRAGMENT_SHADER_FILENAME];
    [self.mesh compileCoreMesh];
    // load billboard to make the object glow
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", BEAM_GLOW_BILLBOARD_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.billboardMesh = [[NGLMesh alloc] initWithFile:BEAM_GLOW_BILLBOARD_MESH_FILENAME
                                              settings:settings delegate:nil];
    self.billboardMesh.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME];
    [self.billboardMesh compileCoreMesh];
    [self.camera addMesh:self.billboardMesh];
    self.billboardMesh.visible = NO;
}

- (void)initCollisionObject {
    self.collisionObject = new btCollisionObject();
    // set basis
    btMatrix3x3 basis;
    basis.setIdentity();
    self.collisionObject->getWorldTransform().setBasis(basis);
    self.collisionObject->getWorldTransform().setFromOpenGLMatrix(*self.mesh.matrix);
    // set sphere collision shape
    btSphereShape *collisionShape = new btSphereShape(BEAM_CORE_SCALE / 2);
    //        boxCollisionShape->setMargin(0.004f);
    self.collisionObject->setCollisionShape(collisionShape);
    // set reference from collision to this object
    self.collisionObject->setUserPointer((__bridge void *)self);
}

- (void)initMotionProperties {
    NGLvec3 cameraPosition = getCameraPosition(self.cameraFromTargetMatrixAtCreation);
    self.mesh.x = cameraPosition.x;
    self.mesh.y = cameraPosition.y;
    self.mesh.z = cameraPosition.z;
    
    self.translationDirection = getCameraViewDirection(self.cameraFromTargetMatrixAtCreation);
    self.translationSpeed = BEAM_SPEED;
    
    [self updateBillboardMesh];
}

- (void)setIsLoaded:(BOOL)isLoaded {
    [super setIsLoaded:isLoaded];
    if (self.isLoaded) {
        // set billboard visible once object is loaded
        self.billboardMesh.visible = YES;
    }
}

- (void)updateFrame {
    [super updateFrame];
    [self updateBillboardMesh];
}

- (void)updateBillboardMesh {
    // update billboard mesh so that it is always attached to the core
    // and that it always faces the camera
    self.billboardMesh.x = self.mesh.x;
    self.billboardMesh.y = self.mesh.y;
    self.billboardMesh.z = self.mesh.z;
    NGLvec3 cameraPosition = getCameraPosition(self.cameraFromTargetMatrixCurrent);
    [self.billboardMesh lookAtPointX:cameraPosition.x toY:cameraPosition.y toZ:cameraPosition.z];
}

- (void)destroy {
    [super destroy];
    [self.camera removeMesh:self.billboardMesh];
}


@end
