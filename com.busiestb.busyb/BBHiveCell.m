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
  UITextField *_editBox;
  UILabel *_textLabel;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizesSubviews = YES;

    _colorNames = @[ @"hex-blue",
                     @"hex-green",
                     @"hex-orange",
                     @"hex-purple",
                     @"hex-red",
                     @"hex-teal", ];
    _editBox = [[UITextField alloc] init];
    _editBox.backgroundColor = [UIColor whiteColor];
    _editBox.returnKeyType = UIReturnKeyDone;
    _editBox.alpha = 0;
    [self addSubview:_editBox];

    _textLabel = [[UILabel alloc] init];
    _textLabel.alpha = 0;
    _textLabel.text = @"Some text";
    _textLabel.font = [UIFont fontWithName:@"soemthing" size:12];
    _textLabel.numberOfLines = 3;
    _textLabel.textAlignment = NSTextAlignmentCenter;
    [_textLabel sizeToFit];
    [self addSubview:_textLabel];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  static CGFloat kTextBoxHorizontalPadding = 30;
  _editBox.frame = CGRectMake(kTextBoxHorizontalPadding,
                              self.bounds.size.height / 3,
                              self.bounds.size.width - 2 * kTextBoxHorizontalPadding,
                              self.bounds.size.height / 3);
  _textLabel.frame = CGRectMake(kTextBoxHorizontalPadding,
                                self.bounds.size.height / 3,
                                self.bounds.size.width - 2 * kTextBoxHorizontalPadding,
                                self.bounds.size.height / 3);
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

- (void)setActive:(BOOL)active {
  _active = active;
  if (!_active) {
    self.editing = NO;
  }
  _textLabel.alpha = active && !_editing ? 1 : 0;
}

- (void)setEditing:(BOOL)editing {
  _editing = editing;
  _textLabel.alpha = _editing || !_active ? 0 : 1;
  _editBox.alpha = _editing && _active ? 1 : 0;
}

- (void)setText:(NSString *)text {
  _editBox.text = text;
  _textLabel.text = text;
  [_textLabel sizeToFit];
  [self setNeedsLayout];
}

#pragma mark Private Methods

- (UIImageView *)hexagonImageViewWithColor:(BBHexagonColor)color {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:_colorNames[color]]];
}

- (UIImageView *)centerHexagonImageView {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"center"]];
}

@end
