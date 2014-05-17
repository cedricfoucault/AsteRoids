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

static const int NUMBER_OF_MESHES = 30;
static const int NUMBER_OF_TEXTURES = 15;

@implementation Projectile

- (void)loadMesh {
//    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
//                              [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
//                              nil];
//    self.mesh = [[NGLMesh alloc] initWithFile:PROJECTILE_MESH_FILENAME settings:settings delegate:self];
    NSString *meshName = [[self class] randomMeshName];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                              [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
                              nil];
    self.mesh = [[NGLMesh alloc] initWithFile:meshName settings:settings delegate:self];
    self.mesh.material = [[self class] randomMaterial];
    [self.mesh compileCoreMesh];
}

+ (NSString *)randomMeshName {
    return [NSString stringWithFormat:@"asteroid%d.obj", (arc4random_uniform(NUMBER_OF_MESHES) + 1)];
}

+ (NGLMaterial *)randomMaterial {
    NGLMaterial *material = [[NGLMaterial alloc] init];
    material.shininess = 96.078431;
    material.ambientColor = nglVec4Make(0.0, 0.0, 0.0, 1.0);
    material.diffuseColor = nglVec4Make(0.64, 0.64, 0.64, 1.0);
    material.specularColor = nglVec4Make(0.090164, 0.090164, 0.090164, 1.0);
    material.diffuseMap = [NGLTexture texture2DWithFile:[self randomTextureName]];
    return material;
}

+ (NSString *)randomTextureName {
    return [NSString stringWithFormat:@"Am%d.jpg", (arc4random_uniform(NUMBER_OF_TEXTURES) + 1)];
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
