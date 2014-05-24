//
//  Constants.h
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#ifndef ARGame_Constants_h
#define ARGame_Constants_h

extern const BOOL DEBUG_LOG;
extern const float NEAR;
extern const float FAR;

extern const float LIGHT_HALF_ATTENUATION;

extern const float FOG_START;
extern const float FOG_END;

extern const float WINDOW_SCALE;
extern const float WINDOW_ASPECT_RATIO;
extern const float ASTEROID_SCALE;
extern const float BEAM_CORE_SCALE;
extern const float BEAM_GLOW_BILLBOARD_SCALE;

extern const float ASTEROID_MAX_SPEED_ROTATION;

extern const float SPAWN_DELAY;
extern const float RELOAD_DELAY;
extern const float RELOAD_PROGRESS_TIMER_DELAY;
extern const float BEAM_SPEED;

extern const float SPAWN_DISTANCE;
extern const float SKYDOME_DISTANCE;

extern NSString * const ASTEROID_MESH_FILENAME;
extern NSString * const BEAM_CORE_MESH_FILENAME;
extern NSString * const BEAM_CORE_FRAGMENT_SHADER_FILENAME;
extern NSString * const BEAM_GLOW_BILLBOARD_MESH_FILENAME;
extern NSString * const BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME;
extern NSString * const SKYDOME_MESH_FILENAME;
extern NSString * const LOADED_VIEWFINDER_FILENAME;
extern NSString * const UNLOADED_VIEWFINDER_FILENAME;

extern NSString * const TRACKER_DATASET_FILENAME;
extern char * const TRACKER_TARGET_NAME;

#endif
