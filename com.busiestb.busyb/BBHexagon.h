//
//  BBHexagon.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BBHexagonEntity;

typedef enum {
  kBBHexagonColorBlue,
  kBBHexagonColorGreen,
  kBBHexagonColorRed,
  kBBHexagonColorOrange,
  kBBHexagonColorPurple,
  kBBHexagonColorTeal,
  kBBHexagonColorNumColors,
} BBHexagonColor;

typedef enum {
  kBBHexagonTypeCell,
  kBBHexagonTypeCenter,
} BBHexagonType;

// A wrapper around a BBHexagonEntity to make setting/getting properties easier.
@interface BBHexagon : NSObject

@property(nonatomic, readonly) BBHexagonEntity *entity;
@property(nonatomic, assign) CGPoint hexCoords;
@property(nonatomic, assign) BBHexagonType type;
@property(nonatomic, assign) BBHexagonColor color;
@property(nonatomic, copy) NSString *text;

+ (instancetype)cellHexagonWithEntity:(BBHexagonEntity *)entity;
+ (instancetype)centerHexagonWithEntity:(BBHexagonEntity *)entity;

- (instancetype)initWithEntity:(BBHexagonEntity *)entity;

@end
