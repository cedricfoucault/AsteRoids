//
//  Constants.h
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#ifndef ARGame_Constants_h
#define ARGame_Constants_h

#define DEG_TO_RAD(X) (X*M_PI/180.0)
#define RANDOM_MINUS_1_TO_1() ((random() / (float)0x3fffffff )-1.0f)
//#define RANDOM_MINUS_1_TO_1() ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5f) * 2

extern const BOOL DEBUG_LOG;
extern const float NEAR;
extern const float FAR;

extern const float LIGHT_HALF_ATTENUATION;

extern const float FOG_START;
extern const float FOG_END;

extern const float WINDOW_SCALE;
extern const float WINDOW_ASPECT_RATIO;
extern const float WALL_SCALE;
extern const float ASTEROID_SCALE;
extern const float BEAM_CORE_SCALE;
extern const float BEAM_GLOW_BILLBOARD_SCALE;

extern const float ASTEROID_MAX_SPEED_ROTATION;

extern const float ASTEROIDS_DENSITY; // number of asteroids / distance unit
extern const float ASTEROIDS_SPAWN_Z;
extern const float ASTEROIDS_SPAWN_X_VARIANCE;
extern const float ASTEROIDS_SPAWN_Y_VARIANCE;

extern const float ASTEROID_SPEED_MEAN; // distance unit / second
extern const float ASTEROID_SPEED_VARIANCE;
extern const float ASTEROID_ROTATION_SPEED_MEAN; // distance unit / second
extern const float ASTEROID_ROTATION_SPEED_VARIANCE;

extern const float SPAWN_DELAY;
extern const float RELOAD_DELAY;
extern const float RELOAD_PROGRESS_TIMER_DELAY;
extern const float BEAM_SPEED;

extern const float SPAWN_DISTANCE;
extern const float SKYDOME_DISTANCE;

extern const float SHIP_ACCELERATION;
extern const float SHIP_SPEED_MAX;

extern const float TIME_SHIP_TRAVEL;
extern const float TIME_SPAWN_ASTEROIDS;

extern const float DESTINATION_PLANET_RADIUS;
extern const float EYE_PLANET_FOCAL;
extern const float DESTINATION_PLANET_START_Z;
extern const float ACCELERATION_TIME;
extern const float MAX_SPEED_TIME;
extern const float TRAVEL_DISTANCE;

extern const int LIFE_MAX;
extern const float LIFE_REGEN_RATE; // life points / s

extern const float CUTOFF_DISTANCE_MIN_Z;
extern const float CUTOFF_DISTANCE_MIN_X;
extern const float CUTOFF_DISTANCE_MIN_Y;
extern const float CUTOFF_DISTANCE_MAX_Z;
extern const float CUTOFF_DISTANCE_MAX_X;
extern const float CUTOFF_DISTANCE_MAX_Y;

extern NSString * const FRAME_MESH_FILENAME;
//extern NSString * const ASTEROID_MESH_FILENAME;
extern NSString * const BEAM_CORE_MESH_FILENAME;
extern NSString * const BEAM_CORE_FRAGMENT_SHADER_FILENAME;
extern NSString * const BEAM_GLOW_BILLBOARD_MESH_FILENAME;
extern NSString * const SKYDOME_MESH_FILENAME;
extern NSString * const DESTINATION_PLANET_MESH_FILENAME;
extern NSString * const BILLBOARD_FRAGMENT_SHADER_FILENAME;
extern NSString * const LOADED_VIEWFINDER_FILENAME;
extern NSString * const UNLOADED_VIEWFINDER_FILENAME;

extern NSString * const TRACKER_DATASET_FILENAME;
extern char * const TRACKER_TARGET_NAME;

extern NSString * const SOUND_SHOT_NAME;
extern NSString * const SOUND_SHOT_EXTENSION;
extern NSString * const SOUND_IMPACT_NAME;
extern NSString * const SOUND_IMPACT_EXTENSION;
extern NSString * const SOUND_EXPLOSION_NAME;
extern NSString * const SOUND_EXPLOSION_EXTENSION;

#endif
