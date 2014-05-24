//
//  PoseMatrixManager.h
//  ARGame
//
//  Created by Cédric Foucault on 24/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NinevehGL/NinevehGL.h>
#import <QCAR/Tool.h>

@interface CameraManager : NSObject

+ (CameraManager *)sharedManager;

@property (strong, nonatomic) NGLCamera *camera;
@property (strong, nonatomic) NGLCamera *cameraForTranslucentObjects;
@property (nonatomic) float *targetFromCameraMatrix;
@property (nonatomic) float *cameraFromTargetMatrix;

- (void)updateMatricesWithQMatrix:(QCAR::Matrix44F)qMatrix targetScale:(float)scale;
- (NGLvec3)cameraPosition;
- (NGLvec3)cameraViewDirection;

@end
