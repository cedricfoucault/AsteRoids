//
//  Billboard.h
//  ARGame
//
//  Created by Cédric Foucault on 18/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <NinevehGL/NinevehGL.h>

@interface Billboard : NGLMesh

- (id)initWithScale:(float)scale;
- (id)initWithTextureNamed:(NSString *)textureName scale:(float)scale;

@end
