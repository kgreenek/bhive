//
//  BBHexagon.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHexagon.h"

@implementation BBHexagon

- (instancetype)initWithHexCoords:(CGPoint)hexCoords
                             type:(BBHexagonType)type
                            color:(BBHexagonColor)color
                             text:(NSString *)text {
  self = [super init];
  if (self) {
    _hexCoords = hexCoords;
    _type = type;
    _color = color;
    _text = [text copy];
  }
  return self;
}

+ (BBHexagon *)cellHexagon {
  return [[BBHexagon alloc] initWithHexCoords:CGPointMake(0, 0)
                                         type:kBBHexagonTypeCell
                                        color:[self.class randomHexagonColor]
                                         text:nil];
}

+ (BBHexagon *)centerHexagon {
  return [[BBHexagon alloc] initWithHexCoords:CGPointMake(0, 0)
                                         type:kBBHexagonTypeCenter
                                        color:kBBHexagonColorBlue
                                         text:nil];
}

+ (BBHexagon *)hexagonfromHexagon:(BBHexagon *)hexagon withHexCoords:(CGPoint)hexCoords {
  return [[BBHexagon alloc] initWithHexCoords:hexCoords
                                         type:hexagon.type
                                        color:hexagon.color
                                         text:hexagon.text];
}

+ (BBHexagon *)hexagonfromHexagon:(BBHexagon *)hexagon withText:(NSString *)text {
  return [[BBHexagon alloc] initWithHexCoords:hexagon.hexCoords
                                         type:hexagon.type
                                        color:hexagon.color
                                         text:text];
}

#pragma mark Private Methods

+ (BBHexagonColor)randomHexagonColor {
  return arc4random() % kBBHexagonColorNumColors;
}

@end
