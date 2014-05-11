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


