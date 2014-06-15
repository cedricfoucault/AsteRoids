//
//  BeamCatcher.m
//  ARGame
//
//  Created by Cédric Foucault on 14/06/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "BeamCatcher.h"
#import <NinevehGL/NinevehGL.h>
#import "Constants.h"
#import "Beam.h"

@interface BeamCatcher ()

@property (nonatomic, strong) Beam *beam;

@end

@implementation BeamCatcher

- (void)loadMesh {
    //    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
    //                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
    //                              [NSString stringWithFormat:@"%f", ASTEROID_SCALE], kNGLMeshKeyNormalize,
    //                              nil];
    //    self.mesh = [[NGLMesh alloc] initWithFile:ASTEROID_MESH_FILENAME settings:settings delegate:self];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                              [NSString stringWithFormat:@"%f", BEAM_CATCHER_SCALE], kNGLMeshKeyNormalize,
                              nil];
    self.mesh = [[NGLMesh alloc] initWithFile:BEAM_CATCHER_MESH_FILENAME settings:settings delegate:self];
    self.mesh.x = BEAM_CATCHER_X;
    self.mesh.y = BEAM_CATCHER_Y;
    self.mesh.z = BEAM_CATCHER_Z;
}

- (void)updateFrameWithTimeDelta:(float)timeDelta shipSpeed:(float)shipSpeed {
    // static object - skip update
    if (self.beam != nil && self.beam.isLoaded) {
        [self.beam updateFrameWithTimeDelta:0 shipSpeed:0];
    }
}

- (void)commitBeam {
    self.beam = [[Beam alloc] initWithCollisionWorld:self.collisionWorld];
    self.beam.mesh.x = self.mesh.x;
    self.beam.mesh.y = self.mesh.y;
    self.beam.mesh.z = BEAM_CORE_SCALE / 2 + 0.1;
    self.beam.translationSpeed = 0.0f;
    self.beam.motionPropertiesInitialized = TRUE;
}

- (void)destroy {
    [self.beam destroy];
    [super destroy];
}

- (void)meshLoadingDidFinish:(NGLParsing)parsing {
    // get mesh box width and height
    NGLBoundingBox boundingBox = [self.mesh boundingBox];
    self.meshBoxSizeX = boundingBox.volume[3].x - boundingBox.volume[0].x;
    self.meshBoxSizeY = boundingBox.volume[1].y - boundingBox.volume[0].y;
    self.meshBoxSizeZ = boundingBox.volume[4].z - boundingBox.volume[0].z;
    // add mesh and collision objects to both worlds
    [self.cameraManager.camera addMesh:self.mesh];
    // done loading
    self.isLoaded = YES;
}




@end
