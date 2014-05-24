//
//  ParticleSystem.m
//  ARGame
//
//  Created by Cédric Foucault on 23/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "ParticleSystem.h"
#import <GLKit/GLKit.h>
#import "Constants.h"
#import "PoseMatrixMathHelper.h"
#import "GLSLProgram.h"

#define N_PARTICLES_MAX 2000
#define PARTICLE_SIZE 0.006f

typedef struct {
	NGLvec3 position;
    float size;
} Particle;

typedef struct {
    NGLvec4 vertex;
    NGLvec2 texture;
    NGLvec4 color;
} TexturedColoredVertex;

typedef struct {
    TexturedColoredVertex bl;
    TexturedColoredVertex br;
    TexturedColoredVertex tl;
    TexturedColoredVertex tr;
} ParticleQuad;

static const struct {
    NGLvec4 blPos;
    NGLvec4 brPos;
    NGLvec4 tlPos;
    NGLvec4 trPos;
} quadVerticesPosition = {
    nglVec4Make(-0.5f, -0.5f, 0.0f, 1.0),
    nglVec4Make(0.5f, -0.5f, 0.0f, 1.0),
    nglVec4Make(-0.5f, 0.5f, 0.0f, 1.0),
    nglVec4Make(0.5f, 0.5f, 0.0f, 1.0),
};

@interface ParticleSystem()

@property (nonatomic) Particle *particles;
@property (nonatomic) ParticleQuad *quads;
@property (nonatomic) GLushort *indices;
@property (nonatomic) GLuint verticesID;
@property (strong, nonatomic) GLKTextureInfo *texture;
@property (strong, nonatomic) GLSLProgram *particleShader;
@property (nonatomic) GLuint inPosition,   // Shader program attributes and uniforms
                             inTexCoord,
                             u_texture,
                             u_VPMatrix;
@property NGLCamera *camera;
@property (nonatomic) float *targetFromCameraMatrix;
@property (nonatomic) float *cameraFromTargetMatrix;

@end

@implementation ParticleSystem

- (id)initWithCamera:(NGLCamera *)camera cameraFromTargetMatrix:(float *)cameraFromTargetMatrix targetFromCameraMatrix:(float *)targetFromCameraMatrix {
    self = [super init];
    if (self) {
        _camera = camera;
        _cameraFromTargetMatrix = cameraFromTargetMatrix;
        _targetFromCameraMatrix = targetFromCameraMatrix;
    }
    return self;
}

- (void)setupParticles {
	// Allocate the memory necessary for the particle arrays
	_particles = (Particle *) malloc(sizeof(Particle) * N_PARTICLES_MAX );
    _quads = (ParticleQuad *) malloc(sizeof(ParticleQuad) * N_PARTICLES_MAX);
    _indices = (GLushort *) malloc(sizeof(GLushort) * N_PARTICLES_MAX * 6);
    
    // Setup particles
    for(int i=0; i<N_PARTICLES_MAX; i++) {
        // Randomize position
        _particles[i].position.x = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * WINDOW_SCALE;
        _particles[i].position.y = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * WINDOW_SCALE / WINDOW_ASPECT_RATIO;
        _particles[i].position.z = 0.0f;
        
        _particles[i].size = PARTICLE_SIZE;
	}
	
    // Setup all particles quad
    for(int i=0; i<N_PARTICLES_MAX; i++) {
        // Set up texture coordinates
        _quads[i].bl.texture.x = 0;
        _quads[i].bl.texture.y = 0;
        
        _quads[i].br.texture.x = 1;
        _quads[i].br.texture.y = 0;
		
        _quads[i].tl.texture.x = 0;
        _quads[i].tl.texture.y = 1;
        
        _quads[i].tr.texture.x = 1;
        _quads[i].tr.texture.y = 1;
	}
    
    // Set up the indices for all particles. This provides an array of indices into the quads array that is used during
    // rendering. As we are rendering quads there are six indices for each particle as each particle is made of two triangles
    // that are each defined by three vertices.
    for( int i=0;i<N_PARTICLES_MAX;i++) {
		_indices[i*6+0] = i*4+0;
		_indices[i*6+1] = i*4+1;
		_indices[i*6+2] = i*4+2;
		
		_indices[i*6+5] = i*4+2;
		_indices[i*6+4] = i*4+3;
		_indices[i*6+3] = i*4+1;
	}
    
	// If one of the arrays cannot be allocated throw an assertion as this is bad
	NSAssert(_particles && _quads && _indices, @"ERROR - ParticleEmitter: Could not allocate arrays.");
    
	// Generate the vertices VBO
	glGenBuffers(1, &_verticesID);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ParticleQuad) * N_PARTICLES_MAX, _quads, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    // Load texture
    // Set up options for GLKTextureLoader
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft,
                             nil];
    // Use GLKTextureLoader to load the data into a texture
    NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"redTexture" ofType:@"jpg"];
    _texture = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
    if (_texture == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    // Throw assersion error if loading texture failed
    NSAssert(!error, @"Unable to load texture");
    
    [self setupShaders];
    
    //	// By default the particle emitter is active when created
    //	active = YES;
    //
    //	// Set the particle count to zero
    //	particleCount = 0;
    //
    //	// Reset the elapsed time
    //	elapsedTime = 0;
}

- (void)setupShaders {
    // Compile the shaders we are using...
    _particleShader = [[GLSLProgram alloc] initWithVertexShaderFilename:@"particle"
                                                 fragmentShaderFilename:@"particle"];
    
    // ... and add the attributes the shader needs for the vertex position, color and texture st information
    [_particleShader addAttribute:@"inPosition"];
    [_particleShader addAttribute:@"inTexCoord"];
    
    // Check to make sure everything lnked OK
    if (![_particleShader link]) {
        NSLog(@"Linking failed");
        NSLog(@"Program log: %@", [_particleShader programLog]);
        NSLog(@"Vertex log: %@", [_particleShader vertexShaderLog]);
        NSLog(@"Fragment log: %@", [_particleShader fragmentShaderLog]);
        _particleShader = nil;
        exit(1);
    }
    
    // Setup the index pointers into the shader for our attributes
    _inPosition = [_particleShader attributeIndex:@"inPosition"];
    _inTexCoord = [_particleShader attributeIndex:@"inTexCoord"];
    
    // Tell OpenGL we want to use this program. This must be done before we set up the pointer indexes for the uniform values
    // we need
    [_particleShader use];
    
    // Setup our uniform pointer indexes. This must be done after the program is linked and used as uniform indexes are allocated
    // dynamically by OpenGL
    _u_texture = [_particleShader uniformIndex:@"u_texture"];
    _u_VPMatrix = [_particleShader uniformIndex:@"u_VPMatrix"];
    //    _u_MVPMatrix = [_particleShader uniformIndex:@"u_MVPMatrix"];
}

- (void)updateQuads {
    for(int i=0; i<N_PARTICLES_MAX; i++) {
        //        NGLmat4 modelViewProjection;
        //        [self getBillboardMvpMatrixWithPosition:self.particles[i].position size:self.particles[i].size result:modelViewProjection];
        NGLmat4 modelMatrix;
        [self getBillboardModelMatrixWithPosition:self.particles[i].position size:self.particles[i].size result:modelMatrix];
        // Update geometry with current MVP
        _quads[i].bl.vertex = nglVec4ByMatrix(quadVerticesPosition.blPos, modelMatrix);
        _quads[i].br.vertex = nglVec4ByMatrix(quadVerticesPosition.brPos, modelMatrix);
        _quads[i].tr.vertex = nglVec4ByMatrix(quadVerticesPosition.trPos, modelMatrix);
        _quads[i].tl.vertex = nglVec4ByMatrix(quadVerticesPosition.tlPos, modelMatrix);
	}
}

- (void)renderParticles {
    [self.particleShader use];
    
    // Bind to the texture that has been loaded for this particle system
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture.name);
    
	// Bind to the verticesID VBO and popuate it with the necessary vertex, color and texture informaiton
	glBindBuffer(GL_ARRAY_BUFFER, self.verticesID);
    // update quad vertices using current particles state
    [self updateQuads];
    // Using glBufferSubData means that a copy is done from the quads array to the buffer rather than recreating the buffer which
    // would be an allocation and copy. The copy also only takes over the number of live particles. This provides a nice performance
    // boost.
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(ParticleQuad) * N_PARTICLES_MAX, self.quads);
    
    // Make sure that the vertex attributes we are using are enabled. This is a cheap call so OK to do each frame
    glEnableVertexAttribArray(self.inPosition);
    glEnableVertexAttribArray(self.inTexCoord);
    
    // Configure the vertex pointer which will use the currently bound VBO for its data
    //    glVertexAttribPointer(inPositionAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
    glVertexAttribPointer(self.inPosition, 4, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
    glVertexAttribPointer(self.inTexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), (GLvoid*) offsetof(TexturedColoredVertex, texture));
    
    // Set the blend function based on the configuration
    //    glBlendFunc(blendFuncSource, blendFuncDestination);
    
    // Set the view projection matrix once and for all
    NGLmat4 vpMatrix;
    [self getViewProjectionMatrix:vpMatrix];
    glUniformMatrix4fv(self.u_VPMatrix, 1, GL_FALSE, vpMatrix);
    
	// Now that all of the VBOs have been used to configure the vertices, pointer size and color
	// use glDrawArrays to draw the points
    glDrawElements(GL_TRIANGLES, N_PARTICLES_MAX * 6, GL_UNSIGNED_SHORT, self.indices);
    
	// Unbind bound objects
	glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
}


- (void)getViewProjectionMatrix:(NGLmat4)result {
    // compute view matrix (including the AR pose matrix)
    NGLmat4 viewMatrix;
    nglMatrixMultiply(*(self.camera.matrixView), *self.camera.matrix, viewMatrix);
    // multiply by projection matrix to get the final model view projection matrix
    nglMatrixMultiply(*(self.camera.matrixProjection), viewMatrix, result);
}

- (void)getBillboardModelMatrixWithPosition:(NGLvec3)position size:(float)size result:(NGLmat4)result {
    // compute model matrix of the billboard in world coordinate
    NGLmat4 modelMatrix;
    // 4th column = translation, given by the position
    modelMatrix[12] = position.x;
    modelMatrix[13] = position.y;
    modelMatrix[14] = position.z;
    modelMatrix[15] = 1;
    // 3rd column = normal of the billboard's surface = look vector = cameraPos - billboardPos
    NGLvec3 cameraPosition = getCameraPosition(self.cameraFromTargetMatrix);
    NGLvec3 look = nglVec3Normalize(nglVec3Subtract(cameraPosition, position));
    modelMatrix[8] = look.x * size;
    modelMatrix[9] = look.y * size;
    modelMatrix[10] = look.z * size;
    modelMatrix[11] = 0;
    // 1st column = right vector = cameraUp x look = 2nd column of cameraFromTargetMatrix x look
    //    NGLvec3 cameraUp = nglVec3Make(self.cameraFromTargetMatrix[4], self.cameraFromTargetMatrix[5], self.cameraFromTargetMatrix[6]);
    NGLvec3 right = nglVec3Cross(nglVec3Make(0, 1, 0), look);
    modelMatrix[0] = right.x * size;
    modelMatrix[1] = right.y * size;
    modelMatrix[2] = right.z * size;
    modelMatrix[3] = 0;
    // 2nd column = up vector = look x right
    NGLvec3 up = nglVec3Cross(look, right);
    modelMatrix[4] = up.x * size;
    modelMatrix[5] = up.y * size;
    modelMatrix[6] = up.z * size;
    modelMatrix[7] = 0;
    
    // Rebase matrix with current camera pose matrix (AR)
    nglMatrixMultiply(self.targetFromCameraMatrix, modelMatrix, result);
}

@end
