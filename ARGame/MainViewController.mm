//
//  MainViewController.m
//  ARGame
//
//  Created by Cédric Foucault on 08/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "MainViewController.h"
#import <NinevehGL/NinevehGL.h>
#import <NinevehGL/NGLObject3D.h>
#import "QCARAppSession.h"
#import <QCAR/TrackerManager.h>
#import <QCAR/Tracker.h>
#import <QCAR/ImageTracker.h>
#import <QCAR/DataSet.h>
#import <QCAR/Trackable.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/ImageTarget.h>
#import <QCAR/Renderer.h>
#import <QCAR/Tool.h>
#import "btBulletCollisionCommon.h"
#import "HUDOverlayView.h"
#import "Projectile.h"
#import "Constants.h"

//static const float WINDOW_SCALE = 2.0f;
//static const float PROJECTILE_SCALE = 1.0f;
//static const float SPAWN_DELAY = 1.15f;

@interface MainViewController () <NGLViewDelegate, NGLMeshDelegate, QCARAppControl>

@property (strong, nonatomic) QCARAppSession *arSession;
@property (strong, nonatomic) NGLMesh *dummy;
@property (strong, nonatomic) NGLMesh *window;
//@property (strong, nonatomic) NGLMesh *skywall;
@property (strong, nonatomic) NGLMesh *skydome;
@property (strong, nonatomic) NGLMesh *wall;
@property (strong, nonatomic) NGLMesh *projectile;
@property (strong, nonatomic) NGLCamera *camera;
@property BOOL useExtendedTracking;

@property (nonatomic) btBroadphaseInterface* physBroadphase;
@property (nonatomic) btCollisionDispatcher*	physDispatcher;
@property (nonatomic) btDefaultCollisionConfiguration* physCollisionConfiguration;
@property (nonatomic) btCollisionWorld* physCollisionWorld;
@property (nonatomic) btCollisionObject* physPlayerObject;
@property (nonatomic) btCollisionObject* physProjectileObject;

@property (nonatomic) float *rebaseMatrix; // keep track of the rebase matrix to update 3D transforms in physics engine
@property (nonatomic) NGLvec3 u0;
@property (nonatomic) BOOL gameHasStarted;
@property (nonatomic) BOOL gameIsPlaying;

@property (strong, nonatomic) IBOutlet HUDOverlayView *hudOverlayView;
@property (strong, nonatomic) UIView *hitOverlayView;
@property (strong, nonatomic) NSTimer *hitTimer;
@property (nonatomic) int playerLifes;
@property (nonatomic) int score;


@property (strong, nonatomic) NSMutableArray *projectiles;
@property (strong, nonatomic) NSTimer *spawnProjectileTimer;

@property (strong, nonatomic) NGLTexture *redTexture;

@end

@implementation MainViewController

- (id)init {
    self = [super init];
    
    if (self) {
        btTransform transform = btTransform();
        transform.setOrigin(btVector3(10.0, 5.0, 100.0));
        btVector3 vec3 = transform.getOrigin();
        NSLog(@"origin: %f %f %f", vec3.getX(), vec3.getY(), vec3.getZ());
        
        // Init AR session
        _arSession = [[QCARAppSession alloc] initWithDelegate:self];
        _useExtendedTracking = YES;
        
        // We use the iOS notification to pause/resume the AR when the application goes (or comeback from) background
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil
                    usingBlock:^(NSNotification *note) {
                                  NSError * error = nil;
                                  if (![self.arSession pauseAR:&error]) {
                                      NSLog(@"Error pausing AR:%@", [error description]);
                                  }
                              }];
        
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil
                    usingBlock:^(NSNotification *note) {
                                  NSError * error = nil;
                                  if(! [self.arSession resumeAR:&error]) {
                                      NSLog(@"Error resuming AR:%@", [error description]);
                                  }
                              }];
        // init the physics
        [self initPhysics];
    
        // init custom properties
        _gameHasStarted = NO;
        _gameIsPlaying = NO;
        _playerLifes = 3;
        _score = 0;
        _projectiles = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)initPhysics {
    // initialize Bullet Physics objects
    
    ///collision configuration contains default setup for memory, collision setup
	_physCollisionConfiguration = new btDefaultCollisionConfiguration();
	///use the default collision dispatcher.
	_physDispatcher = new	btCollisionDispatcher(_physCollisionConfiguration);
    // broadphase algortihm
//	_physBroadphase = new btDbvtBroadphase();
    _physBroadphase = new btSimpleBroadphase();
    // collision world
    _physCollisionWorld = new btCollisionWorld(_physDispatcher, _physBroadphase, _physCollisionConfiguration);
    
    // collision shapes
    _physPlayerObject = new btCollisionObject();
    _physProjectileObject = new btCollisionObject();
    // player collision shape
    btMatrix3x3 basis;
	basis.setIdentity();
	_physPlayerObject->getWorldTransform().setBasis(basis);
    btScalar playerRadius = 0.35;
    btSphereShape *playerSphere = new btSphereShape(playerRadius);
    _physPlayerObject->setCollisionShape(playerSphere);
    _physCollisionWorld->addCollisionObject(_physPlayerObject);
    
    // init rebase matrix to identity
    _rebaseMatrix = (float *) malloc(16 * sizeof(float));
    nglMatrixIdentity(_rebaseMatrix);
    
}

- (void)dealloc {
    // destroy the Bullet Physics objects that were allocated
    delete _physBroadphase;
    delete _physDispatcher;
    delete _physBroadphase;
    free(_rebaseMatrix);
}

- (void)loadView {
    //*************************
	//	NinevehGL Stuff
	//*************************
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
	// Create the NGLView manually (without XIB), with the screen's size and sets its delegate.
	NGLView *nglView = [[NGLView alloc] initWithFrame:screenBounds];
	nglView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	nglView.delegate = self;
    nglView.backgroundColor = [UIColor blackColor];
	// Sets the NGLView as the root view of this View Controller hierarchy.
	self.view = nglView;
    
    //*************************
	//	QCAR Stuff
	//*************************
    CGRect arViewFrame = screenBounds;
    // initialize the AR session
    [self.arSession initAR:QCAR::GL_20 ARViewBoundsSize:arViewFrame.size orientation:UIInterfaceOrientationLandscapeRight];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init touch gesture recognizers
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shotHitTest)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    // Init overlays
    self.hitOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width * 2, self.view.bounds.size.height)];
    [[NSBundle mainBundle] loadNibNamed:@"hudGame" owner:self options:nil];
    [self.view addSubview:self.hudOverlayView];
    self.hitOverlayView.backgroundColor = [UIColor redColor];
    self.hitOverlayView.alpha = 0.85;
    self.hitOverlayView.hidden = YES;
    [self.view addSubview:self.hitOverlayView];
    // Set OpenGL parameters
    nglGlobalColorFormat(NGLColorFormatRGBA);
    nglGlobalFlush();
    
    // Set the world
    //THIS IS ONLY TO AVOID THE "VUFORIA" ERROR
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                @"0.0001", kNGLMeshKeyNormalize,
                nil];
    self.dummy = [[NGLMesh alloc] initWithFile:@"dummy.obj" settings:settings delegate:self];
    self.dummy.y = -0.5f;
    self.dummy.z = -1.0f;
    self.dummy.material = [NGLMaterial material];
    
    // Setting the window
	settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", WINDOW_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.window = [[NGLMesh alloc] initWithFile:WINDOW_MESH_FILENAME settings:settings delegate:self];
    NGLMaterial *blackMaterial = [[NGLMaterial alloc] init];
    blackMaterial.ambientColor = nglColorMake(0.0, 0.0, 0.0, 1.0);
    blackMaterial.diffuseColor = nglColorMake(0.0, 0.0, 0.0, 1.0);
    blackMaterial.emissiveColor = nglColorMake(0.0, 0.0, 0.0, 1.0);
    blackMaterial.specularColor = nglColorMake(0.0, 0.0, 0.0, 1.0);
    blackMaterial.shininess = 0.0;
    self.window.material = blackMaterial;
    [self.window compileCoreMesh];
    self.window.visible = NO;
    
    // Setting the skydome
	settings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSString stringWithFormat:@"%f", SKYDOME_DISTANCE], kNGLMeshKeyNormalize,
                nil];
    self.skydome = [[NGLMesh alloc] initWithFile:SKYDOME_MESH_FILENAME settings:settings delegate:self];
    self.skydome.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:@"StarDome.fsh"];
    [self.skydome compileCoreMesh];
    
    
    // Setting the invisible "occlusion" wall
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", WINDOW_SCALE * 10], kNGLMeshKeyNormalize,
                nil];
    self.wall = [[NGLMesh alloc] initWithFile:@"Wall with hole.obj" settings:settings delegate:self];
    NGLMaterial *transparentMaterial = [[NGLMaterial alloc] init];
    transparentMaterial.alpha = 0.05;
    self.wall.material = transparentMaterial;
    [self.wall compileCoreMesh];
    
    // Setting the projectile
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", PROJECTILE_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.projectile = [[NGLMesh alloc] initWithFile:PROJECTILE_MESH_FILENAME settings:settings delegate:self];
    
	// Set the camera
    self.camera = [[NGLCamera alloc] initWithMeshes:self.dummy, self.window, self.wall, self.skydome, nil];
//	[self.camera autoAdjustAspectRatio:YES animated:YES];
    
    // Set the light
//    nglGlobalLightEffects(NGLLightEffectsOFF);
    nglGlobalLightEffects(NGLLightEffectsON);
    nglGlobalFlush();
    NGLLight *light = [NGLLight defaultLight];
    light.x = 0.0f;
    light.y = 4.0f;
    light.z = 5.0f;
    light.attenuation = LIGHT_HALF_ATTENUATION / 10;
    light.type = NGLLightTypePoint;
    [light lookAtObject:self.window];
    
    // Set the fog
    NGLFog *defaultFog = [NGLFog defaultFog];
    defaultFog.color = nglVec4Make(0, 0, 0, 1);
	defaultFog.type = NGLFogTypeLinear;
//    defaultFog.type = NGLFogTypeNone;
    defaultFog.start = FOG_START;
    defaultFog.end = FOG_END;
    
	// Starts the debug monitor.
//	[[NGLDebug debugMonitor] startWithView:(NGLView *)self.view];
}

- (void)meshLoadingDidFinish:(NGLParsing)parsing {
    // init physics collision object for projectile mesh
    if (parsing.mesh == self.projectile) {
//        NSLog(@"projectile mesh loaded\n");
        btMatrix3x3 basis;
        basis.setIdentity();
        _physProjectileObject->getWorldTransform().setBasis(basis);
        
        NGLBoundingBox boundingBox =  [self.projectile boundingBox];
//        NSLog(@"box volume:");
//        for (int i = 0; i < 8; i++) {
//            NGLvec3 vertex3 = boundingBox.volume[i];
//            NSLog(@"vertex %d: (%f %f %f)", i, vertex3.x, vertex3.y, vertex3.z);
//        }
//        NSLog(@"bounds (aligned):");
//        NSLog(@"min: (%f %f %f); max: (%f %f %f)", boundingBox.aligned.min.x, boundingBox.aligned.min.y, boundingBox.aligned.min.z, boundingBox.aligned.max.x, boundingBox.aligned.max.y, boundingBox.aligned.max.z);
        NGLvec3 boxVertex = boundingBox.volume[0];
        btBoxShape* boxCollisionShape = new btBoxShape(btVector3(fabsf(boxVertex.x),fabsf(boxVertex.x),fabsf(boxVertex.x)));
//        boxCollisionShape->setMargin(0.004f);
        _physProjectileObject->setCollisionShape(boxCollisionShape);
        _physCollisionWorld->addCollisionObject(_physProjectileObject);
    }
}

// draw a frame
- (void) drawView {
    if (self.arSession.cameraIsStarted) {
        QCAR::State state = QCAR::Renderer::getInstance().begin();
        
        // draw video background
        QCAR::Renderer::getInstance().drawVideoBackground();
        
        // Update tracking state
        float scale = 247.f;
		for (int i = 0; i < state.getNumTrackableResults(); ++i) {
			// Get the trackable
			const QCAR::TrackableResult* result = state.getTrackableResult(i);
            const QCAR::Trackable& trackable = result->getTrackable();
            // Get the pose matrix
			QCAR::Matrix44F qMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
            
			if (!strcmp(trackable.getName(), "tarmac")) {
                // get the target scale
                const QCAR::ImageTarget *target = static_cast<const QCAR::ImageTarget*>(&result->getTrackable());
                scale = target->getSize().data[0];
                
                // update rebase matrix
                [self nglRebaseMatrixFromQCARMatrix:qMatrix scale:scale result:self.rebaseMatrix];
                
                // update the rebase matrices of the camera and the light
                [self.camera rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                [[NGLLight defaultLight] rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                
                // notify that we found a target
                [self targetWasFound];
                
                break;
			}
		}
        
        if (self.gameHasStarted && self.gameIsPlaying) {
            // add objects to destroy in an array and destroy them after the collision detection is done
            NSMutableArray *toDestroy = [[NSMutableArray alloc] init];
            // update projectile objects in 3D simulation (graphics and physics)
            for (Projectile *projectile in [self.projectiles copy]) {
                if (projectile.meshHasLoaded) {
                    [projectile updateFrame];
                    if ([self isOutOfBounds:projectile.mesh]) {
                        NSLog(@"destroy (out of bounds)");
                        [toDestroy addObject:projectile];
                    }
                }
            }
            // update player collision object
            NGLmat4 cameraTransform;
            nglMatrixCopy(*self.camera.matrix, cameraTransform);
            self.physPlayerObject->getWorldTransform().setFromOpenGLMatrix(cameraTransform);
            
            // detect collisions
            self.physCollisionWorld->performDiscreteCollisionDetection();
            int numManifolds = self.physCollisionWorld->getDispatcher()->getNumManifolds();
            for (int i = 0; i < numManifolds; i++) {
                btPersistentManifold* contactManifold = self.physCollisionWorld->getDispatcher()->getManifoldByIndexInternal(i);
                const btCollisionObject* obA = static_cast<const btCollisionObject*>(contactManifold->getBody0());
                const btCollisionObject* obB = static_cast<const btCollisionObject*>(contactManifold->getBody1());
                
                int numContacts = contactManifold->getNumContacts();
                if (numContacts > 0) {
//                    NSLog(@"COLLISION!");
                    if (obA == self.physPlayerObject) {
                        // hit player
                        [self playerWasHit];
                        // destroy object that has collided
                        for (Projectile *projectile in [self.projectiles copy]) {
                            if (projectile.meshHasLoaded) {
                                if (obB == projectile.collisionObject) {
                                    NSLog(@"destroy");
                                    [toDestroy addObject:projectile];
                                    break;
                                }
                            }
                        }
                    } else if (obB == self.physPlayerObject) {
                        // hit player
                        [self playerWasHit];
                        // destroy object that has collided
                        for (Projectile *projectile in [self.projectiles copy]) {
                            if (projectile.meshHasLoaded) {
                                if (obA == projectile.collisionObject) {
                                    NSLog(@"destroy");
                                    [toDestroy addObject:projectile];
                                    break;
                                }
                            }
                        }
                    }
                }
                contactManifold->clearManifold();
            }
            
            // Destroy all the objects marked
            for (Projectile *projectile in toDestroy) {
                [self destroyProjectile:projectile];
            }
        }
        
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        if (self.gameHasStarted) {
            // Render
            glDisable(GL_DEPTH_TEST);
            // window object (without occlusion)
            [self.window drawMeshWithCamera:self.camera];
            // rest of the world
            glEnable(GL_DEPTH_TEST);
            [self.camera drawCamera];
        }
        glDisable (GL_BLEND);
        
        QCAR::Renderer::getInstance().end();
    }
}

- (void)shotHitTest {
    NSLog(@"tap");
    if (self.gameIsPlaying) {
        NSLog(@"raycast test");
        btVector3 from(0,0,0.9);
        btVector3 to(0,0, -20);
//        btCollisionWorld::ClosestRayResultCallback closestResults(from,to);
        btCollisionWorld::AllHitsRayResultCallback allResults(from, to);
        // perform raycast
//        self.physCollisionWorld->rayTest(from, to, closestResults);
        self.physCollisionWorld->rayTest(from, to, allResults);
        
        for (int i=0;i<allResults.m_hitFractions.size();i++) {
            const btCollisionObject *objectHit = allResults.m_collisionObjects.at(i);
            if (self.physPlayerObject == objectHit) {
                NSLog(@"player hit...");
            }
            for (Projectile *projectile in [self.projectiles copy]) {
                if (projectile.meshHasLoaded && projectile.collisionObject == objectHit) {
                    NSLog(@"found projectile");
                    [self incrementScore];
                    [self destroyProjectile:projectile];
                    break;
                }
            }
        }
        
//        if (closestResults.hasHit()) {
//            NSLog(@"hit!");
//            const btCollisionObject *objectHit = closestResults.m_collisionObject;
//            if (self.physPlayerObject == objectHit) {
//                NSLog(@"player hit...");
//            }
//            for (Projectile *projectile in [self.projectiles copy]) {
//                if (projectile.meshHasLoaded && projectile.collisionObject == objectHit) {
//                    NSLog(@"found projectile");
//                    [self incrementScore];
//                    [self destroyProjectile:projectile];
//                    break;
//                    
////                    NGLMaterial *material = [[NGLMaterial alloc] init];
////                    material.ambientColor = nglVec4Make(1, 0, 0, 1);
////                    material.diffuseColor = nglVec4Make(1, 0, 0, 1);
////                    projectile.mesh.material = material;
//                }
//            }
//        }
    }
}

- (void)incrementScore {
    self.score++;
    self.hudOverlayView.scoreCountLabel.text = [NSString stringWithFormat:@"%3d", self.score];
}

- (void)nglRebaseMatrixFromQCARMatrix:(QCAR::Matrix44F)qMatrix scale:(float)scale result:(NGLmat4)result {
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

- (NGLvec3)playerDirection {
    NGLmat4 cameraMatrix;
    nglMatrixCopy(*self.camera.matrix, cameraMatrix);
    float vx = + cameraMatrix[12];
    float vy = + cameraMatrix[13];
    float vz = + cameraMatrix[14];
    NGLvec3 v = nglVec3Make(vx, vy, vz);
    nglVec3Normalize(v);
    return nglVec3ByMatrixTransposed(v, self.rebaseMatrix);
}

- (void)targetWasFound {
    if (!self.gameHasStarted) {
        [self startGame];
    }
}

- (void)startGame {
//    float d0 = 15.0f;
//    float d0 = 10.0f;
//    float xAtZ0 = ((float)arc4random() / (float)RAND_MAX) * (WINDOW_SCALE - PROJECTILE_SCALE) / 4;
//    float yAtZ0 = ((float)arc4random() / (float)RAND_MAX) * (WINDOW_SCALE - PROJECTILE_SCALE) / 4;
//    NSLog(@"%f %f", xAtZ0, yAtZ0);
//    self.u0 = nglVec3Add([self playerDirection], nglVec3Make(-xAtZ0, -yAtZ0, 0));
//    self.projectile.x = xAtZ0 - d0 * self.u0.x;
//    self.projectile.y = yAtZ0 - d0 * self.u0.y;
//    self.projectile.z = - d0 * self.u0.z;
    self.gameHasStarted = YES;
    self.gameIsPlaying = YES;
    self.spawnProjectileTimer = [NSTimer scheduledTimerWithTimeInterval:SPAWN_DELAY target:self selector:@selector(spawnProjectile) userInfo:nil repeats:YES];
}

- (void)stopGame {
    [self.spawnProjectileTimer invalidate];
}

- (void)playerWasHit {
    // decrement player lifes
    self.playerLifes--;
    self.hudOverlayView.lifeCountLabel.text = [NSString stringWithFormat:@"%d/3", self.playerLifes];
    // show hit overlay for a certain duration
    if (self.hitTimer) {
        [self.hitTimer invalidate];
    }
    self.hitOverlayView.hidden = NO;
    [self.view setNeedsDisplay];
    NSTimeInterval secondsShown = 0.25;
    self.hitTimer = [NSTimer scheduledTimerWithTimeInterval:secondsShown target:self selector:@selector(hideHitOverlay) userInfo:nil repeats:NO];
}

 - (void)hideHitOverlay {
     self.hitOverlayView.hidden = YES;
     self.hitTimer = nil;
 }

// callback: the AR initialization is done
- (void) onInitARDone:(NSError *)initError {
    if (initError == nil) {
        // start the AR through a call to startAR
        NSError * error = nil;
        [self.arSession startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        if (error) {
            NSLog(@"ERROR: Error starting AR:%@", [error description]);
        }
        
        // by default, we try to set the continuous auto focus mode
        // and we update menu to reflect the state of continuous auto-focus
        bool isContinuousAutofocus = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        if (!isContinuousAutofocus) {
            NSLog(@"ERROR: Could not set continuous autofocus");
        }
    } else {
        NSLog(@"ERROR: Error initializing AR:%@", [initError description]);
    }
    
    // Adjust NGL camera parameters
    const QCAR::CameraCalibration& cameraCalibration = QCAR::CameraDevice::getInstance().getCameraCalibration();
    QCAR::Vec2F size = cameraCalibration.getSize();
    QCAR::Vec2F focalLength = cameraCalibration.getFocalLength();
    float fovRadians = 2 * atan(0.5f * size.data[1] / focalLength.data[1]);
    float fovDegrees = fovRadians * 180.0f / M_PI;
        [self.camera lensPerspective:(size.data[0] / size.data[1]) near:0.01f far:100.0f angle:fovDegrees];
//    [self.camera lensPerspective:(size.data[0] / size.data[1]) near:0.001f far:100.0f angle:fovDegrees];
    
    // print projection matrices
    NSLog(@"INFO: Successfully started AR.");
//    NSLog(@"NGL View Projection Matrix:\n");
//    nglMatrixDescribe(*self.camera.matrixProjection);
//    
//    NGLmat4 matrix;
////    nglMatrixCopy(QCAR::Tool::getProjectionGL(cameraCalibration, 2.0f, 2000.0f).data, matrix);
//    nglMatrixCopy(QCAR::Tool::getProjectionGL(cameraCalibration, 0.001f, 100.0f).data, matrix);
//    NSLog(@"QCAR View Projection Matrix:\n");
//    nglMatrixDescribe(matrix);
}

// initialize the tracker(s)
- (bool) doInitTrackers {
    // Initialize the image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ImageTracker::getClassType());
    if (trackerBase == NULL) {
        NSLog(@"ERROR: Failed to initialize ImageTracker.");
        return false;
    }
    NSLog(@"INFO: Successfully initialized ImageTracker.");
    return true;
}

// deinititalize the tracker(s)
- (bool) doDeinitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ImageTracker::getClassType());
    return true;
}

// initialize the data associated to the tracker(s)
- (bool) doLoadTrackersData {
    QCAR::DataSet *dataSetTarmac = [self loadImageTrackerDataSet:@"Tarmac.xml"];
    if (dataSetTarmac == NULL) {
        NSLog(@"ERROR: Failed to load dataset");
        return false;
    }
    if (! [self activateDataSetTracking:dataSetTarmac]) {
        NSLog(@"ERROR: Failed to activate data set tracking");
        return false;
    }
    
    return true;
}

// unload the data associated to the tracker(s)
- (bool) doUnloadTrackersData {
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL) {
        NSLog(@"ERROR: Failed to unload tracking data set because the ImageTracker has not been initialized.");
        return false;
    }
    QCAR::DataSet *theDataset = imageTracker->getActiveDataSet();
    if (theDataset == NULL) {
        NSLog(@"ERROR: Failed to unload tracking data set because no active dataset was found.");
        return false;
    }
    if (![self deactivateDataSetTracking:theDataset]) {
        NSLog(@"ERROR: Failed to deactivate dataset tracking.");
    }
    return true;
}

// start the tracker(s)
- (bool) doStartTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    if (tracker == NULL) {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
    
    tracker->start();
    return YES;
}

// stop the tracker(s)
- (bool) doStopTrackers {
    // Stop the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    
    if (tracker == NULL) {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
    
    tracker->stop();
    NSLog(@"INFO: successfully stopped tracker");
    return YES;
}

// Load the image tracker data set
- (QCAR::DataSet *)loadImageTrackerDataSet:(NSString*)dataFile {
    NSLog(@"loadImageTrackerDataSet (%@)", dataFile);
    QCAR::DataSet * dataSet = NULL;
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (NULL == imageTracker) {
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = imageTracker->createDataSet();
        
        if (NULL != dataSet) {
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::DataSet::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                imageTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}

// activate the dataset for tracking
- (BOOL)activateDataSetTracking:(QCAR::DataSet *)theDataSet {
    BOOL success = NO;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL) {
        NSLog(@"ERROR: Failed to load tracking data set because the ImageTracker has not been initialized.");
    }
    else {
        // Activate the data set:
        if (!imageTracker->activateDataSet(theDataSet)) {
            NSLog(@"ERROR: Failed to activate data set.");
        }
        else {
            NSLog(@"INFO: Successfully activated data set.");
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        if (![self setExtendedTrackingForDataSet:theDataSet start:self.useExtendedTracking]) {
            NSLog(@"ERROR: Failed to set extended tracking.");
            success = NO;
        } else {
            NSLog(@"INFO: Successfully set extended tracking.");
            success = YES;
        }
    }
    
    return success;
}

- (BOOL) setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking()) {
                NSLog(@"ERROR: Failed to start extended tracking on: %s", trackable->getName());
                result = NO;
            }
        } else {
            if (!trackable->stopExtendedTracking()) {
                NSLog(@"ERROR: Failed to stop extended tracking on: %s", trackable->getName());
                result = NO;
            }
        }
    }
    return result;
}

- (BOOL)deactivateDataSetTracking:(QCAR::DataSet *)theDataSet {
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL) {
        NSLog(@"ERROR: Failed to unload tracking data set because the ImageTracker has not been initialized.");
    }
    else {
        // Activate the data set:
        if (!imageTracker->deactivateDataSet(theDataSet)) {
            NSLog(@"ERROR: Failed to deactivate data set.");
        }
        else {
            success = YES;
        }
    }
    
    return success;
}

- (void)pause {
    self.gameIsPlaying = NO;
}

- (void)resume {
    self.gameIsPlaying = YES;
}

- (void)spawnProjectile {
    NSLog(@"spawn");
    if (self.gameHasStarted && self.gameIsPlaying) {
        Projectile *projectile = [[Projectile alloc] initWithMesh:self.projectile camera:self.camera collisionWorld:self.physCollisionWorld rebase:self.rebaseMatrix];
        [self.projectiles addObject:projectile];
    }
}

- (void)destroyProjectile:(Projectile *)projectile {
    [projectile destroy];
    [self.projectiles removeObject:projectile];
}

- (BOOL)isOutOfBounds:(NGLObject3D *)object3D {
    return (object3D.x > SPAWN_DISTANCE || object3D.y > SPAWN_DISTANCE || object3D.z > SPAWN_DISTANCE || object3D.x < -SPAWN_DISTANCE || object3D.y < -SPAWN_DISTANCE || object3D.z < -SPAWN_DISTANCE);
}

- (BOOL)prefersStatusBarHidden {
    return  YES;
}

@end
