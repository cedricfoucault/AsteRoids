//
//  HUDOverlayView.h
//  ARGame
//
//  Created by Cédric Foucault on 20/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HUDDelegate <NSObject>

- (void)pause;
- (void)resume;

@end

@interface HUDOverlayView : UIView
@property (weak, nonatomic) IBOutlet UILabel *lifeCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *viewFinder;
@property (weak, nonatomic) IBOutlet UILabel *scoreCountLabel;
- (IBAction)pauseTapped:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet id<HUDDelegate> delegate;

@end
