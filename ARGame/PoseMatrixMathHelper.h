//
//  PoseMatrixMathHelper.h
//  ARGame
//
//  Created by Cédric Foucault on 10/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <NinevehGL/NinevehGL.h>
#import <QCAR/Tool.h>

void getTargetFromCameraMatrix(float qMatrixData[], float scale, NGLmat4 result);

void getCameraFromTargetMatrix(NGLmat4 targetFromCameraMatrix, NGLmat4 result);
NGLvec3 getCameraPosition(NGLmat4 cameraFromTargetMatrix);
NGLvec3 getCameraViewDirection(NGLmat4 cameraFromTargetMatrix);

void getRotationMatrixFromAxisAngle(NGLvec3 axis, float angleRad, NGLmat4 result);
