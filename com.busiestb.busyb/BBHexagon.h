//
//  BBHexagon.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  kBBHexagonTypeCell,
  kBBHexagonTypeCenter,
} BBHexagonType;

@interface BBHexagon : NSObject

@property(nonatomic, assign) CGPoint hexCoords;
@property(nonatomic, assign) BBHexagonType type;
@property(nonatomic, strong) BBHexagon *parent;

+ (BBHexagon *)cellHexagonWithParent:(BBHexagon *)parent
                           hexCoords:(CGPoint)hexCoords;
+ (BBHexagon *)centerHexagon;

@end
