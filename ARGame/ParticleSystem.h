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

@property (nonatomic, getter=isAlive) BOOL alive;

@property (nonatomic) float systemTimeToLive; // how long the whole particle system will be alive

@property (nonatomic) NGLvec3 sourcePosition;
@property (nonatomic) NGLvec3 sourceDirection;
@property (nonatomic) float sourceEmitterTimeToLive; // how long the source will be emitting
@property (nonatomic) float sourceEmissionRate; // how fast the source emits particles

@property (nonatomic) int maxParticles; // max number of particles alive at a given time
@property (nonatomic) float particleTimeToLiveMean, particleTimeToLiveVariance;
@property (nonatomic) NGLvec3 particleStartPositionMean, particleStartPositionVariance;
//@property (nonatomic) float particleDirectionAngleMean, particleDirectionAngleVariance;
@property (nonatomic) float particleSpeedMean, particleSpeedVariance;
@property (nonatomic) float particleStartRotationMean, particleStartRotationVariance;
@property (nonatomic) float particleRotationSpeedMean, particleRotationSpeedVariance;
@property (nonatomic) float particleSizeMean, particleSizeVariance;


- (void)initSystem;
- (void)initSystemWithSourcePosition:(NGLvec3)sourceStartPosition sourceDirection:(NGLvec3)sourceDirection;
- (void)updateWithTimeDelta:(float)timeDelta;
- (void)renderParticles;

@end
