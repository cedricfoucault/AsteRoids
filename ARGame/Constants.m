//
//  Constants.c
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Constants.h"
#import <math.h>

const BOOL DEBUG_LOG = NO;
const BOOL USE_EXTENDED_TRACKING = NO;
//const BOOL APP_PREVIEW = YES;
const BOOL APP_PREVIEW = NO;

const float NEAR = 0.01f;
const float FAR = 100.0f;

const float WINDOW_SCALE = 1.0f;
//const float WINDOW_ASPECT_RATIO = 29.7 / 21;
const float WINDOW_ASPECT_RATIO = 1 / 0.750151;
const float WALL_SCALE = 10.0f;
const float ASTEROID_SCALE = 0.4f;

const float BEAM_CORE_SCALE = 0.11f;
const float BEAM_GLOW_BILLBOARD_SCALE = BEAM_CORE_SCALE;

const float ASTEROIDS_DENSITY = 0.2f; // number of asteroids / distance unit
const float ASTEROIDS_SPAWN_Z = -50.0f;
const float ASTEROIDS_SPAWN_X_VARIANCE = 1.0f;
const float ASTEROIDS_SPAWN_Y_VARIANCE = ASTEROIDS_SPAWN_X_VARIANCE / WINDOW_ASPECT_RATIO;
const float PROBA_GO_THROUGH_WINDOW = 0.28;

const float ASTEROID_SPEED_MEAN = 0.06f; // distance unit / second
const float ASTEROID_SPEED_VARIANCE = 0.06f;
//const float ASTEROID_SPEED_MEAN = 0.f; // distance unit / second
//const float ASTEROID_SPEED_VARIANCE = 0.f;
const float ASTEROID_ROTATION_SPEED_MEAN = 2.25f; // degrees / second
const float ASTEROID_ROTATION_SPEED_VARIANCE = 2.25f;

const float SPAWN_DELAY = 1.0f;
const float RELOAD_DELAY = 0.4f;
const float RELOAD_PROGRESS_TIMER_DELAY = 0.02f;

const float BEAM_SPEED = 34.0f;
const float SPAWN_DISTANCE = - ASTEROIDS_SPAWN_Z;
//const float SKYDOME_DISTANCE = SPAWN_DISTANCE + 0.1;
const float SKYDOME_DISTANCE = 3.0f;
const float LIGHT_HALF_ATTENUATION = SPAWN_DISTANCE * 2;
const float FOG_END = SPAWN_DISTANCE + 2;
const float FOG_START= FOG_END * 2 / 3;

const float CUTOFF_DISTANCE_MIN_Z = ASTEROIDS_SPAWN_Z - 5.0f;
const float CUTOFF_DISTANCE_MIN_X = - 10.0f;
const float CUTOFF_DISTANCE_MIN_Y = CUTOFF_DISTANCE_MIN_X / WINDOW_ASPECT_RATIO;
const float CUTOFF_DISTANCE_MAX_Z = 15.0f;
const float CUTOFF_DISTANCE_MAX_X = - CUTOFF_DISTANCE_MIN_X;
const float CUTOFF_DISTANCE_MAX_Y = - CUTOFF_DISTANCE_MIN_Y;

//const float SHIP_ACCELERATION = 0.05f;
const float SHIP_SPEED_MAX = 5.0f;

const float TIME_SHIP_TRAVEL = 120.0f;
const float TIME_SPAWN_ASTEROIDS = TIME_SHIP_TRAVEL -
    (ASTEROIDS_SPAWN_Z > 0 ? ASTEROIDS_SPAWN_Z : - ASTEROIDS_SPAWN_Z) / SHIP_SPEED_MAX - 4.0f;

const float DESTINATION_PLANET_RADIUS = 21390;
const float DESTINATION_PLANET_END_SCALE = 1 / (WINDOW_ASPECT_RATIO * WINDOW_ASPECT_RATIO);
const float DESTINATION_PLANET_START_SCALE = 0.05;

//const float ACCELERATION_TIME = SHIP_SPEED_MAX / SHIP_ACCELERATION; // time speed is accelerating (spped < max speed)
//const float MAX_SPEED_TIME = TIME_SHIP_TRAVEL - ACCELERATION_TIME; // time going at max speed
//const float TRAVEL_DISTANCE = 0.5 * SHIP_ACCELERATION * ACCELERATION_TIME * ACCELERATION_TIME + SHIP_SPEED_MAX * MAX_SPEED_TIME;

const float SHIP_SPEED_HALF_LIFE = TIME_SHIP_TRAVEL / 5.0f;

//const float EYE_PLANET_FOCAL = TRAVEL_DISTANCE * DESTINATION_PLANET_END_SCALE * DESTINATION_PLANET_START_SCALE /
//    (DESTINATION_PLANET_RADIUS * (DESTINATION_PLANET_END_SCALE - DESTINATION_PLANET_START_SCALE));

//const float DESTINATION_PLANET_START_Z = EYE_PLANET_FOCAL * DESTINATION_PLANET_RADIUS / DESTINATION_PLANET_START_SCALE;

const int LIFE_MAX = 10; // max amount of life
const float LIFE_REGEN_RATE = 0.2; // life points / s


NSString * const WALL_MESH_FILENAME = @"wall_with_hole_marker_dimension.obj";
NSString * const FRAME_MESH_FILENAME = @"grunge_frame.obj";
NSString * const BEAM_CORE_MESH_FILENAME = @"beam_core.obj";
NSString * const BEAM_CORE_FRAGMENT_SHADER_FILENAME = @"beam_core.fsh";
NSString * const BEAM_GLOW_BILLBOARD_MESH_FILENAME = @"beam_glow_billboard.obj";
NSString * const SKYDOME_MESH_FILENAME = @"StarDome.obj";
NSString * const DESTINATION_PLANET_MESH_FILENAME = @"planet_earth_billboard.obj";
NSString * const BILLBOARD_FRAGMENT_SHADER_FILENAME = @"billboard.fsh";
NSString * const BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME = @"beam_glow_billboard.fsh";
NSString * const LOADED_VIEWFINDER_FILENAME = @"viewfinder_thick_white.png";
NSString * const UNLOADED_VIEWFINDER_FILENAME = @"viewfinder_thick_gray.png";
NSString * const TRACKER_DATASET_FILENAME = @"AsteRoids.xml";
char * const TRACKER_TARGET_NAME = "asteroids_marker";

NSString * const SOUND_SHOT_NAME = @"shot2";
NSString * const SOUND_SHOT_EXTENSION = @"wav";
NSString * const SOUND_IMPACT_NAME = @"impact4";
NSString * const SOUND_IMPACT_EXTENSION = @"aiff";
NSString * const SOUND_EXPLOSION_NAME = @"explosion";
NSString * const SOUND_EXPLOSION_EXTENSION = @"wav";
NSString * const SOUND_BOOM_NAME = @"boom";
NSString * const SOUND_BOOM_EXTENSION = @"aiff";
NSString * const SOUND_GAMEOVER_NAME = @"gameover";
NSString * const SOUND_GAMEOVER_EXTENSION = @"wav";
NSString * const SOUND_ENDGAME_NAME = @"success";
NSString * const SOUND_ENDGAME_EXTENSION = @"wav";
NSString * const SOUND_MUSIC_NAME = @"music2Min";
NSString * const SOUND_MUSIC_EXTENSION = @"mp3";
const float SOUND_MUSIC_VOLUME = 0.66f;
NSString * const SOUND_MENU_NAME = @"menu";
NSString * const SOUND_MENU_EXTENSION = @"mp3";
const float SOUND_MENU_VOLUME = 0.66f;

NSString * const FONT_FAMILY_NAME = @"Exo 2.0";
NSString * const FONT_LIGHT_NAME = @"Exo2.0-Light";
NSString * const FONT_REGULAR_NAME = @"Exo2.0-Regular";
NSString * const FONT_MEDIUM_NAME = @"Exo2.0-Medium";
NSString * const FONT_BOLD_NAME = @"Exo2.0-Bold";
const CGFloat FONT_SIZE = 26.0;
const CGFloat FONT_SIZE_SMALL = 13.0;

NSString * const MARKER_IMAGE_URL_STRING = @"http://i.imgur.com/lQIpE6Q.jpg";

