//
//  BBHexagon.m
//  com.hexkvlt.bhive
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHexagon.h"

#import "BBHexagonEntity.h"

@implementation BBHexagon

- (instancetype)initWithEntity:(BBHexagonEntity *)entity {
  self = [super init];
  if (self) {
    _entity = entity;
  }
  return self;
}

+ (instancetype)cellHexagonWithEntity:(BBHexagonEntity *)entity {
  BBHexagon *hexagon = [[BBHexagon alloc] initWithEntity:entity];
  hexagon.type = kBBHexagonTypeCell;
  hexagon.hexCoords = CGPointMake(0, 0);
  hexagon.color = [BBHexagon randomHexagonColor];
  hexagon.text = nil;
  return hexagon;
}

+ (instancetype)centerHexagonWithEntity:(BBHexagonEntity *)entity {
  BBHexagon *hexagon = [[BBHexagon alloc] initWithEntity:entity];
  hexagon.type = kBBHexagonTypeCenter;
  hexagon.hexCoords = CGPointMake(0, 0);
  // The color isn't used for center hexagons.
  hexagon.color = kBBHexagonColorBlue;
  hexagon.text = nil;
  return hexagon;
}

- (CGPoint)hexCoords {
  return CGPointMake([_entity.hexCoordsX floatValue], [_entity.hexCoordsY floatValue]);
}

- (void)setHexCoords:(CGPoint)hexCoords {
  _entity.hexCoordsX = @( hexCoords.x );
  _entity.hexCoordsY = @( hexCoords.y );
}

- (BBHexagonType)type {
  return [_entity.type intValue];
}

- (void)setType:(BBHexagonType)type {
  _entity.type = @( type );
}

- (BBHexagonColor)color {
  return [_entity.color intValue];
}

- (void)setColor:(BBHexagonColor)color {
  _entity.color = @( color );
}

- (NSString *)text {
  return _entity.text;
}

- (void)setText:(NSString *)text {
  _entity.text = [text copy];
}

#pragma mark Private Methods

+ (BBHexagonColor)randomHexagonColor {
  return arc4random() % kBBHexagonColorNumColors;
}

@end
