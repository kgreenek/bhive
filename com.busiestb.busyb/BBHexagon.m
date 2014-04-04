//
//  BBHexagon.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHexagon.h"

@implementation BBHexagon

+ (BBHexagon *)cellHexagonWithParent:(BBHexagon *)parent
                           hexCoords:(CGPoint)hexCoords {
  BBHexagon *hexagon = [[BBHexagon alloc] init];
  hexagon.parent = parent;
  hexagon.hexCoords = hexCoords;
  hexagon.type = kBBHexagonTypeCell;
  return hexagon;
}

+ (BBHexagon *)centerHexagon {
  BBHexagon *hexagon = [[BBHexagon alloc] init];
  hexagon.hexCoords = CGPointMake(0, 0);
  hexagon.type = kBBHexagonTypeCenter;
  return hexagon;
}

@end
