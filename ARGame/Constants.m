//
//  Constants.c
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Constants.h"

const float WINDOW_SCALE = 2.0f;
const float PROJECTILE_SCALE = 1.0f;
const float SPAWN_DELAY = 1.15f;
const float SPAWN_DISTANCE = 40.0f;
const float SKYDOME_DISTANCE = SPAWN_DISTANCE + 0.1;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 2;
const float FOG_END = SKYDOME_DISTANCE + 2;
const float FOG_START= FOG_END / 2;
NSString * const PROJECTILE_MESH_FILENAME = @"BlueRock.obj";
NSString * const WINDOW_MESH_FILENAME = @"Plane.obj";
NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
