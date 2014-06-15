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
#import "CameraManager.h"

#define N_PARTICLES_MAX 300
#define PARTICLE_SIZE_MAX 0.04f
#define TTL_MAX 2.25f

typedef struct {
	NGLvec3 position; // position relative to emitter
    NGLvec3 direction; // includes the speed
//    NGLvec4 color;
//    NGLvec4 deltaColor;
    float rotationAngle;
    float rotationSpeed;
    float size;
    float timeToLive;
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

static GLKTextureInfo *texture;
static GLSLProgram *particleShader;
static GLuint inPosition,   // Shader program attributes and uniforms
              inTexCoord,
              u_texture,
              u_VPMatrix;

@interface ParticleSystem()

@property (weak, nonatomic) CameraManager *cameraManager;

@property (nonatomic, getter=isEmitting) BOOL emitting;
@property (nonatomic) float emitCounter; // time counter needed to emit at given emission rate

@property (nonatomic) int particleCount;
@property (nonatomic) Particle *particles;
@property (nonatomic) ParticleQuad *quads;
@property (nonatomic) GLushort *indices;
@property (nonatomic) GLuint verticesID;
//@property (strong, nonatomic) GLKTextureInfo *texture;
//@property (strong, nonatomic) GLSLProgram *particleShader;
//@property (nonatomic) GLuint inPosition,   // Shader program attributes and uniforms
//                             inTexCoord,
//                             u_texture,
//                             u_VPMatrix;

@end

@implementation ParticleSystem

+ (void)initialize {
    [self initGLTexture];
    [self initGLShaders];
}

+ (void)initGLTexture {
    // Load texture
    // Set up options for GLKTextureLoader
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft,
                             nil];
    // Use GLKTextureLoader to load the data into a texture
    NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"debris" ofType:@"png"];
    texture = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
    if (texture == nil) {
        NSLog(@"ERROR - ParticleSystem: could not load texture, %@", [error localizedDescription]);
    }
    // Throw assersion error if loading texture failed
    NSAssert(!error, @"ERROR - ParticleSystem: could not load texture");
}

+ (void)initGLShaders {
    // Compile the shaders we are using...
    particleShader = [[GLSLProgram alloc] initWithVertexShaderFilename:@"particle"
                                                 fragmentShaderFilename:@"particle"];
    
    // ... and add the attributes the shader needs for the vertex position, color and texture st information
    [particleShader addAttribute:@"inPosition"];
    [particleShader addAttribute:@"inTexCoord"];
    
    // Check to make sure everything lnked OK
    if (![particleShader link]) {
        NSLog(@"Linking failed");
        NSLog(@"Program log: %@", [particleShader programLog]);
        NSLog(@"Vertex log: %@", [particleShader vertexShaderLog]);
        NSLog(@"Fragment log: %@", [particleShader fragmentShaderLog]);
        particleShader = nil;
        exit(1);
    }
    
    // Setup the index pointers into the shader for our attributes
    inPosition = [particleShader attributeIndex:@"inPosition"];
    inTexCoord = [particleShader attributeIndex:@"inTexCoord"];
    
    // Tell OpenGL we want to use this program. This must be done before we set up the pointer indexes for the uniform values
    // we need
    [particleShader use];
    
    // Setup our uniform pointer indexes. This must be done after the program is linked and used as uniform indexes are allocated
    // dynamically by OpenGL
    u_texture = [particleShader uniformIndex:@"u_texture"];
    u_VPMatrix = [particleShader uniformIndex:@"u_VPMatrix"];
    //    _u_MVPMatrix = [_particleShader uniformIndex:@"u_MVPMatrix"];
}

- (id)init {
    self = [super init];
    if (self) {
        _cameraManager = [CameraManager sharedManager];
        _alive = YES;
        _emitting = YES;
    }
    return self;
}

- (void)dealloc {
    if (_verticesID) {
        glDeleteBuffers(1, &_verticesID);
    }
//    if (_texture != nil) {
//        GLuint textureID = _texture.name;
//        glDeleteTextures(1, &textureID);
//    }
}

- (void)stop {
	_alive = NO;
}

//- (void)setupParticles {
//	// Allocate the memory necessary for the particle arrays
//	_particles = (Particle *) malloc(sizeof(Particle) * N_PARTICLES_MAX );
//    _quads = (ParticleQuad *) malloc(sizeof(ParticleQuad) * N_PARTICLES_MAX);
//    _indices = (GLushort *) malloc(sizeof(GLushort) * N_PARTICLES_MAX * 6);
//    
//    // Setup system attributes
//    [self initSystem];
//	
//    // Setup all particles quad
//    for(int i = 0; i < N_PARTICLES_MAX; i++) {
//        // Set up texture coordinates
//        _quads[i].bl.texture.x = 0;
//        _quads[i].bl.texture.y = 0;
//        
//        _quads[i].br.texture.x = 1;
//        _quads[i].br.texture.y = 0;
//		
//        _quads[i].tl.texture.x = 0;
//        _quads[i].tl.texture.y = 1;
//        
//        _quads[i].tr.texture.x = 1;
//        _quads[i].tr.texture.y = 1;
//	}
//    
//    // Set up the indices for all particles. This provides an array of indices into the quads array that is used during
//    // rendering. As we are rendering quads there are six indices for each particle as each particle is made of two triangles
//    // that are each defined by three vertices.
//    for(int i = 0; i < N_PARTICLES_MAX;i++) {
//		_indices[i*6+0] = i*4+0;
//		_indices[i*6+1] = i*4+1;
//		_indices[i*6+2] = i*4+2;
//		
//		_indices[i*6+5] = i*4+2;
//		_indices[i*6+4] = i*4+3;
//		_indices[i*6+3] = i*4+1;
//	}
//    
//	// If one of the arrays cannot be allocated throw an assertion as this is bad
//	NSAssert(_particles && _quads && _indices, @"ERROR - ParticleSystem: Could not allocate arrays.");
//    
//	// Generate the vertices VBO
//	glGenBuffers(1, &_verticesID);
//    glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(ParticleQuad) * N_PARTICLES_MAX, _quads, GL_DYNAMIC_DRAW);
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//    
//    // Load texture
//    // Set up options for GLKTextureLoader
//    NSError *error;
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft,
//                             nil];
//    // Use GLKTextureLoader to load the data into a texture
//    NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"debris" ofType:@"png"];
//    _texture = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
//    if (_texture == nil) {
//        NSLog(@"ERROR - ParticleSystem: could not load texture, %@", [error localizedDescription]);
//    }
//    // Throw assersion error if loading texture failed
//    NSAssert(!error, @"ERROR - ParticleSystem: could not load texture");
//    
//    [self setupShaders];
//}

- (void)initGL {
	// Allocate the memory necessary for the particle arrays
	_particles = (Particle *) malloc(sizeof(Particle) * N_PARTICLES_MAX );
    _quads = (ParticleQuad *) malloc(sizeof(ParticleQuad) * N_PARTICLES_MAX);
    _indices = (GLushort *) malloc(sizeof(GLushort) * N_PARTICLES_MAX * 6);
	
    // Setup all particles quad
    for(int i = 0; i < N_PARTICLES_MAX; i++) {
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
    for(int i = 0; i < N_PARTICLES_MAX;i++) {
		_indices[i*6+0] = i*4+0;
		_indices[i*6+1] = i*4+1;
		_indices[i*6+2] = i*4+2;
		
		_indices[i*6+5] = i*4+2;
		_indices[i*6+4] = i*4+3;
		_indices[i*6+3] = i*4+1;
	}
    
	// If one of the arrays cannot be allocated throw an assertion as this is bad
	NSAssert(_particles && _quads && _indices, @"ERROR - ParticleSystem: Could not allocate arrays.");
    
	// Generate the vertices VBO
	glGenBuffers(1, &_verticesID);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ParticleQuad) * N_PARTICLES_MAX, _quads, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
//    // Load texture
//    // Set up options for GLKTextureLoader
//    NSError *error;
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft,
//                             nil];
//    // Use GLKTextureLoader to load the data into a texture
//    NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"debris" ofType:@"png"];
//    _texture = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
//    if (_texture == nil) {
//        NSLog(@"ERROR - ParticleSystem: could not load texture, %@", [error localizedDescription]);
//    }
//    // Throw assersion error if loading texture failed
//    NSAssert(!error, @"ERROR - ParticleSystem: could not load texture");
    
//    [self setupShaders];
}

//- (void)setupShaders {
//    // Compile the shaders we are using...
//    _particleShader = [[GLSLProgram alloc] initWithVertexShaderFilename:@"particle"
//                                                 fragmentShaderFilename:@"particle"];
//    
//    // ... and add the attributes the shader needs for the vertex position, color and texture st information
//    [_particleShader addAttribute:@"inPosition"];
//    [_particleShader addAttribute:@"inTexCoord"];
//    
//    // Check to make sure everything lnked OK
//    if (![_particleShader link]) {
//        NSLog(@"Linking failed");
//        NSLog(@"Program log: %@", [_particleShader programLog]);
//        NSLog(@"Vertex log: %@", [_particleShader vertexShaderLog]);
//        NSLog(@"Fragment log: %@", [_particleShader fragmentShaderLog]);
//        _particleShader = nil;
//        exit(1);
//    }
//    
//    // Setup the index pointers into the shader for our attributes
//    _inPosition = [_particleShader attributeIndex:@"inPosition"];
//    _inTexCoord = [_particleShader attributeIndex:@"inTexCoord"];
//    
//    // Tell OpenGL we want to use this program. This must be done before we set up the pointer indexes for the uniform values
//    // we need
//    [_particleShader use];
//    
//    // Setup our uniform pointer indexes. This must be done after the program is linked and used as uniform indexes are allocated
//    // dynamically by OpenGL
//    _u_texture = [_particleShader uniformIndex:@"u_texture"];
//    _u_VPMatrix = [_particleShader uniformIndex:@"u_VPMatrix"];
//    //    _u_MVPMatrix = [_particleShader uniformIndex:@"u_MVPMatrix"];
//}

- (void)initSystem {
    // counters
    _particleCount = 0;
    _emitCounter = 0.0f;
    // max number of particles at any time
    _maxParticles = N_PARTICLES_MAX;
    // time to live
    _systemTimeToLive = TTL_MAX;
    _particleTimeToLiveMean = TTL_MAX * 0.8;
    _particleTimeToLiveVariance = TTL_MAX - _particleTimeToLiveMean;
    _sourceEmitterTimeToLive = 0.15f;
    _sourceEmissionRate = _maxParticles / _sourceEmitterTimeToLive;
    // source position
    _sourcePosition = nglVec3Make(0.0f, 0.0f, -1.0f);
    _sourceDirection = nglVec3Make(0.0f, 0.0f, 0.0f);
    // start positions
    _particleStartPositionMean = nglVec3Make(0.0f, 0.0f, 0.0f);
    _particleStartPositionVariance = nglVec3Make(0.0f, 0.0f, 0.0f);
    // speed
    _particleSpeedMean = 0.7;
    _particleSpeedVariance = 0.59 * _particleSpeedMean;
    // start rotation
    _particleStartRotationMean = 0;
    _particleStartRotationVariance = 360;
    // rotation speed
    _particleRotationSpeedMean = 0;
    _particleRotationSpeedVariance = 1440;
    // start size
    _particleSizeMean = 0.04;
    _particleSizeVariance = 0.027;
    
    [self initGL];
}

- (void)initSystemWithSourcePosition:(NGLvec3)sourceStartPosition sourceDirection:(NGLvec3)sourceDirection {
    // counters
    _particleCount = 0;
    _emitCounter = 0.0f;
    // max number of particles at any time
    _maxParticles = N_PARTICLES_MAX;
    // time to live
    _systemTimeToLive = TTL_MAX;
    _particleTimeToLiveMean = TTL_MAX * 0.8;
    _particleTimeToLiveVariance = TTL_MAX - _particleTimeToLiveMean;
    _sourceEmitterTimeToLive = 0.15f;
    _sourceEmissionRate = _maxParticles / _sourceEmitterTimeToLive;
    // source position
    _sourcePosition = sourceStartPosition;
    _sourceDirection = sourceDirection;
    // start positions
    _particleStartPositionMean = nglVec3Make(0.0f, 0.0f, 0.0f);
    _particleStartPositionVariance = nglVec3Make(0.0f, 0.0f, 0.0f);
    // speed
    _particleSpeedMean = 0.7;
    _particleSpeedVariance = 0.59 * _particleSpeedMean;
    // start rotation
    _particleStartRotationMean = 0;
    _particleStartRotationVariance = 360;
    // rotation speed
    _particleRotationSpeedMean = 0;
    _particleRotationSpeedVariance = 1440;
    // start size
    _particleSizeMean = 0.04;
    _particleSizeVariance = 0.027;
    
    [self initGL];
}

- (void)updateWithTimeDelta:(float)timeDelta shipSpeed:(float)shipSpeed {
    // update the whole system timeToLive
    _systemTimeToLive -= timeDelta;
    if (_systemTimeToLive <= 0) {
        [self stop];
        return;
    }
    
    // update source
    _sourcePosition = nglVec3Add(_sourcePosition, nglVec3Multiplyf(_sourceDirection, timeDelta));
    
    // emit particles
    if (_emitting) {
        float timePerEmittedParticle = 1.0 / _sourceEmissionRate;
        // update emission counter
		if (_particleCount < _maxParticles) {
            _emitCounter += timeDelta;
        }
        
        // emit particle one at a time and decrement counter accordingly
		while (_particleCount < _maxParticles && _emitCounter > timePerEmittedParticle) {
			[self emitParticle];
			_emitCounter -= timePerEmittedParticle;
		}
        
        // update emission timeToLive
        _sourceEmitterTimeToLive -= timeDelta;
		if (_sourceEmitterTimeToLive <= 0) {
            [self stopEmitting];
        }
	}

    
    // update particles
    int i = 0;
    while (i < _particleCount) {
        Particle *particle = &_particles[i];
        particle->timeToLive -= timeDelta;
        if (particle->timeToLive > 0) {
            // Particle is still alive, update its attributes
            NGLvec3 localTranslation = nglVec3Multiplyf(particle->direction, timeDelta);
            NGLvec3 shipTranslation = nglVec3Make(0, 0, shipSpeed * timeDelta);
            particle->position = nglVec3Add(particle->position, nglVec3Add(localTranslation, shipTranslation));
            particle->rotationAngle += particle->rotationSpeed * timeDelta;
            
            i++;
        } else {
            // The particle is not alive anymore, replace it with the last active particle
			// in the array and reduce the count of particles by one.
            // This causes all active particles to be packed together at the start of the array
            // so that a particle which has run out of life will only drop into this clause once
			if (i != _particleCount - 1) {
                _particles[i] = _particles[_particleCount - 1];
            }
			_particleCount--;
        }
	}
    // update quad vertices using current particles state
    [self updateQuads];
}

- (void)stopEmitting {
    _emitting = NO;
}

- (void)emitParticle {
	// Safety check
	if (_particleCount == _maxParticles) {
        return;
    }
	
	// Take the next particle out of the particle pool we have created and initialize it
	Particle *particle = &_particles[_particleCount];
	[self initParticle:particle];
	
	// Increment the particle count
	_particleCount++;
}

- (void)initParticle:(Particle *)particle {
    particle->timeToLive = MAX(0, _particleTimeToLiveMean + _particleTimeToLiveVariance * RANDOM_MINUS_1_TO_1());
    
    particle->position = nglVec3Add(_particleStartPositionMean,
                                    nglVec3Multiplyf(_particleStartPositionVariance, RANDOM_MINUS_1_TO_1()));
    
    NGLvec3 directionNormed = nglVec3Normalize(nglVec3Make(RANDOM_MINUS_1_TO_1(),
                                                           RANDOM_MINUS_1_TO_1(),
                                                           RANDOM_MINUS_1_TO_1()));
    float speed = _particleSpeedMean + _particleSpeedVariance * RANDOM_MINUS_1_TO_1();
    particle->direction = nglVec3Multiplyf(directionNormed, speed);
    
    particle->rotationAngle = _particleStartRotationMean + _particleStartRotationVariance * RANDOM_MINUS_1_TO_1();
    particle->rotationSpeed = _particleRotationSpeedMean + _particleRotationSpeedVariance * RANDOM_MINUS_1_TO_1();
    
    particle->size = MAX(0, _particleSizeMean + _particleSizeVariance * RANDOM_MINUS_1_TO_1());
}

- (void)updateQuads {
    for(int i = 0; i < _particleCount; i++) {
        //        NGLmat4 modelViewProjection;
        //        [self getBillboardMvpMatrixWithPosition:self.particles[i].position size:self.particles[i].size result:modelViewProjection];
        NGLmat4 modelMatrix;
        NGLvec3 absolutePosition = nglVec3Add(_particles[i].position, _sourcePosition);
        [self getBillboardModelMatrixWithPosition:absolutePosition
                                         rotation:_particles[i].rotationAngle
                                             size:_particles[i].size
                                           result:modelMatrix];
        // Update geometry with current MVP
        _quads[i].bl.vertex = nglVec4ByMatrix(quadVerticesPosition.blPos, modelMatrix);
        _quads[i].br.vertex = nglVec4ByMatrix(quadVerticesPosition.brPos, modelMatrix);
        _quads[i].tr.vertex = nglVec4ByMatrix(quadVerticesPosition.trPos, modelMatrix);
        _quads[i].tl.vertex = nglVec4ByMatrix(quadVerticesPosition.tlPos, modelMatrix);
	}
}

- (void)renderParticles {
//    [self.particleShader use];
    [particleShader use];
    
    // Bind to the texture that has been loaded for this particle system
    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, self.texture.name);
    glBindTexture(GL_TEXTURE_2D, texture.name);
    
	// Bind to the verticesID VBO and popuate it with the necessary vertex, color and texture informaiton
	glBindBuffer(GL_ARRAY_BUFFER, self.verticesID);
    // Using glBufferSubData means that a copy is done from the quads array to the buffer rather than recreating the buffer which
    // would be an allocation and copy. The copy also only takes over the number of live particles. This provides a nice performance
    // boost.
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(ParticleQuad) * _particleCount, self.quads);
    
    // Make sure that the vertex attributes we are using are enabled. This is a cheap call so OK to do each frame
//    glEnableVertexAttribArray(self.inPosition);
    glEnableVertexAttribArray(inPosition);
//    glEnableVertexAttribArray(self.inTexCoord);
    glEnableVertexAttribArray(inTexCoord);
    
    // Configure the vertex pointer which will use the currently bound VBO for its data
    //    glVertexAttribPointer(inPositionAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
//    glVertexAttribPointer(self.inPosition, 4, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
    glVertexAttribPointer(inPosition, 4, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
//    glVertexAttribPointer(self.inTexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), (GLvoid*) offsetof(TexturedColoredVertex, texture));
    glVertexAttribPointer(inTexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), (GLvoid*) offsetof(TexturedColoredVertex, texture));

    
    // Set the blend function based on the configuration
    //    glBlendFunc(blendFuncSource, blendFuncDestination);
    
    // Do not write in Z buffer to prevent particle-particle occlusion
    glDepthMask(GL_FALSE);
    
    // Set the view projection matrix once and for all
    NGLmat4 vpMatrix;
    [self getViewProjectionMatrix:vpMatrix];
//    glUniformMatrix4fv(self.u_VPMatrix, 1, GL_FALSE, vpMatrix);
    glUniformMatrix4fv(u_VPMatrix, 1, GL_FALSE, vpMatrix);
    
	// Now that all of the VBOs have been used to configure the vertices, pointer size and color
	// use glDrawArrays to draw the points
    glDrawElements(GL_TRIANGLES, _particleCount * 6, GL_UNSIGNED_SHORT, self.indices);
    
	// Unbind bound objects
	glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    glDepthMask(GL_TRUE);
}


- (void)getViewProjectionMatrix:(NGLmat4)result {
    // compute view matrix (including the AR pose matrix)
    NGLmat4 viewMatrix;
    nglMatrixMultiply(*self.cameraManager.camera.matrixView, *self.cameraManager.camera.matrix, viewMatrix);
    // multiply by projection matrix to get the final model view projection matrix
    nglMatrixMultiply(*self.cameraManager.camera.matrixProjection, viewMatrix, result);
}

- (void)getBillboardModelMatrixWithPosition:(NGLvec3)position
                                   rotation:(float)rotationAngle
                                       size:(float)size
                                     result:(NGLmat4)result {
    // compute model matrix of the billboard in world coordinate
    NGLmat4 modelMatrix;
    // 4th column = translation, given by the position
    modelMatrix[12] = position.x;
    modelMatrix[13] = position.y;
    modelMatrix[14] = position.z;
    modelMatrix[15] = 1;
    // 3rd column = normal of the billboard's surface = look vector = cameraPos - billboardPos
    NGLvec3 cameraPosition = self.cameraManager.cameraPosition;
    NGLvec3 look = nglVec3Normalize(nglVec3Subtract(cameraPosition, position));
    modelMatrix[8] = look.x * size;
    modelMatrix[9] = look.y * size;
    modelMatrix[10] = look.z * size;
    modelMatrix[11] = 0;
    // 1st column = right vector = worldUp x look = 2nd column of cameraFromTargetMatrix x look
    float radians = DEG_TO_RAD(rotationAngle);
//    NGLvec3 cameraUp = nglVec3Make(self.cameraManager.cameraFromTargetMatrix[4],
//                                   self.cameraManager.cameraFromTargetMatrix[5],
//                                   self.cameraManager.cameraFromTargetMatrix[6]);
//    NGLvec3 rightAt0Deg = nglVec3Cross(cameraUp, look);
//    NGLvec3 upAt0Deg = nglVec3Cross(look, rightAt0Deg);
//    NGLvec3 right = nglVec3Add(nglVec3Multiplyf(rightAt0Deg, cosf(radians)),
//                               nglVec3Multiplyf(upAt0Deg, sinf(radians)));
    // align billboard so that it doesn't rotate when camera spins around its z-axis
    NGLvec3 right = nglVec3Cross(nglVec3Make(sinf(radians), cosf(radians), 0), look);
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
    nglMatrixMultiply(self.cameraManager.targetFromCameraMatrix, modelMatrix, result);
}

@end
