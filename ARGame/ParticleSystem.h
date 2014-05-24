//
//  ParticleSystem.h
//  ARGame
//
//  Created by Cédric Foucault on 23/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NinevehGL/NinevehGL.h>

@interface ParticleSystem : NSObject

- (id)initWithCamera:(NGLCamera *)camera cameraFromTargetMatrix:(float *)cameraFromTargetMatrix targetFromCameraMatrix:(float *)targetFromCameraMatrix;
- (void)setupParticles;
- (void)renderParticles;

@end
