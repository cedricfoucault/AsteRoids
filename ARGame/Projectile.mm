//
//  Projectile.m
//  ARGame
//
//  Created by Cédric Foucault on 20/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Projectile.h"
#import <NinevehGL/NinevehGL.h>
#import <NinevehGL/NGLMesh.h>
#import "Constants.h"
#import "PoseMatrixMathHelper.h"

//static const float WINDOW_SCALE = 2.0f;
//static const float PROJECTILE_SCALE = 1.0f;

@implementation Projectile

- (id)initWithMesh:(NGLMesh *)mesh camera:(NGLCamera *)camera collisionWorld:(btCollisionWorld *)collisionWorld
    cameraFromTargetMatrix:(float *)cameraFromTargetMatrix {
    self = [super init];
    if (self) {
        // retain references to 3D graphics and physics worlds
        _camera = camera;
        _collisionWorld = collisionWorld;
        // init mesh
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                    kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                    [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
                    nil];
        _mesh = [[NGLMesh alloc] initWithFile:PROJECTILE_MESH_FILENAME settings:settings delegate:self];
        _meshHasLoaded = NO;
        _mesh.delegate = self;
        // init collision object
        _collisionObject = new btCollisionObject();
        btMatrix3x3 basis;
        basis.setIdentity();
        _collisionObject->getWorldTransform().setBasis(basis);
        // get mesh box width and height
        NGLBoundingBox boundingBox = [mesh boundingBox];
        float meshWidth = boundingBox.volume[3].x - boundingBox.volume[0].x;
        float meshHeight = boundingBox.volume[1].y - boundingBox.volume[0].y;
        // init motion properties
        [self initMotionPropertiesWithMatrix:cameraFromTargetMatrix meshWidth:meshWidth meshHeight:meshHeight];
    }
    return self;
}

- (void)initMotionPropertiesWithMatrix:(NGLmat4)cameraFromTargetMatrix meshWidth:(float)width meshHeight:(float)height {
    float d0 = SPAWN_DISTANCE;
    
    float xAtZ0 = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * (WINDOW_SCALE - width);
    float yAtZ0 = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * (WINDOW_SCALE / WINDOW_ASPECT_RATIO - height);
    NSLog(@"xAtZ0: %f, yAtZ0: %f", xAtZ0, yAtZ0);
    _speed = 0.053 + 0.015 * (((float)arc4random() / (float)RAND_MAX) - 0.5);
    //    NSLog(@"%f %f", xAtZ0, yAtZ0);
    NGLvec3 cameraPosition = getCameraPosition(cameraFromTargetMatrix);
    _direction = nglVec3Add(cameraPosition, nglVec3Make(-xAtZ0, -yAtZ0, 0));
    _direction = nglVec3Normalize(_direction);
    _mesh.x = xAtZ0 - d0 * _direction.x;
    _mesh.y = yAtZ0 - d0 * _direction.y;
    _mesh.z = - d0 * _direction.z;
}

- (void)updateFrame {
    // update mesh position
    self.mesh.x += self.direction.x * self.speed;
    self.mesh.y += self.direction.y * self.speed;
    self.mesh.z += self.direction.z * self.speed;
    // update collision object position
    self.collisionObject->getWorldTransform().setFromOpenGLMatrix(*self.mesh.matrix);
}

- (void)destroy {
    // remove mesh and collision object from both worlds
    [self.camera removeMesh:self.mesh];
    self.collisionWorld->removeCollisionObject(self.collisionObject);
}

- (void)meshLoadingDidFinish:(NGLParsing)parsing {
    self.meshHasLoaded = YES;
    // set collision bounding box
    NGLBoundingBox boundingBox = [self.mesh boundingBox];
    NGLvec3 boxVertex = boundingBox.volume[0];
    btBoxShape* boxCollisionShape = new btBoxShape(btVector3(fabsf(boxVertex.x),fabsf(boxVertex.x),fabsf(boxVertex.x)));
    //        boxCollisionShape->setMargin(0.004f);
    self.collisionObject->setCollisionShape(boxCollisionShape);
    // add mesh and collision objects to both worlds
    [self.camera addMesh:self.mesh];
    self.collisionWorld->addCollisionObject(self.collisionObject);
}


@end
