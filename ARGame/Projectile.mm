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

//static const float WINDOW_SCALE = 2.0f;
//static const float PROJECTILE_SCALE = 1.0f;

@implementation Projectile

- (id)initWithMesh:(NGLMesh *)mesh camera:(NGLCamera *)camera collisionWorld:(btCollisionWorld *)collisionWorld rebase:(float *)rebaseMatrix {
    self = [super init];
    if (self) {
        // retain references to 3D graphics and physics worlds
        _camera = camera;
        _collisionWorld = collisionWorld;
        // init mesh
        _meshHasLoaded = NO;
        _mesh.delegate = self;
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                    kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                    [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
                    nil];
//        _mesh = [[NGLMesh alloc] initWithFile:@"yellow rock.obj" settings:settings delegate:self];
        _mesh = [[NGLMesh alloc] initWithFile:PROJECTILE_MESH_FILENAME settings:settings delegate:self];
//        _mesh.material = [NGLMaterial materialEmerald];
//        [_mesh compileCoreMesh];
        // init collision object
        _collisionObject = new btCollisionObject();
        btMatrix3x3 basis;
        basis.setIdentity();
        _collisionObject->getWorldTransform().setBasis(basis);
        // init motion properties
        [self initMotionPropertiesWithRebase:rebaseMatrix];
    }
    return self;
}

- (void)initMotionPropertiesWithRebase:(NGLmat4)rebaseMatrix {
    float d0 = SPAWN_DISTANCE;
    float margin = 0.2;
    float xAtZ0 = ((float)arc4random() / (float)RAND_MAX - 0.5) * (WINDOW_SCALE - PROJECTILE_SCALE - margin) / 2;
    float yAtZ0 = ((float)arc4random() / (float)RAND_MAX - 0.5) * (WINDOW_SCALE - PROJECTILE_SCALE - margin) / 2;
    _speed = 0.053 + 0.015 * (((float)arc4random() / (float)RAND_MAX) - 0.5);
//    NSLog(@"%f %f", xAtZ0, yAtZ0);
    _direction = nglVec3Add([self playerDirectionWithRebase:rebaseMatrix], nglVec3Make(-xAtZ0, -yAtZ0, 0));
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
    NSLog(@"projectile loaded");
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

- (NGLvec3)playerDirectionWithRebase:(NGLmat4)rebaseMatrix {
    NGLmat4 cameraMatrix;
    nglMatrixCopy(*self.camera.matrix, cameraMatrix);
    float vx = + cameraMatrix[12];
    float vy = + cameraMatrix[13];
    float vz = + cameraMatrix[14];
    NGLvec3 v = nglVec3Make(vx, vy, vz);
    nglVec3Normalize(v);
    return nglVec3ByMatrixTransposed(v, rebaseMatrix);
}


@end
