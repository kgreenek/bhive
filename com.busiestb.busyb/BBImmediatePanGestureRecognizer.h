//
//  BBImmediatePanGestureRecognizer.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 5/14/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BBImmediatePanGestureRecognizer : UIPanGestureRecognizer

@property(nonatomic, assign) NSTimeInterval delay;

@end
