//
//  Constants.c
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Constants.h"

const BOOL DEBUG_LOG = NO;

const float NEAR = 0.01f;
const float FAR = 100.0f;

const float WINDOW_SCALE = 1.0f;
//const float WINDOW_ASPECT_RATIO = 29.7 / 21;
const float WINDOW_ASPECT_RATIO = 1 / 0.772727;
const float WALL_SCALE = 10.0f;
const float ASTEROID_SCALE = 0.2f;

const float BEAM_CORE_SCALE = 0.07f;
const float BEAM_GLOW_BILLBOARD_SCALE = 2.8 * BEAM_CORE_SCALE;

const float ASTEROIDS_DENSITY = 0.5f; // number of asteroids / distance unit
const float ASTEROIDS_SPAWN_Z = -50.0f;
const float ASTEROIDS_SPAWN_X_VARIANCE = 0.4f;
const float ASTEROIDS_SPAWN_Y_VARIANCE = ASTEROIDS_SPAWN_X_VARIANCE / WINDOW_ASPECT_RATIO;

//const float ASTEROID_SPEED_MEAN = 0.25f; // distance unit / second
//const float ASTEROID_SPEED_VARIANCE = 0.25f;
const float ASTEROID_SPEED_MEAN = 0.f; // distance unit / second
const float ASTEROID_SPEED_VARIANCE = 0.f;
const float ASTEROID_ROTATION_SPEED_MEAN = 2.25f; // degrees / second
const float ASTEROID_ROTATION_SPEED_VARIANCE = 2.25f;

const float SPAWN_DELAY = 1.0f;
const float RELOAD_DELAY = 1.2f;
const float RELOAD_PROGRESS_TIMER_DELAY = 0.02f;

const float BEAM_SPEED = 20.0f;
const float SPAWN_DISTANCE = - ASTEROIDS_SPAWN_Z;
//const float SKYDOME_DISTANCE = SPAWN_DISTANCE + 0.1;
const float SKYDOME_DISTANCE = 5.0f;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 2;
const float FOG_END = SPAWN_DISTANCE + 2;
const float FOG_START= FOG_END * 2 / 3;

const float CUTOFF_DISTANCE_MIN_Z = ASTEROIDS_SPAWN_Z - 5.0f;
const float CUTOFF_DISTANCE_MIN_X = - 10.0f;
const float CUTOFF_DISTANCE_MIN_Y = CUTOFF_DISTANCE_MIN_X / WINDOW_ASPECT_RATIO;
const float CUTOFF_DISTANCE_MAX_Z = 15.0f;
const float CUTOFF_DISTANCE_MAX_X = - CUTOFF_DISTANCE_MIN_X;
const float CUTOFF_DISTANCE_MAX_Y = - CUTOFF_DISTANCE_MIN_Y;

NSString * const FRAME_MESH_FILENAME = @"frame_rotated.obj";
NSString * const ASTEROID_MESH_FILENAME = @"BlueRock.obj";
NSString * const BEAM_CORE_MESH_FILENAME = @"beam_core.obj";
NSString * const BEAM_CORE_FRAGMENT_SHADER_FILENAME = @"beam_core.fsh";
NSString * const BEAM_GLOW_BILLBOARD_MESH_FILENAME = @"beam_glow_billboard.obj";
NSString * const BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME = @"beam_glow_billboard.fsh";

NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
NSString * const LOADED_VIEWFINDER_FILENAME = @"viewfinder white.png";
NSString * const UNLOADED_VIEWFINDER_FILENAME = @"viewfinder gray 50%.png";
NSString * const TRACKER_DATASET_FILENAME = @"AsteRoids.xml";
char * const TRACKER_TARGET_NAME = "asteroidsBackground";
