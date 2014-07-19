//
//  PoseMatrixManager.m
//  ARGame
//
//  Created by Cédric Foucault on 24/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "CameraManager.h"
#import "PoseMatrixMathHelper.h"
#include <string.h> // memcpy

static const int FILTER_WINDOW_SIZE = 6;
static const int MATRIX_SIZE = 16;

@interface CameraManager ()

{
    float _qMatricesBuffer[FILTER_WINDOW_SIZE * MATRIX_SIZE];
    float _targetFromCameraMatrix[MATRIX_SIZE];
    float _cameraFromTargetMatrix[MATRIX_SIZE];
    float _qMatrixDataSmoothed[MATRIX_SIZE];
}

@property (nonatomic, readonly) float *qMatricesBuffer;
@property (nonatomic) int bufferPosition;
@property (nonatomic) int bufferTimesWritten;
@property (nonatomic, getter = isBufferFull) BOOL bufferFull;

@end

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
        _bufferPosition = 0;
        _bufferTimesWritten = 0;
        _bufferFull = NO;
    }
    return self;
}

- (float *)qMatricesBuffer {
    return _qMatricesBuffer;
}

- (float *)targetFromCameraMatrix {
    return _targetFromCameraMatrix;
}

- (float *)cameraFromTargetMatrix {
    return _cameraFromTargetMatrix;
}

- (float *)qMatrixDataSmoothed {
    return _qMatrixDataSmoothed;
}

- (void)appendQMatrixData:(QCAR::Matrix44F)qMatrix {
    memcpy(&(_qMatricesBuffer[self.bufferPosition * MATRIX_SIZE]), qMatrix.data, MATRIX_SIZE * sizeof(float));
    if (self.bufferPosition < FILTER_WINDOW_SIZE - 1) {
        self.bufferPosition++;
    } else {
        self.bufferPosition = 0;
    }
    if (!self.isBufferFull) {
        self.bufferTimesWritten++;
        if (self.bufferTimesWritten >= FILTER_WINDOW_SIZE) {
            self.bufferFull = YES;
        }
    }
}

- (void)updateMatricesWithQMatrix:(QCAR::Matrix44F)qMatrix targetScale:(float)scale {
    [self appendQMatrixData:qMatrix];
    [self refreshQMatrixDataSmoothed];
//    getTargetFromCameraMatrix(qMatrix.data, scale, self.targetFromCameraMatrix);
    getTargetFromCameraMatrix(_qMatrixDataSmoothed, scale, _targetFromCameraMatrix);
    getCameraFromTargetMatrix(_targetFromCameraMatrix, _cameraFromTargetMatrix);
}

- (void)refreshQMatrixDataSmoothed {
    for (int i = 0; i < MATRIX_SIZE; i++) {
        _qMatrixDataSmoothed[i] = 0;
        int nMatrices = self.isBufferFull ? FILTER_WINDOW_SIZE : self.bufferTimesWritten;
        for (int j = 0; j < nMatrices; j++) {
            _qMatrixDataSmoothed[i] += self.qMatricesBuffer[j * MATRIX_SIZE + i];
        }
        _qMatrixDataSmoothed[i] /= nMatrices;
    }
}

- (NGLvec3)cameraPosition {
    return getCameraPosition(self.cameraFromTargetMatrix);
}

- (NGLvec3)cameraViewDirection {
    return getCameraViewDirection(self.cameraFromTargetMatrix);
}

@end
