//
//  BBHiveCell.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHiveCell.h"

#include <stdlib.h>

#import "BBImmediatePanGestureRecognizer.h"
#import "BBHexagon.h"
#import "UIView+ColorOfPoint.h"

static const CGFloat kHexagonWidth = 48;
static const CGFloat kHexagonHeight = 55;

@implementation BBHiveCell {
  UITextView *_editBox;
  UIView *_editBoxBackground;
  UILabel *_textLabel;
  UIImageView *_trashView;
  BBImmediatePanGestureRecognizer *_panRecognizer;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _trashHidden = YES;
    _editBoxBackground = [[UIView alloc] init];
    _editBoxBackground.layer.cornerRadius = 8;
    _editBoxBackground.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    _editBoxBackground.alpha = 0;
    [self addSubview:_editBoxBackground];

    _editBox = [[UITextView alloc] init];
    _editBox.keyboardAppearance = UIKeyboardAppearanceDark;
    _editBox.backgroundColor = [UIColor clearColor];
    _editBox.font = [UIFont fontWithName:@"GillSans" size:20];
    _editBox.textColor = [UIColor colorWithRed:23 / 255 green:23 / 255 blue:23 / 255 alpha:1];
    _editBox.alpha = 0;
    [self addSubview:_editBox];

    _textLabel = [[UILabel alloc] init];
    _textLabel.alpha = 0;
    _textLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:20];
    _textLabel.textColor = [UIColor colorWithRed:23 / 255 green:23 / 255 blue:23 / 255 alpha:1];
    _textLabel.numberOfLines = 4;
    _textLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_textLabel];

    _trashView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"center-trash"]];
    _trashView.hidden = _trashHidden;
    [self addSubview:_trashView];

    _panRecognizer = [[BBImmediatePanGestureRecognizer alloc] init];
    _panRecognizer.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:_panRecognizer];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  static CGFloat kTextBoxHorizontalPadding = 16;
  static CGFloat kInnerTextBoxPadding = 6;
  _editBoxBackground.frame = CGRectMake(kTextBoxHorizontalPadding,
                                        self.bounds.size.height / 3,
                                        self.bounds.size.width - 2 * kTextBoxHorizontalPadding,
                                        self.bounds.size.height / 3);
  _editBox.frame =
      CGRectMake(_editBoxBackground.frame.origin.x + kInnerTextBoxPadding,
                 _editBoxBackground.frame.origin.y + kInnerTextBoxPadding,
                 _editBoxBackground.frame.size.width - 2 * kInnerTextBoxPadding,
                 _editBoxBackground.frame.size.height - 2 * kInnerTextBoxPadding);
  CGSize size =
      [_textLabel sizeThatFits:CGSizeMake(self.bounds.size.width - 2 * kTextBoxHorizontalPadding,
                                          self.bounds.size.height / 2)];
  _textLabel.frame = CGRectMake((self.bounds.size.width  - size.width) / 2,
                                (self.bounds.size.height  - size.height) / 2,
                                size.width,
                                size.height);
  _trashView.frame = self.bounds;
}

- (CGSize)sizeThatFits:(CGSize)size {
  return CGSizeMake(kHexagonWidth, kHexagonHeight);
}

- (void)setHexagon:(BBHexagon *)hexagon {
  _hexagon = hexagon;
  [self update];
}

- (void)setActive:(BOOL)active {
  _active = active;
  if (!_active) {
    self.editing = NO;
  }
  _textLabel.alpha = active && !_editing ? 1 : 0;
}

- (void)setEditing:(BOOL)editing {
  if (_editing == editing) {
    return;
  }
  _editing = editing;
  _textLabel.alpha = _editing || !_active ? 0 : 1;
  _editBox.alpha = _editing && _active ? 1 : 0;
  _editBoxBackground.alpha = _editBox.alpha;
  if (!_editing) {
    [_delegate didFinishEditingCell:self];
    [_editBox resignFirstResponder];
  } else {
    [_editBox becomeFirstResponder];
  }
}

- (NSString *)editBoxText {
  return _editBox.text;
}

- (void)setTrashHidden:(BOOL)trashHidden {
  _trashHidden = trashHidden;
  _trashView.hidden = _trashHidden;
  self.backgroundView.hidden = !_trashHidden;
}

- (void)update {
  self.backgroundView = _hexagon.type == kBBHexagonTypeCenter
      ? [self centerHexagonImageView] : [self hexagonImageViewWithColor:_hexagon.color];
  _textLabel.text = _hexagon.text ?: @"Tap to Add Text";
  _editBox.text = _hexagon.text;
  _panRecognizer.delay = _hexagon.type == kBBHexagonTypeCenter ? 0 : 0.2;
}

#pragma mark Overridden Methods

- (void)prepareForReuse {
  [_panRecognizer removeTarget:nil action:NULL];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if ([self alphaOfPoint:point] < 0.01) {
    return nil;
  }
  return [super hitTest:point withEvent:event];
}

#pragma mark Action Targets

- (void)addDidPanTarget:(id)target action:(SEL)action {
  [_panRecognizer addTarget:target action:action];
}

- (void)removeDidPanTarget:(id)target action:(SEL)action {
  [_panRecognizer removeTarget:target action:action];
}

#pragma mark Private Methods

- (UIImageView *)hexagonImageViewWithColor:(BBHexagonColor)color {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:[self imageNameForColor:color]]];
}

- (UIImageView *)centerHexagonImageView {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"center"]];
}

- (NSString *)imageNameForColor:(BBHexagonColor)color {
  switch (color) {
    case kBBHexagonColorBlue:
      return @"hex-blue";
    case kBBHexagonColorGreen:
      return @"hex-green";
    case kBBHexagonColorRed:
      return @"hex-red";
    case kBBHexagonColorOrange:
      return @"hex-orange";
    case kBBHexagonColorPurple:
      return @"hex-purple";
    case kBBHexagonColorTeal:
      return @"hex-teal";
    case kBBHexagonColorNumColors:
      NSLog(@"ERROR: Invalid color");
      return nil;
  }
}

@end
