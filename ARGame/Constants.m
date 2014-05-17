//
//  Constants.c
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Constants.h"

const float WINDOW_SCALE = 1.0f;
const float WINDOW_ASPECT_RATIO = 29.7 / 21;
const float PROJECTILE_SCALE = 0.3f;

const float BEAM_CORE_SCALE = 0.07f;
const float BEAM_GLOW_BILLBOARD_SCALE = 2.8 * BEAM_CORE_SCALE;

const float SPAWN_DELAY = 1.0f;
const float RELOAD_DELAY = 1.2f;
const float RELOAD_PROGRESS_TIMER_DELAY = 0.02f;
const float BEAM_SPEED = 0.1f;
const float SPAWN_DISTANCE = 60.0f;
//const float SKYDOME_DISTANCE = SPAWN_DISTANCE + 0.1;
const float SKYDOME_DISTANCE = 5.0f;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 2;
const float FOG_END = SPAWN_DISTANCE + 2;
const float FOG_START= FOG_END * 2 / 3;

NSString * const PROJECTILE_MESH_FILENAME = @"BlueRock.obj";
NSString * const BEAM_CORE_MESH_FILENAME = @"beam_core.obj";
NSString * const BEAM_CORE_FRAGMENT_SHADER_FILENAME = @"beam_core.fsh";
NSString * const BEAM_GLOW_BILLBOARD_MESH_FILENAME = @"beam_glow_billboard.obj";
NSString * const BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME = @"beam_glow_billboard.fsh";

NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
NSString * const LOADED_VIEWFINDER_FILENAME = @"viewfinder white.png";
NSString * const UNLOADED_VIEWFINDER_FILENAME = @"viewfinder gray 50%.png";
NSString * const TRACKER_DATASET_FILENAME = @"AsteRoids.xml";
char * const TRACKER_TARGET_NAME = "asteroidsBackground";


const float ASTEROID_MAX_SPEED_ROTATION = 0.05;
