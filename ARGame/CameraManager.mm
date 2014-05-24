//
//  PoseMatrixManager.m
//  ARGame
//
//  Created by Cédric Foucault on 24/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "CameraManager.h"
#import "PoseMatrixMathHelper.h"

@implementation CameraManager

+ (CameraManager *)sharedManager {
    static CameraManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _targetFromCameraMatrix = (float *) malloc(16 * sizeof(float));
        _cameraFromTargetMatrix = (float *) malloc(16 * sizeof(float));
    }
    return self;
}

- (void)dealloc {
    free(_targetFromCameraMatrix);
    free(_cameraFromTargetMatrix);
}

- (void)updateMatricesWithQMatrix:(QCAR::Matrix44F)qMatrix targetScale:(float)scale {
    getTargetFromCameraMatrix(qMatrix, scale, self.targetFromCameraMatrix);
    getCameraFromTargetMatrix(self.targetFromCameraMatrix, self.cameraFromTargetMatrix);
}

- (NGLvec3)cameraPosition {
    return getCameraPosition(self.cameraFromTargetMatrix);
}

- (NGLvec3)cameraViewDirection {
    return getCameraViewDirection(self.cameraFromTargetMatrix);
}

@end
