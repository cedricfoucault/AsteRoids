//
//  HUDOverlayView.m
//  ARGame
//
//  Created by Cédric Foucault on 20/02/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "HUDOverlayView.h"
#import "PassthroughView.h"

@implementation HUDOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)pauseTapped:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"Pause"]) {
        NSLog(@"yes");
        [sender setTitle:@"Resume" forState:(UIControlStateNormal)];
        [self.delegate pause];
    } else {
        NSLog(@"no");
        [sender setTitle:@"Pause" forState:(UIControlStateNormal)];
//        sender.titleLabel.text = @"Play";
        [self.delegate resume];
    }
}
@end
