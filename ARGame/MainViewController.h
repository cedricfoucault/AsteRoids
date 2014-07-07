//
//  MainViewController.h
//  ARGame
//
//  Created by Cédric Foucault on 08/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HUDOverlayView.h"

@interface MainViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *hudInstructions;
@property (weak, nonatomic) IBOutlet UIImageView *targetViewfinder;
@property (weak, nonatomic) IBOutlet UIView *instruction1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *instruction1CenterXConstraint;
@property (weak, nonatomic) IBOutlet UIView *instruction2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *instruction2CenterXConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *gunViewfinderInstruction;
@property (weak, nonatomic) IBOutlet UIProgressView *reloadProgressViewInstruction;
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *overlayBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startButtonCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startButtonCenterXConstraint;

@property (strong, nonatomic) IBOutlet HUDOverlayView *hudOverlayView;
@property (weak, nonatomic) IBOutlet UIView *ingameOverlay;
@property (weak, nonatomic) IBOutlet UIView *hitOverlayView;
@property (weak, nonatomic) IBOutlet UIView *gameoverOverlay;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gameoverOverlayTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gameoverOverlayBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIView *endgameOverlay;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *endgameOverlayTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *endgameOverlayBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *asteroidsLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *asteroidsLabelRightAlignConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *asteroidsLabelLeftAlignConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *asteroidsIconLeftAlignConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *asteroidsIconBottomAlignConstraint;
@property (weak, nonatomic) IBOutlet UIView *lifebarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maxLifebarWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lifebarWidthConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *gunViewfinder;
@property (weak, nonatomic) IBOutlet UIProgressView *reloadProgressView;

- (IBAction)markerButtonTapped;
- (IBAction)startButtonTapped;
- (IBAction)playAgainButtonTapped;

@end
