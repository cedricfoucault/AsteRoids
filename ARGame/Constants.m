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
const float SPAWN_DISTANCE = 80.0f;
const float SKYWALL_DISTANCE = SPAWN_DISTANCE + 1;
const float SKYDOME_DISTANCE = SKYWALL_DISTANCE;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 4;
const float FOG_START= SKYWALL_DISTANCE / 2;
const float FOG_END = SKYWALL_DISTANCE + 10;
NSString * const PROJECTILE_MESH_FILENAME = @"BlueRock.obj";
NSString * const WINDOW_MESH_FILENAME = @"Plane.obj";
NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
