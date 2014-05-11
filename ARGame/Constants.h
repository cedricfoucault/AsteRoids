//
//  Constants.h
//  ARGame
//
//  Created by Cédric Foucault on 03/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#ifndef ARGame_Constants_h
#define ARGame_Constants_h

extern const float LIGHT_HALF_ATTENUATION;

extern const float FOG_START;
extern const float FOG_END;

extern const float WINDOW_SCALE;
extern const float WINDOW_ASPECT_RATIO;
extern const float PROJECTILE_SCALE;
extern const float BEAM_SCALE;

extern const float SPAWN_DELAY;
extern const float RELOAD_DELAY;
extern const float RELOAD_PROGRESS_TIMER_DELAY;
extern const float BEAM_SPEED;

extern const float SPAWN_DISTANCE;
extern const float SKYDOME_DISTANCE;

extern NSString * const PROJECTILE_MESH_FILENAME;
extern NSString * const BEAM_MESH_FILENAME;
extern NSString * const WINDOW_MESH_FILENAME;
extern NSString * const SKYDOME_MESH_FILENAME;
extern NSString * const LOADED_VIEWFINDER_FILENAME;
extern NSString * const UNLOADED_VIEWFINDER_FILENAME;

extern NSString * const TRACKER_DATASET_FILENAME;
extern char * const TRACKER_TARGET_NAME;

#endif
