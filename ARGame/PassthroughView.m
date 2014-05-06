//
//  PassthroughView.m
//  ARGame
//
//  Created by Cédric Foucault on 04/05/14.
//  Copyright (c) 2014 Cédric Foucault. All rights reserved.
//

#import "PassthroughView.h"

@implementation PassthroughView

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}

@end
