//
//  ParticleManager.h
//  ARGame
//
//  Created by Cédric Foucault on 24/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParticleSystem.h"

@interface ParticleManager : NSObject

+ (ParticleManager *)sharedManager;

- (void)addSystem:(ParticleSystem *)system;
- (void)updateWithTimeDelta:(float)timeDelta shipSpeed:(float)shipSpeed;
- (void)renderParticles;

@end
