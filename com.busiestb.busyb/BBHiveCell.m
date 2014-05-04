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
  UITextField *_textBox;
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
    _textBox = [[UITextField alloc] init];
    _textBox.backgroundColor = [UIColor whiteColor];
    _textBox.returnKeyType = UIReturnKeyDone;
    _textBox.hidden = YES;
    [self addSubview:_textBox];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  static CGFloat kTextBoxHorizontalPadding = 30;
  _textBox.frame = CGRectMake(kTextBoxHorizontalPadding,
                              self.frame.size.height / 3,
                              self.frame.size.width - 2 * kTextBoxHorizontalPadding,
                              self.frame.size.height / 3);
}

- (CGSize)sizeThatFits:(CGSize)size {
  return CGSizeMake(kHexagonWidth, kHexagonHeight);
}

- (void)setHexagon:(BBHexagon *)hexagon {
  _hexagon = hexagon;
  if (hexagon.type == kBBHexagonTypeCenter) {
    self.backgroundView = [self centerHexagonImageView];
  } else {
    self.backgroundView = [self hexagonImageViewWithColor:hexagon.color];
  }
}

- (void)setTextBoxHidden:(BOOL)hidden {
  _textBoxHidden = hidden;
//  _textBox.hidden = hidden;
  [self setNeedsLayout];
}

#pragma mark Private Methods

- (UIImageView *)hexagonImageViewWithColor:(BBHexagonColor)color {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:_colorNames[color]]];
}

- (UIImageView *)centerHexagonImageView {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hex-center"]];
}

@end
