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

@implementation Beam

- (void)loadMesh {
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                              [NSString stringWithFormat:@"%f", BEAM_SCALE], kNGLMeshKeyNormalize,
                              nil];
    self.mesh = [[NGLMesh alloc] initWithFile:BEAM_MESH_FILENAME settings:settings delegate:self];
}

- (void)initMotionProperties {
    NGLvec3 cameraPosition = getCameraPosition(self.cameraFromTargetMatrixAtCreation);
    self.mesh.x = cameraPosition.x;
    self.mesh.y = cameraPosition.y;
    self.mesh.z = cameraPosition.z;
    
    self.translationDirection = getCameraViewDirection(self.cameraFromTargetMatrixAtCreation);
    self.translationSpeed = BEAM_SPEED;
}

@end
