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
                            color:(BBHexagonColor)color {
  self = [super init];
  if (self) {
    _hexCoords = hexCoords;
    _type = type;
    _color = color;
  }
  return self;
}

+ (BBHexagon *)emptyCellHexagon {
  BBHexagon *hexagon = [[BBHexagon alloc] initWithHexCoords:CGPointMake(0, 0)
                                                       type:kBBHexagonTypeEmpty
                                                      color:[self.class randomHexagonColor]];
  return hexagon;
}

+ (BBHexagon *)cellHexagonWithHexCoords:(CGPoint)hexCoords color:(BBHexagonColor)color {
  BBHexagon *hexagon = [[BBHexagon alloc] initWithHexCoords:hexCoords
                                                       type:kBBHexagonTypeCell
                                                      color:color];
  return hexagon;
}

+ (BBHexagon *)centerHexagon {
  BBHexagon *hexagon = [[BBHexagon alloc] initWithHexCoords:CGPointMake(0, 0)
                                                       type:kBBHexagonTypeCenter
                                                      color:kBBHexagonColorBlack];
  return hexagon;
}

+ (BBHexagonColor)randomHexagonColor {
  return arc4random() % kBBHexagonColorNumColors;
}

@end
