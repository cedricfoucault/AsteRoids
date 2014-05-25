//
//  ParticleManager.m
//  ARGame
//
//  Created by Cédric Foucault on 24/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "ParticleManager.h"

@interface ParticleManager ()

@property (strong, nonatomic) NSMutableArray *particleSystems;

@end

@implementation ParticleManager

+ (ParticleManager *)sharedManager {
    static ParticleManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _particleSystems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addSystem:(ParticleSystem *)system {
    [self.particleSystems addObject:system];
}

- (void)updateWithTimeDelta:(float)timeDelta {
    for (ParticleSystem *system in [self.particleSystems copy]) {
        [system updateWithTimeDelta:timeDelta];
        // destroy system if not alive
        if (!system.isAlive) {
            [self.particleSystems removeObject:system];
        }
    }
}

- (void)renderParticles {
    for (ParticleSystem *system in [self.particleSystems copy]) {
        [system renderParticles];
    }
}


@end
