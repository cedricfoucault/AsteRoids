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
#import "PoseMatrixMathHelper.h"
#import <GLKit/GLKit.h>
#import "GLSLProgram.h"
#import "ParticleSystem.h"
#import "CameraManager.h"
#import "ParticleManager.h"
#import "Constants.h"
#import "UILabelBold.h"

#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>

#define ANIMATION_DURATION 2.5
#define SHOWHIDE_ANIMATION_DURATION 0.67


@interface MainViewController () <NGLViewDelegate, NGLMeshDelegate, QCARAppControl, UIGestureRecognizerDelegate>

@property (strong, nonatomic) QCARAppSession *arSession;
@property (strong, nonatomic) NGLMesh *dummy;
@property (strong, nonatomic) NGLMesh *skydome;
@property (strong, nonatomic) NGLMesh *destinationPlanet;
@property (strong, nonatomic) NGLMesh *wall;
@property (strong, nonatomic) NGLMesh *frame;
@property (strong, nonatomic) NGLMesh *asteroid;
@property (strong, nonatomic) NGLMesh *beam;
@property (strong, nonatomic) NGLMesh *beamGlowBillboard;

@property (nonatomic) btBroadphaseInterface* physBroadphase;
@property (nonatomic) btCollisionDispatcher*	physDispatcher;
@property (nonatomic) btDefaultCollisionConfiguration* physCollisionConfiguration;
@property (nonatomic) btCollisionWorld* physCollisionWorld;
@property (nonatomic) btCollisionObject* physPlayerObject;


@property (weak, nonatomic) CameraManager *cameraManager;
@property (nonatomic) NGLvec3 u0;
@property (nonatomic) BOOL gameHasStarted;
@property (nonatomic) BOOL gameIsPlaying;
@property (nonatomic) BOOL shipIsStarted;
@property (nonatomic) BOOL gunIsLoaded;
@property (nonatomic) BOOL firstShotDone;
@property (nonatomic) BOOL tutorialDone;

@property (strong, nonatomic) NSTimer *hitTimer;
@property (nonatomic) int life;
@property (nonatomic) int score;

@property (strong, nonatomic) NSMutableArray *gameObjects;
@property (strong, nonatomic) NSTimer *spawnAsteroidTimer;

@property (weak, nonatomic) ParticleManager *particleManager;
//@property (strong, nonatomic) ParticleSystem *particleSystem;

@property (nonatomic) CFAbsoluteTime timeShipStarted;
@property (nonatomic) CFAbsoluteTime timeTraveled;
@property (nonatomic) CFAbsoluteTime lastFrameTime;

@property (nonatomic) float shipSpeed;
@property (nonatomic) float spawnDistanceCounter;

@property (nonatomic) float lifeRegenCounter;

@property (nonatomic) float destinationPlanetZ;

@property (nonatomic) SystemSoundID soundShot;
@property (nonatomic) SystemSoundID soundImpact;
@property (nonatomic) SystemSoundID soundExplosion;
@property (nonatomic) SystemSoundID soundHit;
@property (nonatomic) SystemSoundID soundGameOver;
@property (nonatomic) SystemSoundID soundEndGame;

@property (nonatomic) AVAudioPlayer *playerMusic;
@property (nonatomic) AVAudioPlayer *playerMenu;

@property (nonatomic) int consecutiveMiddleTaps;

@end

@implementation MainViewController

- (id)init {
    self = [super init];

    if (self) {
        // Init AR session
        _arSession = [[QCARAppSession alloc] initWithDelegate:self];
        
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
        _tutorialDone = NO;
        _shipIsStarted = NO;
        _firstShotDone = NO;
        _life = LIFE_MAX;
        _score = 0;
        _gameObjects = [[NSMutableArray alloc] init];
        _cameraManager = [CameraManager sharedManager];
        _particleManager = [ParticleManager sharedManager];
        
        _shipSpeed = 0.0;
        _timeTraveled = 0.0f;
        
        // load sounds
        [self loadSounds];
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
    // do not update Aaabbs of inactive object
    // -- needed so that it is not done on partially initialized object (causes crash due to multithreading)
    _physCollisionWorld->setForceUpdateAllAabbs(false);
    
    // collision shapes
    _physPlayerObject = new btCollisionObject();
    // player collision shape
    btMatrix3x3 basis;
	basis.setIdentity();
	_physPlayerObject->getWorldTransform().setBasis(basis);
    btScalar playerRadius = 0.35;
    btSphereShape *playerSphere = new btSphereShape(playerRadius);
    _physPlayerObject->setCollisionShape(playerSphere);
    __weak MainViewController *weakSelf = self;
    _physPlayerObject->setUserPointer((__bridge void *)weakSelf);
    _physCollisionWorld->addCollisionObject(_physPlayerObject);
}

- (void) loadSounds {
    // Get the main bundle for the app
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    // Create sound IDs for every sound effects
    NSString *path  = [mainBundle pathForResource:SOUND_SHOT_NAME ofType:SOUND_SHOT_EXTENSION];
    CFURLRef fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundShot);
    
    path  = [mainBundle pathForResource:SOUND_IMPACT_NAME ofType:SOUND_IMPACT_EXTENSION];
    fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundImpact);
    
    path  = [mainBundle pathForResource:SOUND_EXPLOSION_NAME ofType:SOUND_EXPLOSION_EXTENSION];
    fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundExplosion);
    
    path  = [mainBundle pathForResource:SOUND_BOOM_NAME ofType:SOUND_BOOM_EXTENSION];
    fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundHit);
    
    path  = [mainBundle pathForResource:SOUND_GAMEOVER_NAME ofType:SOUND_GAMEOVER_EXTENSION];
    fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundGameOver);
    
    path  = [mainBundle pathForResource:SOUND_ENDGAME_NAME ofType:SOUND_ENDGAME_EXTENSION];
    fileURLRef = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(fileURLRef, &_soundEndGame);
    
    // Create AVAudioPlayer for background musics
    path = [[NSBundle mainBundle] pathForResource:SOUND_MUSIC_NAME ofType:SOUND_MUSIC_EXTENSION];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];
    self.playerMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    [self.playerMusic prepareToPlay];
    [self.playerMusic setVolume:SOUND_MUSIC_VOLUME];
    
    path = [[NSBundle mainBundle] pathForResource:SOUND_MENU_NAME ofType:SOUND_MENU_EXTENSION];
    fileURL = [[NSURL alloc] initFileURLWithPath:path];
    self.playerMenu = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    [self.playerMenu prepareToPlay];
    [self.playerMenu setVolume:SOUND_MENU_VOLUME];
    self.playerMenu.numberOfLoops = -1;
}

- (void)dealloc {
    // destroy the Bullet Physics objects that were allocated
    delete _physDispatcher;
    delete _physBroadphase;
    // dispose of sounds
    AudioServicesDisposeSystemSoundID(_soundShot);
    AudioServicesDisposeSystemSoundID(_soundImpact);
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
    CGSize arViewBoundsSize = arViewFrame.size.width > arViewFrame.size.height?
        CGSizeMake(arViewFrame.size.height, arViewFrame.size.width) :
        arViewFrame.size; // arViewBoundsSize should always be in portraint orientation
    // initialize the AR session
    [self.arSession initAR:QCAR::GL_20 ARViewBoundsSize:arViewBoundsSize orientation:UIInterfaceOrientationLandscapeRight];
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
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];
    // Init overlays
    [[NSBundle mainBundle] loadNibNamed:@"hudInstructions" owner:self options:nil];
    [self.view addSubview:self.hudInstructions];
    // HUD
    [[NSBundle mainBundle] loadNibNamed:@"hudGame" owner:self options:nil];
    [self.view addSubview:self.hudOverlayView];
    self.hudOverlayView.hidden = YES;
    // Set layout constraints
    [self.hudInstructions setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.hudOverlayView setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [self.hitOverlayView setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIView *subview = self.hudInstructions;
    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    subview = self.hudOverlayView;
    views = NSDictionaryOfVariableBindings(subview);
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
//    subview = self.hitOverlayView;
//    views = NSDictionaryOfVariableBindings(subview);
//    [self.view addConstraints:
//     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|"
//                                             options:0
//                                             metrics:nil
//                                               views:views]];
//    
//    [self.view addConstraints:
//     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|"
//                                             options:0
//                                             metrics:nil
//                                               views:views]];
    // Update text
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.labelMoveDevice.text = [self.labelMoveDevice.text stringByReplacingOccurrencesOfString:@"iPhone"
                                                                                         withString:@"iPad"];
    }
    
    // Set OpenGL parameters
    nglGlobalColorFormat(NGLColorFormatRGBA);
    nglGlobalFlush();
    
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
    
    // Set texture quality
    nglGlobalTextureQuality(NGLTextureQualityTrilinear);
    nglGlobalTextureOptimize(NGLTextureOptimizeNone);
    nglGlobalFlush();
    
    // Set the fog
    NGLFog *defaultFog = [NGLFog defaultFog];
    defaultFog.color = nglVec4Make(0, 0, 0, 1);
    //	defaultFog.type = NGLFogTypeLinear;
    defaultFog.type = NGLFogTypeNone;
    defaultFog.start = FOG_START;
    defaultFog.end = FOG_END;
    
    
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
    self.skydome.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BILLBOARD_FRAGMENT_SHADER_FILENAME];
    [self.skydome compileCoreMesh];
    self.skydome.x = 0;
    self.skydome.y = 0;
    self.skydome.z = 0;
    
    // Setting the destination planet
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", 1.0], kNGLMeshKeyNormalize,
                nil];
    self.destinationPlanet = [[NGLMesh alloc] initWithFile:DESTINATION_PLANET_MESH_FILENAME settings:settings delegate:self];
    self.destinationPlanet.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BILLBOARD_FRAGMENT_SHADER_FILENAME];
    [self.destinationPlanet compileCoreMesh];
    self.destinationPlanet.x = 0;
    self.destinationPlanet.y = 0;
    self.destinationPlanet.z = -0.01;
    [self resetPlanet];
    
    
    // Setting the invisible "occlusion" wall
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", WALL_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.wall = [[NGLMesh alloc] initWithFile:@"Wall with hole.obj" settings:settings delegate:self];
    NGLMaterial *transparentMaterial = [[NGLMaterial alloc] init];
    transparentMaterial.alpha = 0.05;
    self.wall.material = transparentMaterial;
    [self.wall compileCoreMesh];
    
    // Setting the porthole frame
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                nil];
    self.frame = [[NGLMesh alloc] initWithFile:FRAME_MESH_FILENAME settings:settings delegate:nil];
    
    // Setting the asteroid mesh
//    settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
//                [NSString stringWithFormat:@"%f", ASTEROID_SCALE], kNGLMeshKeyNormalize,
//                nil];
//    self.asteroid = [[NGLMesh alloc] initWithFile:ASTEROID_MESH_FILENAME settings:settings delegate:nil];
    
    // Setting the beam
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", BEAM_CORE_SCALE], kNGLMeshKeyNormalize,
                nil];
    self.beam = [[NGLMesh alloc] initWithFile:BEAM_CORE_MESH_FILENAME settings:settings delegate:nil];
    self.beam.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BEAM_CORE_FRAGMENT_SHADER_FILENAME];
    [self.beam compileCoreMesh];
    self.beam.visible = NO;
    
    // beam glow
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
                [NSString stringWithFormat:@"%f", 0.2], kNGLMeshKeyNormalize,
                nil];
    self.beamGlowBillboard = [[NGLMesh alloc] initWithFile:BEAM_GLOW_BILLBOARD_MESH_FILENAME settings:settings delegate:self];
    self.beamGlowBillboard.shaders = [NGLShaders shadersWithFilesVertex:nil andFragment:BILLBOARD_FRAGMENT_SHADER_FILENAME];
    [self.beamGlowBillboard compileCoreMesh];
    self.beamGlowBillboard.visible = NO;
    
	// Set the camera
    self.cameraManager.camera = [[NGLCamera alloc] initWithMeshes:self.dummy, self.frame, nil];
    self.cameraManager.cameraForTranslucentObjects = [[NGLCamera alloc] initWithMeshes:nil];
//	[self.camera autoAdjustAspectRatio:YES animated:YES];
    
    // Setting initial asteroids
//    Asteroid *asteroid;
//    for (float z = -4.0f; z > ASTEROIDS_SPAWN_Z; z -= 1 / ASTEROIDS_DENSITY) {
//        asteroid = [[Asteroid alloc] initWithCollisionWorld:self.physCollisionWorld];
//        asteroid.mesh.x = RANDOM_MINUS_1_TO_1() * ASTEROIDS_SPAWN_X_VARIANCE;
//        asteroid.mesh.y = RANDOM_MINUS_1_TO_1() * ASTEROIDS_SPAWN_Y_VARIANCE;
//        asteroid.mesh.z = z;
//        asteroid.translationSpeed = ASTEROID_SPEED_MEAN + RANDOM_MINUS_1_TO_1() * ASTEROID_SPEED_VARIANCE;
//        asteroid.rotationSpeed = ASTEROID_ROTATION_SPEED_MEAN + RANDOM_MINUS_1_TO_1() * ASTEROID_ROTATION_SPEED_VARIANCE;
//        asteroid.motionPropertiesInitialized = TRUE;
//        [self.gameObjects addObject:asteroid];
//    }
//    [self addInitialAsteroids];
//    [self hideGameObjects];
    [self addTutorialAsteroid];
    
	// Starts the debug monitor.
//	[[NGLDebug debugMonitor] startWithView:(NGLView *)self.view];
}

- (void)addInitialAsteroids {
    Asteroid *asteroid;
    for (float z = -4.0f; z > ASTEROIDS_SPAWN_Z; z -= 1 / ASTEROIDS_DENSITY) {
        asteroid = [[Asteroid alloc] initWithCollisionWorld:self.physCollisionWorld];
        asteroid.mesh.z = z;
        float r = ((float)arc4random_uniform(RAND_MAX) / (float)RAND_MAX);
        if (r < PROBA_GO_THROUGH_WINDOW) { // occasionally spawn asteroid so that it passes through the window
            float sizeMax = sqrtf(3 * ASTEROID_SCALE * ASTEROID_SCALE);
            float r;
            r = RANDOM_MINUS_1_TO_1();
            float xAtZ0 = r / 2 * (WINDOW_SCALE - sizeMax);
            r = RANDOM_MINUS_1_TO_1();
            float yAtZ0 = r / 2 * (WINDOW_SCALE / WINDOW_ASPECT_RATIO - sizeMax);
            asteroid.mesh.x = xAtZ0;
            asteroid.mesh.y = yAtZ0;
            asteroid.translationSpeed = 0;
            // rotation
            asteroid.rotationAxis = nglVec3Normalize(nglVec3Make(RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1()));
            asteroid.rotationSpeed = ASTEROID_ROTATION_SPEED_MEAN + RANDOM_MINUS_1_TO_1() * ASTEROID_ROTATION_SPEED_VARIANCE;
        } else {
            // position
            asteroid.mesh.x = RANDOM_MINUS_1_TO_1() * ASTEROIDS_SPAWN_X_VARIANCE;
            asteroid.mesh.y = RANDOM_MINUS_1_TO_1() * ASTEROIDS_SPAWN_Y_VARIANCE;
            // translation
            asteroid.translationDirection = nglVec3Normalize(nglVec3Make(RANDOM_MINUS_1_TO_1(),
                                                                     RANDOM_MINUS_1_TO_1(),
                                                                     RANDOM_MINUS_1_TO_1()));
            asteroid.translationSpeed = ASTEROID_SPEED_MEAN + RANDOM_MINUS_1_TO_1() * ASTEROID_SPEED_VARIANCE;
            // rotation
            asteroid.rotationAxis = nglVec3Normalize(nglVec3Make(RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1()));
            asteroid.rotationSpeed = ASTEROID_ROTATION_SPEED_MEAN + RANDOM_MINUS_1_TO_1() * ASTEROID_ROTATION_SPEED_VARIANCE;
        }
        asteroid.motionPropertiesInitialized = TRUE;
        [self.gameObjects addObject:asteroid];
    }
}

- (void)addTutorialAsteroid {
    Asteroid *asteroid;
    asteroid = [[Asteroid alloc] initWithCollisionWorld:self.physCollisionWorld];
    // position
    asteroid.mesh.x =  3.0f * WINDOW_SCALE / 4.0f;
    asteroid.mesh.y = - 3.0f * WINDOW_SCALE / (4.0f * WINDOW_ASPECT_RATIO);
    asteroid.mesh.z = -2.5f;
    // rotation
    asteroid.rotationAxis = nglVec3Normalize(nglVec3Make(RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1(), RANDOM_MINUS_1_TO_1()));
    asteroid.rotationSpeed = ASTEROID_ROTATION_SPEED_MEAN;
    asteroid.motionPropertiesInitialized = TRUE;
    [self.gameObjects addObject:asteroid];
}

- (void)hideGameObjects {
    for (GameObject3D *gameObject in self.gameObjects) {
        gameObject.mesh.visible = NO;
    }
}

- (void)showGameObjects {
    for (GameObject3D *gameObject in self.gameObjects) {
        gameObject.mesh.visible = YES;
    }
}

static const float sqrt_2 = sqrtf(2);

// draw a frame
- (void) drawView {
    if (self.arSession.cameraIsStarted) {
        CFAbsoluteTime thisFrameTime = CFAbsoluteTimeGetCurrent();
        CFTimeInterval timeDelta = self.lastFrameTime? (thisFrameTime - self.lastFrameTime) : 0.0;
        if (self.shipIsStarted && self.timeTraveled > TIME_SHIP_TRAVEL) {
            // stop ship when time of travel is elapsed
            [self stopShip];
        }
        
        QCAR::State state = QCAR::Renderer::getInstance().begin();
        glDepthRangef(0.0f, 1.0f);
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClearDepthf(1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // draw video background
        QCAR::Renderer::getInstance().drawVideoBackground();
        
        // automatically pause / resume if tracking is lost / recovered
        if (state.getNumTrackableResults() == 0 && self.gameIsPlaying) {
            [self pause];
        } else if (state.getNumTrackableResults() > 0 && !self.gameIsPlaying) {
            [self resume];
        }
        
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
                [self.destinationPlanet rebaseWithMatrix:qMatrix.data scale:scale compatibility:NGLRebaseQualcommAR];
                // move skydome with camera to give illusion of infinity, but make sure that skydome covers the whole window
                NGLvec3 cameraPosition = self.cameraManager.cameraPosition;
                self.skydome.x = ABS(cameraPosition.x) < (SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / 2)?
                                    cameraPosition.x :
                                    ((SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / 2) * signf(cameraPosition.x));
                self.skydome.y = ABS(cameraPosition.y) < (SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / (WINDOW_ASPECT_RATIO * 2))?
                                    cameraPosition.y :
                                    ((SKYDOME_DISTANCE * sqrt_2 / 4 - WINDOW_SCALE / (WINDOW_ASPECT_RATIO * 2)) * signf(cameraPosition.y));
                self.skydome.z = 0;
                self.destinationPlanet.x = cameraPosition.x;
                self.destinationPlanet.y = cameraPosition.y;
                [self.destinationPlanet lookAtPointX:cameraPosition.x toY:cameraPosition.y toZ:cameraPosition.z];
                
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
        if (self.gameHasStarted && self.gameIsPlaying) {
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
            [self.destinationPlanet drawMeshWithCamera:self.cameraManager.camera];
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

- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (DEBUG_LOG) {
        NSLog(@"tap");
    }
    static UIImage *imageUnloadedGunViewfinder = nil;
    if (imageUnloadedGunViewfinder == nil) {
        imageUnloadedGunViewfinder = [UIImage imageNamed:UNLOADED_VIEWFINDER_FILENAME];
    }
    if (self.shipIsStarted && self.gameIsPlaying && self.gunIsLoaded) { // user is in game
        // play sound effect
        AudioServicesPlaySystemSound(self.soundShot);
        // spawn beam
        [self spawnBeam];
        // consume one load and start reload timer
        self.gunIsLoaded = NO;
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
        
        // get touch location and show feedback if user keeps tapping in the middle
        CGPoint touchLocation = [sender locationInView:self.view];
        if ([self isInMiddle:touchLocation]) {
            self.consecutiveMiddleTaps++;
        } else {
            self.consecutiveMiddleTaps = 0;
        }
        if (self.consecutiveMiddleTaps >= 3) {
            // show middle tap feedback
            self.tapMiddleIngame.hidden = false;
            self.tapMiddleIngame.alpha = 0;
            [UIView animateWithDuration:SHOWHIDE_ANIMATION_DURATION
                             animations:^(){
                self.tapMiddleIngame.alpha = 1;
            }
                             completion:^(BOOL finished1){
                [UIView animateWithDuration:SHOWHIDE_ANIMATION_DURATION delay:2.0 options:0
                                 animations:^() {
                                     self.tapMiddleIngame.alpha = 0;
                                 }
                                 completion:^(BOOL finished2) {
//                                     self.tapMiddleIngame.hidden = true;
                                 }];
            }];
            // reset consecutiveMiddleTaps counter
            self.consecutiveMiddleTaps = 0;
        }
    } else if (self.gameIsPlaying && self.gunIsLoaded) { // user is in instructions
        // this is the first player shot
        // play sound effect
        AudioServicesPlaySystemSound(self.soundShot);
        // spawn beam
        [self spawnBeam];
        // consume one load and start reload timer
        self.gunIsLoaded = NO;
        [self.gunViewfinderInstruction setImage:imageUnloadedGunViewfinder];
        [NSTimer scheduledTimerWithTimeInterval:RELOAD_DELAY target:self selector:@selector(reloadInstruction) userInfo:nil repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:RELOAD_PROGRESS_TIMER_DELAY
                                         target: self
                                       selector: @selector(updateReloadProgressTimerInstruction:)
                                       userInfo: nil
                                        repeats: YES];
        // init progress bar
        self.reloadProgressViewInstruction.progress = 0;
        self.reloadProgressViewInstruction.hidden = NO;
        
        // get touch location and show feedback if user keeps tapping in the middle
        CGPoint touchLocation = [sender locationInView:self.view];
        if ([self isInMiddle:touchLocation]) {
            self.consecutiveMiddleTaps++;
        } else {
            self.consecutiveMiddleTaps = 0;
        }
        if (self.consecutiveMiddleTaps >= 3) {
            // show middle tap feedback
            self.tapMiddleInstruction.hidden = false;
            self.tapMiddleInstruction.alpha = 0;
            [UIView animateWithDuration:SHOWHIDE_ANIMATION_DURATION
                             animations:^(){
                                 self.tapMiddleInstruction.alpha = 1;
                             }
                             completion:^(BOOL finished1){
                                 [UIView animateWithDuration:SHOWHIDE_ANIMATION_DURATION delay:2.0 options:0
                                                  animations:^() {
                                                      self.tapMiddleInstruction.alpha = 0;
                                                  }
                                                  completion:^(BOOL finished2) {
//                                                      self.tapMiddleInstruction.hidden = true;
                                                  }];
                             }];
            // reset consecutiveMiddleTaps counter
            self.consecutiveMiddleTaps = 0;
        }
    }
}

- (BOOL)isInMiddle:(CGPoint)touchLocation {
    CGPoint middle = CGPointMake(self.view.frame.size.height / 2, self.view.frame.size.width / 2);
    // see if touch point is within 5% middle rectangle
    return fabsf(middle.x - touchLocation.x) / self.view.frame.size.height < 0.088 &&
            fabsf(middle.y - touchLocation.y) / self.view.frame.size.width < 0.088;
}

-(void)updateReloadProgressTimer:(NSTimer*)timer {
    self.reloadProgressView.progress += RELOAD_PROGRESS_TIMER_DELAY / RELOAD_DELAY;
    if (self.reloadProgressView.progress >= 0.99f) {
        // Invalidate timer progress bar is done
        [timer invalidate];
    }
}

-(void)updateReloadProgressTimerInstruction:(NSTimer*)timer {
    self.reloadProgressViewInstruction.progress += RELOAD_PROGRESS_TIMER_DELAY / RELOAD_DELAY;
    if (self.reloadProgressViewInstruction.progress >= 0.99f) {
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

- (void)reloadInstruction {
    self.gunIsLoaded = YES;
    static UIImage *imageLoadedGunViewfinder = nil;
    if (imageLoadedGunViewfinder == nil) {
        imageLoadedGunViewfinder = [UIImage imageNamed:LOADED_VIEWFINDER_FILENAME];
    }
    [self.gunViewfinderInstruction setImage:imageLoadedGunViewfinder];
    
    // reset progress bar
    self.reloadProgressViewInstruction.hidden = YES;
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
    // only count asteroids destroyed once ship is started
    if (self.shipIsStarted) {
        self.score++;
        self.asteroidsLabel.text = [NSString stringWithFormat:@"%d", self.score];
    } else if (!self.firstShotDone) {
        self.firstShotDone = YES;
        [self displayInstruction3];
    }
}
- (void)targetWasFound {
    if (!self.gameHasStarted) {
        [self startGame];
        [self displayInstruction2];
    }
}

- (void)displayInstruction2 {
    self.gunIsLoaded = YES;
//    self.instruction1CenterXConstraint.constant = 640;
//    self.instruction2CenterXConstraint.constant = 0;
    [self.hudInstructions removeConstraints:@[
                                              self.instruction1CenterXConstraint,
                                              self.instruction2CenterXConstraint
                                              ]];
    [self.targetViewfinder removeFromSuperview];
    self.gunViewfinderInstruction.hidden = NO;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//        [self.instruction1 layoutIfNeeded];
//        [self.instruction2 layoutIfNeeded];
        [self.hudInstructions layoutIfNeeded];
    }];
}

- (void)displayInstruction3 {
    // update overlay to take the whole view
//    self.instruction2CenterXConstraint.constant = 640;
//    self.startButtonCenterYConstraint.constant = 0;
//    self.startButtonCenterXConstraint.constant = 0;
    [self.hudInstructions removeConstraints:@[
                                              self.overlayProportionalHeightConstraint,
                                              self.instruction2CenterXConstraint2,
                                              self.instruction3CenterXConstraint,
                                              self.instruction3CenterYConstraint,
                                              self.startButtonCenterXConstraint,
                                              self.startButtonCenterYConstraint
                                              ]];
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//        [self.overlay layoutIfNeeded];
//        [self.instruction2 layoutIfNeeded];
//        [self.startButton layoutIfNeeded];
        [self.hudInstructions layoutIfNeeded];
    }];
    // music
    self.playerMenu.currentTime = 0.0;
    [self.playerMenu playAtTime:(self.playerMenu.deviceCurrentTime + ANIMATION_DURATION)];
}

- (void)displayGameOver {
    self.gameoverOverlay.hidden = FALSE;
    [self.hudOverlayView removeConstraints:@[
                                             self.gameoverTopAlignConstraint,
                                             self.gameoverBottomAlignConstraint
                                             ]];
    [self.hudOverlayView removeConstraints:@[
                                             self.asteroidsLabelLeftAlignConstraint,
                                             self.asteroidsLabelRightAlignConstraint,
                                             self.asteroidsIconLeftAlignConstraint,
                                             self.asteroidsIconBottomAlignConstraint
                                             ]];
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.hudOverlayView layoutIfNeeded];
        self.ingameOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        self.ingameOverlay.hidden = TRUE;
    }];
}

- (void)displayEndGame {
    // update overlay to take the whole view
    self.endgameOverlay.hidden = FALSE;
    [self.hudOverlayView removeConstraints:@[
                                             self.endgameTopAlignConstraint,
                                             self.endgameBottomAlignConstraint
                                             ]];
    [self.hudOverlayView removeConstraints:@[
         self.asteroidsLabelLeftAlignConstraint,
         self.asteroidsLabelRightAlignConstraint,
         self.asteroidsIconLeftAlignConstraint,
         self.asteroidsIconBottomAlignConstraint
    ]];
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.hudOverlayView layoutIfNeeded];
        self.ingameOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        self.ingameOverlay.hidden = TRUE;
    }];
}

- (void)displayIngame {
    [self.hudOverlayView addConstraints:@[
         self.asteroidsLabelLeftAlignConstraint,
         self.asteroidsLabelRightAlignConstraint,
         self.asteroidsIconLeftAlignConstraint,
         self.asteroidsIconBottomAlignConstraint
    ]];
    [self.hudOverlayView layoutIfNeeded];
    self.ingameOverlay.hidden = FALSE;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.gameoverOverlay.alpha = 0;
        self.endgameOverlay.alpha = 0;
        self.ingameOverlay.alpha = 1;
    } completion:^(BOOL finished) {
        self.gameoverOverlay.hidden = TRUE;
        self.endgameOverlay.hidden = TRUE;
        self.endgameOverlay.alpha = 1;
        self.gameoverOverlay.alpha = 1;
        [self.hudOverlayView addConstraints:@[
                                              self.gameoverTopAlignConstraint,
                                              self.gameoverBottomAlignConstraint,
                                              self.endgameTopAlignConstraint,
                                              self.endgameBottomAlignConstraint
                                            ]];
    }];
}


- (IBAction)markerButtonTapped {
    NSURL *markerImageURL = [NSURL URLWithString:MARKER_IMAGE_URL_STRING];
    [[UIApplication sharedApplication] openURL:markerImageURL];
}

- (IBAction)startButtonTapped {
//    [self startGame];
    [self startShip];
}

- (IBAction)playAgainButtonTapped {
    [self restartShip];
}

- (void)startGame {
    self.gameHasStarted = YES;
    self.gameIsPlaying = YES;
    self.gunIsLoaded = YES;
//    self.spawnAsteroidTimer = [NSTimer scheduledTimerWithTimeInterval:SPAWN_DELAY target:self selector:@selector(spawnAsteroid) userInfo:nil repeats:YES];
    
//    self.hudInstructions.hidden = YES;
//    self.hudOverlayView.hidden = NO;
    
//    [UIView transitionFromView:self.hudInstructions
//                        toView:self.hudOverlayView
//                      duration:ANIMATION_DURATION options:UIViewAnimationOptionShowHideTransitionViews
//                    completion:^(BOOL finished){
//                        self.gameHasStarted = YES;
//                        self.gameIsPlaying = YES;
//                        self.gunIsLoaded = YES;
//                    }];
}

- (void)startShip {
    // tutorial is done
    self.tutorialDone = YES;
    // reset counts
    [self resetScore];
    // set scene
    [self addInitialAsteroids];
    // transition views
    [UIView transitionFromView:self.hudInstructions
                        toView:self.hudOverlayView
                      duration:SHOWHIDE_ANIMATION_DURATION options:UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished){
                        self.shipIsStarted = YES;
                        self.shipSpeed = 0.1f;
                        self.timeShipStarted = CFAbsoluteTimeGetCurrent();
//                        [self stopShip];
                    }];
    // music
    if (self.playerMenu.playing) {
        [self.playerMenu stop];
        [self.playerMenu prepareToPlay];
    }
    self.playerMusic.currentTime = 0.0;
    [self.playerMusic play];
}

- (void)restartShip {
    // reset counts
    [self resetScore];
    [self resetLife];
    self.shipIsStarted = YES;
    self.shipSpeed = 0.1f;
    self.timeShipStarted = CFAbsoluteTimeGetCurrent();
    self.timeTraveled = 0.0f;
    // reset scene
    for (GameObject3D *gameObject in [self.gameObjects copy]) {
        [self.gameObjects removeObject:gameObject];
        [gameObject destroy];
    }
    [self addInitialAsteroids];
    [self resetPlanet];
    // display in-game view
    [self displayIngame];
    // music
    if (self.playerMenu.playing) {
        [self.playerMenu stop];
        [self.playerMenu prepareToPlay];
    }
    self.playerMusic.currentTime = 0.0;
    [self.playerMusic play];
}

- (void)resetPlanet {
    self.destinationPlanetZ = destinationPlanetStartZ();
    [self refreshPlanetMeshScale];
}

//- (void)updatePlanetWithZDelta:(float)zDelta {
//    self.destinationPlanetZ += zDelta;
//    [self refreshPlanetMeshScale];
//}
- (void)updatePlanetWithTimeElapsed:(float)timeElapsed {
    self.destinationPlanetZ = destinationPlanetStartZ() - shipDistanceTraveled(timeElapsed);
    [self refreshPlanetMeshScale];
}

- (void)refreshPlanetMeshScale {
    float scale = DESTINATION_PLANET_RADIUS * eyePlanetFocal() / self.destinationPlanetZ;
    self.destinationPlanet.scaleX = scale;
    self.destinationPlanet.scaleY = scale;
}

- (void)resetScore {
    self.score = 0;
    self.asteroidsLabel.text = [NSString stringWithFormat:@"%d", self.score];
}

- (void)resetLife {
    self.life = LIFE_MAX;
    [self refreshLifebar];
}

- (void)stopShip {
//    [self.spawnAsteroidTimer invalidate];
    self.shipSpeed = 0.;
    self.shipIsStarted = NO;
    [self displayEndGame];
    // music
    if (self.playerMusic.playing) {
        [self.playerMusic stop];
        [self.playerMusic prepareToPlay];
    }
    // play sound effect
    AudioServicesPlaySystemSound(self.soundEndGame);
    // get duration of sound effect
    NSString *path = [[NSBundle mainBundle] pathForResource:SOUND_ENDGAME_NAME ofType:SOUND_ENDGAME_EXTENSION];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];
    AVURLAsset *fxAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    CMTime fxDuration = fxAsset.duration;
    float fxDurationSeconds = CMTimeGetSeconds(fxDuration);
    float soundDelay = fxDurationSeconds > ANIMATION_DURATION ? fxDurationSeconds : ANIMATION_DURATION;
    // play menu music once sound effect is done
    self.playerMenu.currentTime = 0.0;
    [self.playerMenu playAtTime:(self.playerMenu.deviceCurrentTime + ANIMATION_DURATION)];
}

- (void)regenLife {
    // increment player life count
    if (self.life < LIFE_MAX) {
        self.life++;
        [self refreshLifebar];
    }
}

- (void)playerWasHit {
    // decrement player life count
    self.life--;
    [self refreshLifebar];
    // show hit overlay for a certain duration
    if (self.hitTimer) {
        [self.hitTimer invalidate];
    }
    self.hitOverlayView.hidden = NO;
    self.hitOverlayView.alpha = 0.8;
    [self.view setNeedsDisplay];
    NSTimeInterval secondsShown = 1.0;
//    self.hitTimer = [NSTimer scheduledTimerWithTimeInterval:secondsShown target:self selector:@selector(hideHitOverlay) userInfo:nil repeats:NO];
    if (self.life == 0) {
        // display game over if life is 0
        [UIView animateWithDuration:secondsShown animations:^{
            self.hitOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            //        self.hitOverlayView.hidden = TRUE;
            [self gameOver];
        }];
    } else {
        // otherwise just give feedback that player was hit
        [UIView animateWithDuration:secondsShown animations:^{
            self.hitOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            //        self.hitOverlayView.hidden = TRUE;
        }];
    }
    // play sound effect
    AudioServicesPlaySystemSound(self.soundHit);
}

- (void)refreshLifebar {
    self.lifebarWidthConstraint.constant = self.maxLifebarWidthConstraint.constant * self.life / (CGFloat)LIFE_MAX;
    [self.lifebarView layoutIfNeeded];
}

- (void)gameOver {
    //    [self.spawnAsteroidTimer invalidate];
    self.shipSpeed = 0.;
    self.shipIsStarted = NO;
    [self displayGameOver];
    // music
    if (self.playerMusic.playing) {
        [self.playerMusic stop];
        [self.playerMusic prepareToPlay];
    }
    // play sound effect
    AudioServicesPlaySystemSound(self.soundGameOver);
    // get duration of sound effect
    NSString *path = [[NSBundle mainBundle] pathForResource:SOUND_GAMEOVER_NAME ofType:SOUND_GAMEOVER_EXTENSION];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];
    AVURLAsset *fxAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    CMTime fxDuration = fxAsset.duration;
    float fxDurationSeconds = CMTimeGetSeconds(fxDuration);
    // play menu music once sound effect is done
    self.playerMenu.currentTime = 0.0;
    [self.playerMenu playAtTime:(self.playerMenu.deviceCurrentTime + fxDurationSeconds)];
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
            exit(-1);
        }
        
        // by default, we try to set the continuous auto focus mode
        // and we update menu to reflect the state of continuous auto-focus
        bool isContinuousAutofocus = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        if (!isContinuousAutofocus) {
            NSLog(@"ERROR: Could not set continuous autofocus");
        }
    } else {
        NSLog(@"ERROR: Error initializing AR:%@", [initError description]);
        exit(-1);
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
- (BOOL) activateDataSetTracking:(QCAR::DataSet *)theDataSet {
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
        if (![self setExtendedTrackingForDataSet:theDataSet start:USE_EXTENDED_TRACKING]) {
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
    if (DEBUG_LOG) {
        NSLog(@"PAUSE");
    }
    self.gameIsPlaying = NO;
    self.pausedOverlay.hidden = NO;
    if (self.playerMusic.playing) {
        [self.playerMusic pause];
    }
    if (self.playerMenu.playing) {
        [self.playerMenu pause];
    }
}

- (void)resume {
    if (DEBUG_LOG) {
        NSLog(@"RESUME");
    }
    self.gameIsPlaying = YES;
    self.pausedOverlay.hidden = YES;
    if (self.shipIsStarted && !self.playerMusic.playing) {
        [self.playerMusic play];
    } else if (self.firstShotDone && !self.playerMenu.playing) {
        [self.playerMenu play];
    }
}

- (void)update3DWithTimeDelta:(float)timeDelta {
    if (self.gameHasStarted && self.gameIsPlaying && self.shipIsStarted) {
        self.timeTraveled += timeDelta;
        float zDelta = - self.shipSpeed * timeDelta;
        float distanceDelta = - zDelta;
        // Update planet
        [self updatePlanetWithTimeElapsed:self.timeTraveled];
        // Spawn asteroids
        BOOL spawnTimeElapsed = self.timeTraveled > TIME_SPAWN_ASTEROIDS;
        if (!spawnTimeElapsed) {
            static const float SPAWN_DISTANCE = 1 / ASTEROIDS_DENSITY;
            self.spawnDistanceCounter += distanceDelta;
            while (self.spawnDistanceCounter > SPAWN_DISTANCE) {
                [self spawnAsteroid];
                self.spawnDistanceCounter -= SPAWN_DISTANCE;
            }
        }
        // Regen life
        static const float LIFE_REGEN_TIME = 1 / LIFE_REGEN_RATE;
        self.lifeRegenCounter += timeDelta;
        while (self.lifeRegenCounter > LIFE_REGEN_TIME) {
            [self regenLife];
            self.lifeRegenCounter -= LIFE_REGEN_TIME;
        }
        // Update ship speed
        if (self.shipSpeed < SHIP_SPEED_MAX) {
            self.shipSpeed = shipSpeed(self.timeTraveled);
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.shipSpeed];
        }
    }
    
    @synchronized ([[NSLock alloc] init]) {
    
        // add objects to destroy in an array and destroy them after the collision detection is done
        NSMutableSet *toDestroy = [[NSMutableSet alloc] init];
        
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
        for (GameObject3D *gameObject in [self.gameObjects copy]) {
            // check if object has crossed the wall
            if ([self didCollideWall:gameObject]) {
                // destroy mesh
                [toDestroy addObject:gameObject];
                if ([gameObject isKindOfClass:[Asteroid class]]) {
                    // ship was hit by asteroid == player hit
                    [self playerWasHit];
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
                    // play sound effect
                    AudioServicesPlaySystemSound(self.soundExplosion);
                } else if ([gameObject isKindOfClass:[Beam class]]) {
                    // play sound effect
                    AudioServicesPlaySystemSound(self.soundImpact);
                }
                if (DEBUG_LOG) {
                    NSLog(@"destroy object (collision with wall)");
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
                if (DEBUG_LOG) {
                    if (!obA) {
                        NSLog(@"obA is null");
                    } else if (obA == self.physPlayerObject) {
                        NSLog(@"obA is player");
                    }
                    if (!gameObjectA) {
                        NSLog(@"gameObjectA is null");
                    }
                }
                
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
                    // play sound effect
                    AudioServicesPlaySystemSound(self.soundExplosion);
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
                    // play sound effects
                    AudioServicesPlaySystemSound(self.soundImpact);
                    AudioServicesPlaySystemSound(self.soundExplosion);
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
                    // play sound effect
                    AudioServicesPlaySystemSound(self.soundImpact);
                    AudioServicesPlaySystemSound(self.soundExplosion);
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
        if (beam == nil) {
            NSLog(@"beam is nil");
        }
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
    BOOL isInWindowBounds = [self isInWindowBounds:gameObject];
    BOOL result = (wasBehindWall && !isBehindWall && !isInWindowBounds) ||
                    (wasInFrontOfWall && !isInFrontOfWall && !isInWindowBounds);
    return result;
//    return ((wasBehindWall && !isBehindWall) || (wasInFrontOfWall && !isInFrontOfWall)) &&
//           ![self isInWindowBounds:gameObject];
}

- (BOOL)isInWindowBounds:(GameObject3D *)gameObject {
    NGLbounds bounds = gameObject.aabb;
    NGLvec3 size = nglVec3Subtract(bounds.max, bounds.min);
    // check 2D (x,y) coordinates if they are within the virtual "window"'s bounds
//    return fabsf(gameObject.x) + gameObject.meshBoxSizeX / 2 < [self windowSizeX] &&
    return fabsf(gameObject.x) + size.x / 2 <= [self windowHalfExtentX] &&
//    fabsf(gameObject.y) + gameObject.meshBoxSizeY / 2 < [self windowSizeY];
           fabsf(gameObject.y) + size.y / 2 <= [self windowHalfExtentY];
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

float shipSpeed(float time) {
    static float SHIP_SPEED_TAU = 0.0f;
    if (SHIP_SPEED_TAU == 0.0f) {
        SHIP_SPEED_TAU = SHIP_SPEED_HALF_LIFE / logf(2.0f);
    }
    return SHIP_SPEED_MAX * (1 - expf(- time / SHIP_SPEED_TAU));
}

float shipDistanceTraveled(float time) {
    static float SHIP_SPEED_TAU = 0.0f;
    if (SHIP_SPEED_TAU == 0.0f) {
        SHIP_SPEED_TAU = SHIP_SPEED_HALF_LIFE / logf(2.0f);
    }
    return SHIP_SPEED_MAX * (time + SHIP_SPEED_TAU * expf(- time / SHIP_SPEED_TAU));
}

float travelDistance() {
    return shipDistanceTraveled(TIME_SHIP_TRAVEL);
}

float eyePlanetFocal() {
    return travelDistance() * DESTINATION_PLANET_END_SCALE * DESTINATION_PLANET_START_SCALE /
    (DESTINATION_PLANET_RADIUS * (DESTINATION_PLANET_END_SCALE - DESTINATION_PLANET_START_SCALE));
}

float destinationPlanetStartZ() {
    return eyePlanetFocal() * DESTINATION_PLANET_RADIUS / DESTINATION_PLANET_START_SCALE;
}

@end
