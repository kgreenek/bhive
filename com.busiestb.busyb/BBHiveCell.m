//
//  BBHiveCell.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHiveCell.h"

#include <stdlib.h>

#import "BBHexagon.h"

static const CGFloat kHexagonWidth = 48;
static const CGFloat kHexagonHeight = 55;

@implementation BBHiveCell {
  NSArray *_colorNames;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _colorNames = @[ @"hex-black",
                     @"hex-blue",
                     @"hex-green",
                     @"hex-lavender",
                     @"hex-mint",
                     @"hex-orange",
                     @"hex-orange",
                     @"hex-pink",
                     @"hex-purp",
                     @"hex-salmon",
                     @"hex-teal", ];
  }
  return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
  return CGSizeMake(kHexagonWidth, kHexagonHeight);
}

- (void)setHexagon:(BBHexagon *)hexagon {
  if (hexagon.type == kBBHexagonTypeCenter) {
    self.backgroundView = [self centerHexagonImageView];
  } else {
    self.backgroundView = [self hexagonImageViewWithRandomColor];
  }
}

#pragma mark Private Methods

- (UIImageView *)hexagonImageViewWithRandomColor {
  int r = arc4random() % 11;
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:_colorNames[r]]];
}

- (UIImageView *)centerHexagonImageView {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hex-center"]];
}

@end
