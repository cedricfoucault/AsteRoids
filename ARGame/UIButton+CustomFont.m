//
//  UIButton+CustomFont.m
//  AsteRoids
//
//  Created by Cédric Foucault on 13/07/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "UIButton+CustomFont.h"
#import "Constants.h"

@implementation UIButton (CustomFont)

- (void)awakeFromNib {
    [super awakeFromNib];
//    self.titleLabel.font = [UIFont fontWithName:FONT_LIGHT_NAME size:FONT_SIZE];
    UIFont *font = [UIFont fontWithName:FONT_LIGHT_NAME size:FONT_SIZE];
    UIColor *colorNormal = [UIColor colorWithRed:0 green:240/255.0 blue:246/255.0 alpha:1.0];
    UIColor *colorHighlighted = [UIColor colorWithRed:23/255.0 green:151/255.0 blue:158/255.0 alpha:1.0];
    NSNumber *underlineValue = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
    
    NSDictionary *attributesNormal = [NSDictionary
                                      dictionaryWithObjects:@[
                                                              font, colorNormal, underlineValue
                                                              ]
                                      forKeys:@[
                                                NSFontAttributeName,
                                                NSForegroundColorAttributeName,
                                                NSUnderlineStyleAttributeName
                                                ]];
    NSDictionary *attributesHighlighted = [NSDictionary
                                           dictionaryWithObjects:@[
                                                              font, colorHighlighted, underlineValue
                                                              ]
                                           forKeys:@[
                                                NSFontAttributeName,
                                                NSForegroundColorAttributeName,
                                                NSUnderlineStyleAttributeName
                                                ]];
    
    NSMutableAttributedString *titleNormal = [[NSMutableAttributedString alloc]
                                              initWithString:self.titleLabel.text
                                              attributes:attributesNormal];
    NSMutableAttributedString *titleHighlighted = [[NSMutableAttributedString alloc]
                                              initWithString:self.titleLabel.text
                                              attributes:attributesHighlighted];

    [self setAttributedTitle:titleNormal forState:UIControlStateNormal];
    [self setAttributedTitle:titleHighlighted forState:UIControlStateHighlighted];
    
}

@end
