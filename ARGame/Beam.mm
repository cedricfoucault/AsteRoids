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

@interface Beam () <NGLMeshDelegate>

@property (nonatomic) btCollisionObject *collisionObject;
@property (nonatomic) NGLvec3 direction;
@property (nonatomic) float speed;

@property (weak, nonatomic) NGLCamera *camera;
@property (nonatomic) btCollisionWorld* collisionWorld;
@end

@implementation Beam

- (id)initWithMesh:(NGLMesh *)mesh camera:(NGLCamera *)camera collisionWorld:(btCollisionWorld *)collisionWorld
            cameraFromTargetMatrix:(float *)cameraFromTargetMatrix {
    self = [super init];
    if (self) {
        // retain references to 3D graphics and physics worlds
        _camera = camera;
        _collisionWorld = collisionWorld;
        // init mesh
        _meshHasLoaded = NO;
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                    kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                    [NSString stringWithFormat:@"%f", BEAM_SCALE], kNGLMeshKeyNormalize,
                    nil];
        self.mesh = [[NGLMesh alloc] initWithFile:BEAM_MESH_FILENAME settings:settings delegate:self];
        // init collision object
//        _collisionObject = new btCollisionObject();
//        btMatrix3x3 basis;
//        basis.setIdentity();
//        _collisionObject->getWorldTransform().setBasis(basis);
        // init motion properties
        [self initMotionPropertiesWithMatrix:cameraFromTargetMatrix];
    }
    return self;
}

- (void)initMotionPropertiesWithMatrix:(NGLmat4)cameraFromTargetMatrix {
    _speed = BEAM_SPEED;
    
    NGLvec3 cameraPosition = getCameraPosition(cameraFromTargetMatrix);
    _mesh.x = cameraPosition.x;
    _mesh.y = cameraPosition.y;
    _mesh.z = cameraPosition.z;
    
    _direction = getCameraViewDirection(cameraFromTargetMatrix);
//    [_mesh rotateToX:_direction.x toY:_direction.y toZ:_direction.z];
}

- (void)updateFrame {
    // update mesh position
//    NSLog(@"%f %f %f", self.mesh.x, self.mesh.y, self.mesh.z);
    self.mesh.x += self.direction.x * self.speed;
    self.mesh.y += self.direction.y * self.speed;
    self.mesh.z += self.direction.z * self.speed;
    // update collision object position
//    self.collisionObject->getWorldTransform().setFromOpenGLMatrix(*self.mesh.matrix);
}

- (void)destroy {
    // remove mesh and collision object from both worlds
    [self.camera removeMesh:self.mesh];
    self.collisionWorld->removeCollisionObject(self.collisionObject);
}

- (void)meshLoadingDidFinish:(NGLParsing)parsing {
    NSLog(@"beam loaded");
    self.meshHasLoaded = YES;
    // set collision bounding box
//    NGLBoundingBox boundingBox = [self.mesh boundingBox];
//    NGLvec3 boxVertex = boundingBox.volume[0];
//    btBoxShape* boxCollisionShape = new btBoxShape(btVector3(fabsf(boxVertex.x),fabsf(boxVertex.x),fabsf(boxVertex.x)));
    //        boxCollisionShape->setMargin(0.004f);
//    self.collisionObject->setCollisionShape(boxCollisionShape);
    // add mesh and collision objects to both worlds
    [self.camera addMesh:self.mesh];
//    self.collisionWorld->addCollisionObject(self.collisionObject);
}


@end
