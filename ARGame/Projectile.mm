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


@implementation Projectile

- (void)loadMesh {
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                              [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
                              nil];
    self.mesh = [[NGLMesh alloc] initWithFile:PROJECTILE_MESH_FILENAME settings:settings delegate:self];
}


- (void)initMotionProperties {
    float maxSize = fmaxf(fmaxf(self.meshBoxSizeX, self.meshBoxSizeY), self.meshBoxSizeZ);
    float r;
    r = randfUniform() - 0.5;
    float xAtZ0 = r * (WINDOW_SCALE - maxSize);
    r = randfUniform() - 0.5;
    float yAtZ0 = r * (WINDOW_SCALE / WINDOW_ASPECT_RATIO - maxSize);
    //    NSLog(@"%f %f", xAtZ0, yAtZ0);
    
    NGLvec3 cameraPosition = getCameraPosition(self.cameraFromTargetMatrixAtCreation);
    self.translationDirection = nglVec3Add(cameraPosition, nglVec3Make(-xAtZ0, -yAtZ0, 0));
    self.translationDirection = nglVec3Normalize(self.translationDirection);
    
    self.mesh.x = xAtZ0 - SPAWN_DISTANCE * self.translationDirection.x;
    self.mesh.y = yAtZ0 - SPAWN_DISTANCE * self.translationDirection.y;
    self.mesh.z = - SPAWN_DISTANCE * self.translationDirection.z;
    
    // init random translation speed
    r = randfUniform() - 0.5;
    self.translationSpeed = 0.053 + 0.015 * r;
    
    // init random rotation (spinning)
    self.rotationSpeed = randfUniform() * ASTEROID_MAX_SPEED_ROTATION;
    self.rotationAxis = nglVec3Normalize(nglVec3Make(randfUniform() - 0.5, randfUniform() - 0.5, randfUniform() - 0.5));
}

float randfUniform() {
    return (float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX;
}

@end
