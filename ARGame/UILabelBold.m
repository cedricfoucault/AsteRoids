//
//  UILabelBold.m
//  AsteRoids
//
//  Created by Cédric Foucault on 13/07/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "UILabelBold.h"
#import "Constants.h"

@implementation UILabelBold

- (void)awakeFromNib {
    [super awakeFromNib];
    self.font = [UIFont fontWithName:FONT_BOLD_NAME size:FONT_SIZE];
}

@end
