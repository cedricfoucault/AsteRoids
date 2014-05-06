//
//  Constants.c
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Constants.h"

const float WINDOW_SCALE = 1.0f;
const float PROJECTILE_SCALE = 1.0f;
const float SPAWN_DELAY = 1.15f;
const float RELOAD_DELAY = 1.0f;
const float RELOAD_PROGRESS_TIMER_DELAY = 0.02f;
const float SPAWN_DISTANCE = 40.0f;
const float SKYDOME_DISTANCE = SPAWN_DISTANCE + 0.1;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 2;
const float FOG_END = SKYDOME_DISTANCE + 2;
const float FOG_START= FOG_END / 2;
NSString * const PROJECTILE_MESH_FILENAME = @"BlueRock.obj";
NSString * const WINDOW_MESH_FILENAME = @"Plane.obj";
NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
NSString * const LOADED_VIEWFINDER_FILENAME = @"viewfinder white.png";
NSString * const UNLOADED_VIEWFINDER_FILENAME = @"viewfinder red.png";
NSString * const TRACKER_DATASET_FILENAME = @"AsteRoids.xml";
char * const TRACKER_TARGET_NAME = "asteroidsBackground";
