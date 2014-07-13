//
//  UILabelSmall.m
//  AsteRoids
//
//  Created by Cédric Foucault on 13/07/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "UILabelSmall.h"
#import "Constants.h"

@implementation UILabelSmall

- (void)awakeFromNib {
    [super awakeFromNib];
    self.font = [UIFont fontWithName:FONT_LIGHT_NAME size:FONT_SIZE_SMALL];
}

@end
