//
//  BBHexagon.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  kBBHexagonColorBlue,
  kBBHexagonColorGreen,
  kBBHexagonColorOrange,
  kBBHexagonColorPurple,
  kBBHexagonColorTeal,
  kBBHexagonColorNumColors,
} BBHexagonColor;

typedef enum {
  kBBHexagonTypeCell,
  kBBHexagonTypeCenter,
} BBHexagonType;

@interface BBHexagon : NSObject

@property(nonatomic, readonly) CGPoint hexCoords;
@property(nonatomic, readonly) BBHexagonType type;
@property(nonatomic, readonly) BBHexagonColor color;

+ (BBHexagon *)cellHexagon;
+ (BBHexagon *)centerHexagon;
+ (BBHexagon *)hexagonfromHexagon:(BBHexagon *)hexagon withHexCoords:(CGPoint)hexCoords;

@end
