//
//  PoseMatrixMathHelper.m
//  ARGame
//
//  Created by Cédric Foucault on 10/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "PoseMatrixMathHelper.h"

void getTargetFromCameraMatrix(QCAR::Matrix44F qMatrix, float scale, NGLmat4 result) {
    NGLmat4 matrix, myRebase;
    nglMatrixCopy(qMatrix.data, matrix);
    
    // Reduces the position by size to fit the NinevehGL/OpenGL sytem [0.0, 1.0].
    // By default, the rebase assumes the rotation matrix is already in the NinevehGL format/orientation.
    NGLvec3 position = (NGLvec3) {{matrix[12] / scale, matrix[13] / scale, matrix[14] / scale}};
    matrix[12] /= scale;
    matrix[13] /= scale;
    matrix[14] /= scale;
    
    // Qualcomm has the camera UP vector inverted in relation to NinevehGL.
    NGLQuaternion *quat = [[NGLQuaternion alloc] init];
    [quat rotateByAxis:(NGLvec3){{1.0f, 0.0f, 0.0f}} angle:180.0f mode:NGLAddModeSet];
    nglMatrixMultiply(*quat.matrix, matrix, myRebase);
    
    // Correcting translation component from QCAR coordinate system to NinevehGL coordinate system
    myRebase[12] = position.x;
    myRebase[13] = -position.y;
    myRebase[14] = -position.z;
    // put in result
    nglMatrixCopy(myRebase, result);
}

void getCameraFromTargetMatrix(NGLmat4 targetFromCameraMatrix, NGLmat4 result) {
    // cameraFromTargetMatrix is the inverse of targetFromCameraMatrix
    // computed by: [R | t]' = [R' | -R't]
    
    // Get rotation matrix R;
    NGLmat4 rotationMatrix;
    NGLmat4 rotationMatrixInverse;
    nglMatrixCopy(targetFromCameraMatrix, rotationMatrix);
    rotationMatrix[3] = 0;
    rotationMatrix[7] = 0;
    rotationMatrix[11] = 0;
    rotationMatrix[12] = 0;
    rotationMatrix[13] = 0;
    rotationMatrix[14] = 0;
    rotationMatrix[15] = 0;
    // R' = transpose(R)
    nglMatrixTranspose(rotationMatrix, rotationMatrixInverse);
    
    // Get translation vector -t
    NGLvec3 translationVectorMinus = nglVec3Make(-targetFromCameraMatrix[12],
                                                 -targetFromCameraMatrix[13],
                                                 -targetFromCameraMatrix[14]);
    // "inverse" translation is -R't
    NGLvec3 translationVectorInverse = nglVec3ByMatrix(translationVectorMinus, rotationMatrixInverse);
    // put [R' | -R't] in result
    nglMatrixCopy(rotationMatrixInverse, result);
    result[12] = translationVectorInverse.x;
    result[13] = translationVectorInverse.y;
    result[14] = translationVectorInverse.z;
}

NGLvec3 getCameraPosition(NGLmat4 cameraFromTargetMatrix) {
    // cameraFromTargetMatrix is [R | t]
    // return t
    return nglVec3Make(cameraFromTargetMatrix[12],
                cameraFromTargetMatrix[13],
                cameraFromTargetMatrix[14]);
}

NGLvec3 getCameraViewDirection(NGLmat4 cameraFromTargetMatrix) {
    // cameraFromTargetMatrix is [R | t]
    // return - 3rd column of R
    return nglVec3Make(- cameraFromTargetMatrix[8],
                       - cameraFromTargetMatrix[9],
                       - cameraFromTargetMatrix[10]);
}


void getRotationMatrixFromAxisAngle(NGLvec3 axis, float angleRad, NGLmat4 result) {
    // axis must be normalized
    float cosAngle = cosf(angleRad);
    float sinAngle = sinf(angleRad);
    
    // matrix formula:
    // |  cos(angle) + x.x.(1 - cos(angle))   x.y.(1 - cos(angle)) - z.sin(angle)  x.z.(1 - cos(angle)) + y.sin(angle)  0 |
    // |                                                                                                                  |
    // | y.x.(1 - cos(angle)) + z.sin(angle)   cos(angle) + y.y.(1 - cos(angle))   y.z.(1 - cos(angle) - x.sin(angle)   0 |
    // |                                                                                                                  |
    // | z.x.(1 - cos(angle)) - y.sin(angle)  z.y.(1 - cos(angle)) + x.sin(angle)   cos(angle) + z.z.(1 - cos(angle))   0 |
    // |                                                                                                                  |
    // |                      0                                     0                                  0                1 |
    
    // 4th row
    result[3] = 0;
    result[7] = 0;
    result[11] = 0;
    result[15] = 1;
    // 4th column
    result[12] = 0;
    result[13] = 0;
    result[14] = 0;
    
    // fill 3x3 submatrix
    // 1st column
    result[0] = cosAngle + axis.x * axis.x * (1 - cosAngle);
    result[1] = axis.y * axis.x * (1 - cosAngle) + axis.z * sinAngle;
    result[2] = axis.z * axis.x * (1 - cosAngle) - axis.y * sinAngle;
    // 2nd column
    result[4] = axis.x * axis.y * (1 - cosAngle) - axis.z * sinAngle;
    result[5] = cosAngle + axis.y * axis.y * (1 - cosAngle);
    result[6] = axis.z * axis.y * (1 - cosAngle) + axis.x * sinAngle;
    // 3rd column
    result[8] = axis.x * axis.z * (1 - cosAngle) + axis.y * sinAngle;
    result[9] = axis.y * axis.z * (1 - cosAngle) - axis.x * sinAngle;
    result[10] = cosAngle + axis.z * axis.z * (1 - cosAngle);
}


