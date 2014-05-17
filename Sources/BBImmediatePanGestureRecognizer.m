//
//  BBImmediatePanGestureRecognizer.m
//  com.hexkvlt.bhive
//
//  Created by Kevin Greene on 5/14/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBImmediatePanGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation BBImmediatePanGestureRecognizer {
  NSTimer *_tapTimer;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _delay = 0.2;
  }
  return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  _tapTimer = [NSTimer scheduledTimerWithTimeInterval:_delay
                                               target:self
                                             selector:@selector(startGesture)
                                             userInfo:nil
                                              repeats:NO];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [_tapTimer invalidate];
  _tapTimer = nil;
}

- (void)startGesture {
  if (self.state == UIGestureRecognizerStatePossible) {
    self.state = UIGestureRecognizerStateBegan;
  }
  _tapTimer = nil;
}

@end
