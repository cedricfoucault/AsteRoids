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
#import "Asteroid.h"
#import "Beam.h"
#import "Constants.h"
#import "PoseMatrixMathHelper.h"
#import <GLKit/GLKit.h>
#import "GLSLProgram.h"
#import "ParticleSystem.h"
#import "CameraManager.h"
#import "ParticleManager.h"


@interface MainViewController () <NGLViewDelegate, NGLMeshDelegate, QCARAppControl, UIGestureRecognizerDelegate>

@property (strong, nonatomic) QCARAppSession *arSession;
@property (strong, nonatomic) NGLMesh *dummy;
@property (strong, nonatomic) NGLMesh *skydome;
@property (strong, nonatomic) NGLMesh *wall;
@property (strong, nonatomic) NGLMesh *asteroid;
@property (strong, nonatomic) NGLMesh *beam;
@property (strong, nonatomic) NGLMesh *beamGlowBillboard;
@property BOOL useExtendedTracking;

@property (nonatomic) btBroadphaseInterface* physBroadphase;
@property (nonatomic) btCollisionDispatcher*	physDispatcher;
@property (nonatomic) btDefaultCollisionConfiguration* physCollisionConfiguration;
@property (nonatomic) btCollisionWorld* physCollisionWorld;
@property (nonatomic) btCollisionObject* physPlayerObject;

@property (weak, nonatomic) CameraManager *cameraManager;
@property (nonatomic) NGLvec3 u0;
@property (nonatomic) BOOL gameHasStarted;
@property (nonatomic) BOOL gameIsPlaying;
@property (nonatomic) BOOL gunIsLoaded;

@property (nonatomic) CFAbsoluteTime lastFrameTime;

@property (strong, nonatomic) IBOutlet HUDOverlayView *hudOverlayView;
@property (strong, nonatomic) IBOutlet UIView *overlayViewfinder;
@property (strong, nonatomic) UIView *hitOverlayView;
@property (weak, nonatomic) IBOutlet UIImageView *gunViewfinder;
@property (weak, nonatomic) IBOutlet UIProgressView *reloadProgressView;

@property (strong, nonatomic) NSTimer *hitTimer;
@property (nonatomic) int playerLifes;
@property (nonatomic) int score;

@property (strong, nonatomic) NSMutableArray *gameObjects;
@property (strong, nonatomic) NSTimer *spawnAsteroidTimer;

@property (weak, nonatomic) ParticleManager *particleManager;
//@property (strong, nonatomic) ParticleSystem *particleSystem;

@property (nonatomic) float shipSpeed;
@property (nonatomic) float distanceTraveled;
@property (nonatomic) float spawnDistanceCounter;

@end

@implementation MainViewController

- (id)init {
    self = [super init];
    
    if (self) {
        // Init AR session
        _arSession = [[QCARAppSession alloc] initWithDelegate:self];
        _useExtendedTracking = YES;
        
        // We use the iOS notification to pause/resume the AR when the application goes (or comeback from) background
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil
                    usingBlock:^(NSNotification *note) {
                                  NSError * error = nil;
                                  if (![self.arSession pauseAR:&error]) {
                                      NSLog(@"ERROR pausing AR:%@", [error description]);
                                  }
                              }];
        
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil
                    usingBlock:^(NSNotification *note) {
                                  NSError * error = nil;
                                  if(! [self.arSession resumeAR:&error]) {
                                      NSLog(@"ERROR resuming AR:%@", [error description]);
                                  }
                              }];
        // init the physics
        btTransform transform = btTransform();
        transform.setOrigin(btVector3(10.0, 5.0, 100.0));
        [self initPhysics];
        
        // init custom properties
        _gameHasStarted = NO;
        _gameIsPlaying = NO;
        _playerLifes = 3;
        _score = 0;
        _gameObjects = [[NSMutableArray alloc] init];
        _cameraManager = [CameraManager sharedManager];
        _particleManager = [ParticleManager sharedManager];
        
        _shipSpeed = 0.0;
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
	_physBroadphase = new btDbvtBroadphase();
//    _physBroadphase = new btSimpleBroadphase();
    // collision world
    _physCollisionWorld = new btCollisionWorld(_physDispatcher, _physBroadphase, _physCollisionConfiguration);
    
    // collision shapes
    _physPlayerObject = new btCollisionObject();
    // player collision shape
    btMatrix3x3 basis;
	basis.setIdentity();
	_physPlayerObject->getWorldTransform().setBasis(basis);
    btScalar playerRadius = 0.35;
    btSphereShape *playerSphere = new btSphereShape(playerRadius);
    _physPlayerObject->setCollisionShape(playerSphere);
    _physCollisionWorld->addCollisionObject(_physPlayerObject);
}

- (void)dealloc {
    // destroy the Bullet Physics objects that were allocated
    delete _physDispatcher;
    delete _physBroadphase;
}

- (void)loadView {
    //*************************
	//	NinevehGL Stuff
	//*************************
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
	// Create the NGLView manually with the screen's size and sets its delegate.
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our control subview is on-screen
    if (self.hudOverlayView != nil) {
        if ([touch.view isDescendantOfView:self.hudOverlayView]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init touch gesture recognizers
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];
    
    // Init overlays
    [[NSBundle mainBundle] loadNibNamed:@"OverlayViewfinder" owner:self options:nil];
    [self.view addSubview:self.overlayViewfinder];
    // HUD
    [[NSBundle mainBundle] loadNibNamed:@"hudGame" owner:self options:nil];
    [self.view addSubview:self.hudOverlayView];
    self.hudOverlayView.hidden = YES;
    // Hit
    self.hitOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width * 2, self.view.bounds.size.height)];
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
    
    // Setting the skydome
	settings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSString stringWithFormat:@"%f", SKYDOME_DISTANCE], kNGLMeshKeyNormalize,
                nil];
    self.skydome = [[NGLMesh alloc] initWithFile:SKYDOME_MESH_FILENAME settings:settings delegate:self];
    self.skydome.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:@"StarDome.fsh"];
    [self.skydome compileCoreMesh];
    self.skydome.x = 0;
    self.skydome.y = 0;
    self.skydome.z = 0;
    
    
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
    
    // Setting the asteroid mesh
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", ASTEROID_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.asteroid = [[NGLMesh alloc] initWithFile:ASTEROID_MESH_FILENAME settings:settings delegate:nil];
    
    // Setting the beam
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", BEAM_CORE_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.beam = [[NGLMesh alloc] initWithFile:BEAM_CORE_MESH_FILENAME settings:settings delegate:nil];
    self.beam.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_CORE_FRAGMENT_SHADER_FILENAME];
    [self.beam compileCoreMesh];
    self.beam.visible = NO;
    
    // Test lookAt routine
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", 0.2], kNGLMeshKeyNormalize,
                nil];
    self.beamGlowBillboard = [[NGLMesh alloc] initWithFile:BEAM_GLOW_BILLBOARD_MESH_FILENAME settings:settings delegate:self];
    self.beamGlowBillboard.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_GLOW_BILLBOARD_FRAGMENT_SHADER_FILENAME];
    [self.beamGlowBillboard compileCoreMesh];
    self.beamGlowBillboard.visible = NO;
    
	// Set the camera
    self.cameraManager.camera = [[NGLCamera alloc] initWithMeshes:self.dummy, nil];
    self.cameraManager.cameraForTranslucentObjects = [[NGLCamera alloc] initWithMeshes:nil];
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
    [light lookAtPointX:0.0 toY:0.0 toZ:0.0];
    
    // Set the fog
    NGLFog *defaultFog = [NGLFog defaultFog];
    defaultFog.color = nglVec4Make(0, 0, 0, 1);
	defaultFog.type = NGLFogTypeLinear;
//    defaultFog.type = NGLFogTypeNone;
    defaultFog.start = FOG_START;
    defaultFog.end = FOG_END;
    
	// Starts the debug monitor.
	[[NGLDebug debugMonitor] startWithView:(NGLView *)self.view];
    
//    self.particleSystem = [[ParticleSystem alloc] init];
//    [self.particleSystem initSystem];
//    ParticleSystem *system = [[ParticleSystem alloc] init];
//    [system initSystem];
//    [self.particleManager addSystem:system];
}

//- (void)meshLoadingDidFinish:(NGLParsing)parsing {
//    if (parsing.mesh == self.beamGlowBillboard) {
//        for (int i = 0; i < N_PARTICLES_MAX; i++) {
//            NGLMesh *particle = [self.beamGlowBillboard copyInstance];
//            particle.visible = YES;
//            [particle scaleToX:0.1 toY:0.1 toZ:1.0];
//            particle.x = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * WINDOW_SCALE;
//            particle.y = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX - 0.5) * WINDOW_SCALE / WINDOW_ASPECT_RATIO;
//            particle.z = 0;
//            [self.camera addMesh:particle];
//            [self.particles addObject:particle];
//        }
//    }
//}

static const float sqrt_2 = sqrtf(2);

// draw a frame
- (void) drawView {
    if (self.arSession.cameraIsStarted) {
        CFAbsoluteTime thisFrameTime = CFAbsoluteTimeGetCurrent();
        CFTimeInterval timeDelta = self.lastFrameTime? (thisFrameTime - self.lastFrameTime) : 0.0;
        
        QCAR::State state = QCAR::Renderer::getInstance().begin();
        glDepthRangef(0.0f, 1.0f);
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClearDepthf(1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // draw video background
        QCAR::Renderer::getInstance().drawVideoBackground();
        
        // Update tracking state
        float scale = 1.0f;
		for (int i = 0; i < state.getNumTrackableResults(); ++i) {
			// Get the trackable
			const QCAR::TrackableResult* result = state.getTrackableResult(i);
            const QCAR::Trackable& trackable = result->getTrackable();
            // Get the pose matrix
			QCAR::Matrix44F qMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
            
			if (!strcmp(trackable.getName(), TRACKER_TARGET_NAME)) {
                // get the target scale
                const QCAR::ImageTarget *target = static_cast<const QCAR::ImageTarget*>(&result->getTrackable());
                scale = target->getSize().data[0];
                
                // update rebase matrix
                [self.cameraManager updateMatricesWithQMatrix:qMatrix targetScale:scale];
                
                // update the rebase matrices of the camera and the light
                [self.cameraManager.camera rebaseWithMatrix:qMatrix.data
                                                      scale:scale
                                              compatibility:NGLRebaseQualcommAR];
                [self.cameraManager.cameraForTranslucentObjects rebaseWithMatrix:qMatrix.data
                                                                           scale:scale
                                                                   compatibility:NGLRebaseQualcommAR];
                [[NGLLight defaultLight] rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                [self.skydome rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                [self.wall rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                // move skydome with camera to give illusion of infinity, but make sure that skydome covers the whole window
                NGLvec3 cameraPosition = self.cameraManager.cameraPosition;
                self.skydome.x = ABS(cameraPosition.x) < (SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / 2)?
                                    cameraPosition.x :
                                    ((SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / 2) * signf(cameraPosition.x));
                self.skydome.y = ABS(cameraPosition.y) < (SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / (WINDOW_ASPECT_RATIO * 2))?
                                    cameraPosition.y :
                                    ((SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / (WINDOW_ASPECT_RATIO * 2)) * signf(cameraPosition.y));
                self.skydome.z = 0;
                
                // notify that we found a target
                [self targetWasFound];
                
                break;
			}
		}
        // update objects in 3D simulation
        if (self.gameHasStarted && self.gameIsPlaying) {
            [self update3DWithTimeDelta:timeDelta];
        }
        // render
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        if (self.gameHasStarted) {
            // Render
            // enable z-buffer testing
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);
            // fill z-buffer with occlusion wall
            glDepthMask(GL_TRUE);
            [self.wall drawMeshWithCamera:self.cameraManager.camera];
            // render skydome without writing to the z-buffer
            glDepthMask(GL_FALSE);
            [self.skydome drawMeshWithCamera:self.cameraManager.camera];
            // render rest of the world with z-buffering read/write and alpha test
            glDepthMask(GL_TRUE);
            [self.cameraManager.camera drawCamera];
            [self.cameraManager.cameraForTranslucentObjects drawCamera];
            
            // render particles
            [self.particleManager renderParticles];
//            if (self.particleSystem.isAlive) {
//                [self.particleSystem updateWithTimeDelta:timeDelta];
//                [self.particleSystem renderParticles];
//            }
        }
        glDisable(GL_BLEND);
        
        QCAR::Renderer::getInstance().end();
        
        self.lastFrameTime = thisFrameTime;
    }
}

int signf(float f) {
    return (f < 0.) ? -1 : (f > 0.) ? +1 : 0;
}

- (void)handleTap {
    if (DEBUG_LOG) {
        NSLog(@"tap");
    }
    if (self.gameIsPlaying && self.gunIsLoaded) {
        // test hit
//        [self shotHitTest];
        // spawn beam
        [self spawnBeam];
        // consume one load and start reload timer
        self.gunIsLoaded = NO;
        static UIImage *imageUnloadedGunViewfinder = nil;
        if (imageUnloadedGunViewfinder == nil) {
            imageUnloadedGunViewfinder = [UIImage imageNamed:UNLOADED_VIEWFINDER_FILENAME];
        }
        [self.gunViewfinder setImage:imageUnloadedGunViewfinder];
        [NSTimer scheduledTimerWithTimeInterval:RELOAD_DELAY target:self selector:@selector(reload) userInfo:nil repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:RELOAD_PROGRESS_TIMER_DELAY
                                                 target: self
                                               selector: @selector(updateReloadProgressTimer:)
                                               userInfo: nil
                                                repeats: YES];
        // init progress bar
        self.reloadProgressView.progress = 0;
        self.reloadProgressView.hidden = NO;
    }
}
-(void)updateReloadProgressTimer: (NSTimer*) timer {
    self.reloadProgressView.progress += RELOAD_PROGRESS_TIMER_DELAY / RELOAD_DELAY;
    if(self.reloadProgressView.progress >= 0.99f) {
        // Invalidate timer progress bar is done
        [timer invalidate];
    }
}

- (void)reload {
    self.gunIsLoaded = YES;
    static UIImage *imageLoadedGunViewfinder = nil;
    if (imageLoadedGunViewfinder == nil) {
        imageLoadedGunViewfinder = [UIImage imageNamed:LOADED_VIEWFINDER_FILENAME];
    }
    [self.gunViewfinder setImage:imageLoadedGunViewfinder];
    
    // reset progress bar
    self.reloadProgressView.hidden = YES;
}

//- (void)shotHitTest {
//    NSLog(@"raycast test");
//    btVector3 from(0,0,0.9);
//    btVector3 to(0,0, -20);
////        btCollisionWorld::ClosestRayResultCallback closestResults(from,to);
//    btCollisionWorld::AllHitsRayResultCallback allResults(from, to);
//    // perform raycast
////        self.physCollisionWorld->rayTest(from, to, closestResults);
//    self.physCollisionWorld->rayTest(from, to, allResults);
//    
//    for (int i=0;i<allResults.m_hitFractions.size();i++) {
//        const btCollisionObject *objectHit = allResults.m_collisionObjects.at(i);
//        if (self.physPlayerObject == objectHit) {
//            NSLog(@"player hit...");
//        }
//        for (Asteroid *asteroid in [self.asteroids copy]) {
//            if (asteroid.isLoaded && asteroid.collisionObject == objectHit) {
//                NSLog(@"found asteroid");
//                [self incrementScore];
//                [self.asteroids removeObject:asteroid];
//                [asteroid destroy];
//                break;
//            }
//        }
//    }
//    
////    if (closestResults.hasHit()) {
////        NSLog(@"hit!");
////        const btCollisionObject *objectHit = closestResults.m_collisionObject;
////        if (self.physPlayerObject == objectHit) {
////            NSLog(@"player hit...");
////        }
////        for (Asteroid *asteroid in [self.asteroids copy]) {
////            if (asteroid.isLoaded && asteroid.collisionObject == objectHit) {
////                NSLog(@"found asteroid");
////                [self incrementScore];
////                [self destroyAsteroid:asteroid];
////                break;
////                
////                NGLMaterial *material = [[NGLMaterial alloc] init];
////                material.ambientColor = nglVec4Make(1, 0, 0, 1);
////                material.diffuseColor = nglVec4Make(1, 0, 0, 1);
////                asteroid.mesh.material = material;
////            }
////        }
////    }
//}

- (void)incrementScore {
    self.score++;
    self.hudOverlayView.scoreCountLabel.text = [NSString stringWithFormat:@"%3d", self.score];
}
- (void)targetWasFound {
    if (!self.gameHasStarted) {
        [self startGame];
    }
}

- (void)startGame {
    self.gameHasStarted = YES;
    self.gameIsPlaying = YES;
    self.gunIsLoaded = YES;
//    self.spawnAsteroidTimer = [NSTimer scheduledTimerWithTimeInterval:SPAWN_DELAY target:self selector:@selector(spawnAsteroid) userInfo:nil repeats:YES];
    self.overlayViewfinder.hidden = YES;
    self.hudOverlayView.hidden = NO;
    
    self.shipSpeed = 2.5;
}

- (void)stopGame {
//    [self.spawnAsteroidTimer invalidate];
    self.shipSpeed = 0.;
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
    [self.cameraManager.camera lensPerspective:(size.data[0] / size.data[1])
                                          near:NEAR far:FAR angle:fovDegrees];
    [self.cameraManager.cameraForTranslucentObjects lensPerspective:(size.data[0] / size.data[1])
                                                               near:NEAR far:FAR angle:fovDegrees];
    
    // print projection matrices
    if (DEBUG_LOG) {
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
    if (DEBUG_LOG) {
        NSLog(@"INFO: Successfully initialized ImageTracker.");
    }
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
//    QCAR::DataSet *dataSetTarmac = [self loadImageTrackerDataSet:@"Tarmac.xml"];
    QCAR::DataSet *dataSetTarmac = [self loadImageTrackerDataSet:TRACKER_DATASET_FILENAME];
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
    if (DEBUG_LOG) {
        NSLog(@"INFO: successfully stopped tracker");
    }
    return YES;
}

// Load the image tracker data set
- (QCAR::DataSet *)loadImageTrackerDataSet:(NSString*)dataFile {
    if (DEBUG_LOG) {
        NSLog(@"loadImageTrackerDataSet (%@)", dataFile);
    }
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
            if (DEBUG_LOG) {
                NSLog(@"INFO: Successfully activated data set.");
            }
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        if (![self setExtendedTrackingForDataSet:theDataSet start:self.useExtendedTracking]) {
            NSLog(@"ERROR: Failed to set extended tracking.");
            success = NO;
        } else {
            if (DEBUG_LOG) {
                NSLog(@"INFO: Successfully set extended tracking.");
            }
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

- (void)update3DWithTimeDelta:(float)timeDelta {
    // Spawn asteroids
    if (self.gameHasStarted && self.gameIsPlaying) {
        static const float SPAWN_DISTANCE = 1 / ASTEROIDS_DENSITY;
        float distanceDelta = self.shipSpeed * timeDelta; // distance travelled by the ship since last frame
        self.distanceTraveled += distanceDelta;
        self.spawnDistanceCounter += distanceDelta;
        
        while (self.spawnDistanceCounter > SPAWN_DISTANCE) {
            [self spawnAsteroid];
            self.spawnDistanceCounter -= SPAWN_DISTANCE;
        }
	}
    
    @synchronized ([[NSLock alloc] init]) {
    
        // add objects to destroy in an array and destroy them after the collision detection is done
        NSMutableArray *toDestroy = [[NSMutableArray alloc] init];
        
        // update game objects in 3D simulation (graphics and physics)
        for (GameObject3D *gameObject in [self.gameObjects copy]) {
            if (gameObject.isLoaded) {
                [gameObject updateFrameWithTimeDelta:timeDelta shipSpeed:self.shipSpeed];
                if ([self isOutOfBounds:gameObject]) {
                    if (DEBUG_LOG) {
                        NSLog(@"destroy object (out of bounds)");
                    }
                    [toDestroy addObject:gameObject];
                }
            }
        }
        
        // update particles
        [self.particleManager updateWithTimeDelta:timeDelta shipSpeed:self.shipSpeed];
        
        // update player collision object
        self.physPlayerObject->getWorldTransform().setFromOpenGLMatrix(*self.cameraManager.camera.matrix);
        
        // check objects collision with virtual wall
        for (GameObject3D *gameObject in self.gameObjects) {
            // check if object has crossed the wall
            if ([self didCollideWall:gameObject]) {
                [toDestroy addObject:gameObject];
                if (DEBUG_LOG) {
                    NSLog(@"destroy object (collision with wall)");
                }
                if ([gameObject isKindOfClass:[Asteroid class]]) {
                    // add new particle debris effect on shot asteroid
                    ParticleSystem *system = [[ParticleSystem alloc] init];
                    NGLvec3 sourcePosition = nglVec3Make(gameObject.mesh.x, gameObject.y, gameObject.z);
                    NGLvec3 sourceDirection = nglVec3Multiplyf(nglVec3Make(- gameObject.translationDirection.x,
                                                                           - gameObject.translationDirection.y,
                                                                           - gameObject.translationDirection.z),
                                                               gameObject.translationSpeed);
                    sourceDirection.z -= 2 * self.shipSpeed;  // take ship translation into account
                    [system initSystemWithSourcePosition:sourcePosition sourceDirection:sourceDirection];
                    [self.particleManager addSystem:system];
                }
            }
        }
        
        // detect collisions (using Bullet simulation)
        self.physCollisionWorld->performDiscreteCollisionDetection();
        int numManifolds = self.physCollisionWorld->getDispatcher()->getNumManifolds();
        for (int i = 0; i < numManifolds; i++) {
            btPersistentManifold* contactManifold = self.physCollisionWorld->getDispatcher()->getManifoldByIndexInternal(i);
            const btCollisionObject* obA = static_cast<const btCollisionObject*>(contactManifold->getBody0());
            const btCollisionObject* obB = static_cast<const btCollisionObject*>(contactManifold->getBody1());
            GameObject3D *gameObjectA = (__bridge GameObject3D *) obA->getUserPointer();
            GameObject3D *gameObjectB = (__bridge GameObject3D *) obB->getUserPointer();
            
            int numContacts = contactManifold->getNumContacts();
            if (numContacts > 0) {
                // check Player - Asteroid collision
                if (obA == self.physPlayerObject &&
                    [gameObjectB isKindOfClass:[Asteroid class]]) {
                    // Player was hit by asteroid
                    [self playerWasHit];
                    // destroy collided asteroid
                    Asteroid *asteroid = (Asteroid *)gameObjectB;
                    [toDestroy addObject:asteroid];
                    if (DEBUG_LOG) {
                        NSLog(@"destroy asteroid (collision with player)");
                    }
                } else if (obB == self.physPlayerObject &&
                           [gameObjectA isKindOfClass:[Asteroid class]]) {
                    // Player was hit by asteroid
                    [self playerWasHit];
                    // destroy collided asteroid
                    Asteroid *asteroid = (Asteroid *)gameObjectA;
                    [toDestroy addObject:asteroid];
                    if (DEBUG_LOG) {
                        NSLog(@"destroy asteroid (collision with player)");
                    }
                    
                    // check Beam - Asteroid collision
                } else if ([gameObjectA isKindOfClass:[Beam class]] &&
                           [gameObjectB isKindOfClass:[Asteroid class]]) {
                    [self incrementScore];
                    [toDestroy addObject:gameObjectA];
                    [toDestroy addObject:gameObjectB];
                    if (DEBUG_LOG) {
                        NSLog(@"asteroid was shot!");
                        NSLog(@"destroy asteroid & beam");
                    }
                    // add new particle debris effect on shot asteroid
                    ParticleSystem *system = [[ParticleSystem alloc] init];
                    NGLvec3 sourcePosition = nglVec3Make(gameObjectB.mesh.x, gameObjectB.mesh.y, gameObjectB.mesh.z);
    //                NGLvec3 sourceDirection = nglVec3Multiplyf(gameObjectB.translationDirection,
    //                                                           gameObjectB.translationSpeed);
                    NGLvec3 sourceDirection = nglVec3Multiplyf(gameObjectA.translationDirection,
                                                               gameObjectA.translationSpeed / 2.5f); // get beam direction and speed
                    [system initSystemWithSourcePosition:sourcePosition sourceDirection:sourceDirection];
                    [self.particleManager addSystem:system];
                } else if ([gameObjectB isKindOfClass:[Beam class]] &&
                           [gameObjectA isKindOfClass:[Asteroid class]]) {
                    [self incrementScore];
                    [toDestroy addObject:gameObjectA];
                    [toDestroy addObject:gameObjectB];
                    if (DEBUG_LOG) {
                        NSLog(@"asteroid was shot!");
                        NSLog(@"destroy asteroid & beam");
                    }
                    // add new particle debris effect on shot asteroid
                    ParticleSystem *system = [[ParticleSystem alloc] init];
                    NGLvec3 sourcePosition = nglVec3Make(gameObjectA.mesh.x, gameObjectA.mesh.y, gameObjectA.mesh.z);
                    NGLvec3 sourceDirection = nglVec3Multiplyf(gameObjectB.translationDirection,
                                                               gameObjectB.translationSpeed / 2.5f); // get beam direction and speed
                    [system initSystemWithSourcePosition:sourcePosition sourceDirection:sourceDirection];
                    [self.particleManager addSystem:system];
                }
                
            }
            contactManifold->clearManifold();
        }
        
        // Destroy all the objects marked
        for (GameObject3D *gameObject in toDestroy) {
            [self.gameObjects removeObject:gameObject];
            [gameObject destroy];
        }
            
    }
}

- (void)spawnAsteroid {
    if (self.gameHasStarted && self.gameIsPlaying) {
        if (DEBUG_LOG) {
            NSLog(@"spawn asteroid");
        }
        Asteroid *asteroid = [[Asteroid alloc] initWithCollisionWorld:self.physCollisionWorld];
        [self.gameObjects addObject:asteroid];
    }
}

- (void)spawnBeam {
    if (self.gameHasStarted && self.gameIsPlaying) {
        if (DEBUG_LOG) {
            NSLog(@"spawn beam");
        }
        Beam *beam = [[Beam alloc] initWithCollisionWorld:self.physCollisionWorld];
        [self.gameObjects addObject:beam];
    }
}

- (BOOL)isOutOfBounds:(GameObject3D *)gameObject {
    return (gameObject.x > CUTOFF_DISTANCE_MAX_X ||
            gameObject.y > CUTOFF_DISTANCE_MAX_Y ||
            gameObject.z > CUTOFF_DISTANCE_MAX_Z ||
            gameObject.x < CUTOFF_DISTANCE_MIN_X ||
            gameObject.y < CUTOFF_DISTANCE_MIN_Y ||
            gameObject.z < CUTOFF_DISTANCE_MIN_Z);
}

- (BOOL)didCollideWall:(GameObject3D *)gameObject {
    NGLbounds bounds = gameObject.aabb;
    NGLvec3 size = nglVec3Subtract(bounds.max, bounds.min);
//    BOOL wasBehindWall = gameObject.lastFrameZ + gameObject.meshBoxSizeZ / 2 < 0;
    BOOL wasBehindWall = gameObject.lastFrameZ + size.z / 2 < 0;
//    BOOL isBehindWall = gameObject.z + gameObject.meshBoxSizeZ / 2 < 0;
    BOOL isBehindWall = gameObject.z + size.z / 2 < 0;
//    BOOL wasInFrontOfWall = gameObject.lastFrameZ - gameObject.meshBoxSizeZ / 2 > 0;
    BOOL wasInFrontOfWall = gameObject.lastFrameZ - size.z / 2 > 0;
//    BOOL isInFrontOfWall = gameObject.z - gameObject.meshBoxSizeZ / 2 > 0;
    BOOL isInFrontOfWall = gameObject.z - size.z / 2 > 0;
    return ((wasBehindWall && !isBehindWall) || (wasInFrontOfWall && !isInFrontOfWall)) &&
           ![self isInWindowBounds:gameObject];
}

- (BOOL)isInWindowBounds:(GameObject3D *)gameObject {
    NGLbounds bounds = gameObject.aabb;
    NGLvec3 size = nglVec3Subtract(bounds.max, bounds.min);
    // check 2D (x,y) coordinates if they are within the virtual "window"'s bounds
//    return fabsf(gameObject.x) + gameObject.meshBoxSizeX / 2 < [self windowSizeX] &&
    return fabsf(gameObject.x) + size.x / 2 < [self windowHalfExtentX] &&
//    fabsf(gameObject.y) + gameObject.meshBoxSizeY / 2 < [self windowSizeY];
           fabsf(gameObject.y) + size.y / 2 < [self windowHalfExtentY];
}

- (float)windowHalfExtentX {
    return WINDOW_SCALE / 2;
}

- (float)windowHalfExtentY {
    return [self windowHalfExtentX] / WINDOW_ASPECT_RATIO;
}

- (BOOL)prefersStatusBarHidden {
    return  YES;
}

@end
