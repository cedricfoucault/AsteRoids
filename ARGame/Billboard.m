//
//  Billboard.m
//  ARGame
//
//  Created by Cédric Foucault on 18/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "Billboard.h"
#import "Constants.h"

@implementation Billboard

- (id)init {
    self = [super init];
    if (self) {
        // Mesh's structure. Each line represents one vertex with all its elements.
        float structures[] =
        {
            -0.3, -0.3, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // position (4), normals (3), texcoord (2)
            0.3, -0.3, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f,
            0.3, 0.3, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,
            -0.3, 0.3, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,
        };
		
        // Mesh's indices. Each line forms a triangle. Only triangles are accepted by OpenGL ES.
        unsigned int indices[] =
        {
            0, 1, 2,
            2, 3, 0,
        };
		
        // Instruction about the elements presents in the structure.
        // The params in order are: Element's name, Starting Index, Length, (internal) always 0.
        NGLMeshElements *elements = [[NGLMeshElements alloc] init];
        [elements addElement:(NGLElement){NGLComponentVertex, 0, 4, 0}];
        [elements addElement:(NGLElement){NGLComponentNormal, 4, 3, 0}];
        [elements addElement:(NGLElement){NGLComponentTexcoord, 7, 2, 0}];
        
        // Defining the mesh's material.
        NGLMaterial *material = [NGLMaterial material];
        material.diffuseMap = [NGLTexture texture2DWithImage:[UIImage imageNamed:@"glow.png"]];
        self.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME];
		
        // Setting the mesh's structure and informing about the counts of the arrays defined above.
        [self setIndices:indices count:6];
        [self setStructures:structures count:36 stride:9];
        [self.meshElements addFromElements:elements];
        self.material = material;
        
        // Compiling the mesh
        [self performSelector:@selector(updateCoreMesh)];
    }
    return self;
}

- (id)initWithScale:(float)scale {
    self = [super init];
    if (self) {
        static const NGLTexture *texture = nil;
        if (texture == nil) {
            texture = [NGLTexture texture2DWithImage:[UIImage imageNamed:@"glow.png"]];
        }
        
        // Mesh's structure. Each line represents one vertex with all its elements.
        float structures[] =
        {
            -scale/2, -scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // position (4), normals (3), texcoord (2)
            scale/2, -scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f,
            scale/2,  scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,
            -scale/2,  scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,
        };
		
        // Mesh's indices. Each line forms a triangle. Only triangles are accepted by OpenGL ES.
        unsigned int indices[] =
        {
            0, 1, 2,
            2, 3, 0,
        };
		
        // Instruction about the elements presents in the structure.
        // The params in order are: Element's name, Starting Index, Length, (internal) always 0.
        NGLMeshElements *elements = [[NGLMeshElements alloc] init];
        [elements addElement:(NGLElement){NGLComponentVertex, 0, 4, 0}];
        [elements addElement:(NGLElement){NGLComponentNormal, 4, 3, 0}];
        [elements addElement:(NGLElement){NGLComponentTexcoord, 7, 2, 0}];
        
        // Defining the mesh's material.
        NGLMaterial *material = [NGLMaterial material];
        material.diffuseMap = texture;
        self.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME];
		
        // Setting the mesh's structure and informing about the counts of the arrays defined above.
        [self setIndices:indices count:6];
        [self setStructures:structures count:36 stride:9];
        [self.meshElements addFromElements:elements];
        self.material = material;
        
        // Compiling the mesh
        [self performSelector:@selector(updateCoreMesh)];
    }
    return self;
}


- (id)initWithTextureNamed:(NSString *)textureName scale:(float)scale {
    self = [super init];
    if (self) {
        // Mesh's structure. Each line represents one vertex with all its elements.
        float structures[] =
        {
            -scale/2, -scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // position (4), normals (3), texcoord (2)
             scale/2, -scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f,
             scale/2,  scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,
            -scale/2,  scale/2, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,
        };
		
        // Mesh's indices. Each line forms a triangle. Only triangles are accepted by OpenGL ES.
        unsigned int indices[] =
        {
            0, 1, 2,
            2, 3, 0,
        };
		
        // Instruction about the elements presents in the structure.
        // The params in order are: Element's name, Starting Index, Length, (internal) always 0.
        NGLMeshElements *elements = [[NGLMeshElements alloc] init];
        [elements addElement:(NGLElement){NGLComponentVertex, 0, 4, 0}];
        [elements addElement:(NGLElement){NGLComponentNormal, 4, 3, 0}];
        [elements addElement:(NGLElement){NGLComponentTexcoord, 7, 2, 0}];
        
        // Defining the mesh's material.
        NGLMaterial *material = [NGLMaterial material];
        material.diffuseMap = [NGLTexture texture2DWithImage:[UIImage imageNamed:textureName]];
        self.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME];
		
        // Setting the mesh's structure and informing about the counts of the arrays defined above.
        [self setIndices:indices count:6];
        [self setStructures:structures count:36 stride:9];
        [self.meshElements addFromElements:elements];
        self.material = material;
        
        // Compiling the mesh
        [self performSelector:@selector(updateCoreMesh)];
    }
    return self;
}

@end
