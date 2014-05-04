//
//  BBHiveLayout.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHiveLayout.h"

static NSString * kHiveCellIdentifier = @"HiveCell";
static const CGFloat kHexagonWidth = 48;
static const CGFloat kHexagonHeight = 55;
static const CGFloat kActiveHexagonWidth = 240;   // kHexagonWidth * 5
static const CGFloat kActiveHexagonHeight = 275;  // kHexagonHeight * 5
static const CGFloat kHexagonPointHeight = 14;
static const CGFloat kDefaultHexagonPadding = 2;
static const CGFloat kCellActiveHexagonPadding = 120;

@implementation BBHiveLayout {
  CGFloat _hexagonPadding;
  NSDictionary *_layoutInfo;
  NSIndexPath *_activeCellIndexPath;
}

- (instancetype)initWithDelegate:(id<BBHiveLayoutDelegate>)delegate
                  activeCellPath:(NSIndexPath *)activeCellIndexPath {
  self = [super init];
  if (self) {
    _delegate = delegate;
    if (activeCellIndexPath) {
      _hexagonPadding = kCellActiveHexagonPadding;
    } else {
      _hexagonPadding = kDefaultHexagonPadding;
    }
    _activeCellIndexPath = activeCellIndexPath;
  }
  return self;
}

- (CGPoint)nearestHexCoordsFromScreenCoords:(CGPoint)screenCoords {
  screenCoords.x -= self.collectionView.frame.size.width / 2;
  screenCoords.y -= self.collectionView.frame.size.height / 2;
  CGFloat y = roundf(screenCoords.y / (kHexagonHeight - kHexagonPointHeight + _hexagonPadding));
  CGFloat x = roundf(screenCoords.x / (kHexagonWidth + _hexagonPadding) - y / 2);
  return CGPointMake(x, y);
}

#pragma mark Overriden Methods

- (void)prepareLayout {
  NSMutableDictionary *layoutInfo = [NSMutableDictionary dictionary];
  NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
  NSInteger sectionCount = [self.collectionView numberOfSections];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  for (NSInteger section = 0; section < sectionCount; ++section) {
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
    for (NSInteger item = 0; item < itemCount; item++) {
      indexPath = [NSIndexPath indexPathForItem:item inSection:section];
      UICollectionViewLayoutAttributes *itemAttributes =
          [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
      itemAttributes.frame = [self frameForHexagonAtIndexpath:indexPath];
      cellLayoutInfo[indexPath] = itemAttributes;
    }
  }
  layoutInfo[kHiveCellIdentifier] = cellLayoutInfo;
  _layoutInfo = layoutInfo;
}

- (CGSize)collectionViewContentSize {
  CGFloat minX = 0;
  CGFloat maxX = 0;
  CGFloat minY = 0;
  CGFloat maxY = 0;
  NSEnumerator *layoutInfoEnumerator = [_layoutInfo keyEnumerator];
  id layoutInfoKey;
  while ((layoutInfoKey = [layoutInfoEnumerator nextObject])) {
    NSDictionary *cellLayoutInfo = [_layoutInfo objectForKey:layoutInfoKey];
    NSEnumerator *cellLayoutInfoEnumerator = [cellLayoutInfo keyEnumerator];
    id cellInfoKey;
    while ((cellInfoKey = [cellLayoutInfoEnumerator nextObject])) {
      UICollectionViewLayoutAttributes *attrs = [cellLayoutInfo objectForKey:cellInfoKey];
      if (attrs.frame.origin.x < minX) minX = attrs.frame.origin.x;
      if (attrs.frame.origin.x + attrs.size.width > maxX)
        maxX = attrs.frame.origin.x + attrs.size.width;
      if (attrs.frame.origin.y < minY) minY = attrs.frame.origin.y;
      if (attrs.frame.origin.y + attrs.size.height > maxY)
        maxY = attrs.frame.origin.y + attrs.size.height;
    }
  }
  // We would expect to just return contentSize here, but if the contentSize is smaller than the
  // collectionView's frame, the contentOffset gets borked by an Apple bug. As a workaround,
  // always make sure the returned contentSize is at least as big as the collectionView frame.
  CGSize contentSize = CGSizeMake(maxX - minX, maxY - minY);
  CGRect collectionViewFrame = self.collectionView.frame;
  return CGSizeMake(fmaxf(contentSize.width, CGRectGetWidth(collectionViewFrame)),
                    fmaxf(contentSize.height, CGRectGetHeight(collectionViewFrame)));
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
  return _layoutInfo[kHiveCellIdentifier][indexPath];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSMutableArray *attrs = [NSMutableArray arrayWithCapacity:_layoutInfo.count];
  [_layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                   NSDictionary *elementsInfo,
                                                   BOOL *stop) {
    [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                      UICollectionViewLayoutAttributes *cellAttrs,
                                                      BOOL *innerStop) {
      if (CGRectIntersectsRect(rect, cellAttrs.frame)) {
        [attrs addObject:cellAttrs];
      }
    }];
  }];
  return attrs;
}

#pragma mark Private Methods

- (CGRect)frameForHexagonAtIndexpath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:_activeCellIndexPath]) {
    // Center the active hexagon.
    return CGRectMake(self.collectionView.frame.size.width / 2 - kActiveHexagonWidth / 2,
                      self.collectionView.frame.size.height / 2 - kActiveHexagonHeight / 2,
                      kActiveHexagonWidth,
                      kActiveHexagonHeight);
  }
  CGPoint hexCoords = [_delegate hexCoordinatesForItemAtIndexPath:indexPath];
  CGPoint position = [self positionForHexagonWithHexCoords:hexCoords];
  CGPoint offsetForActiveHexagon = [self offsetForActiveHexagon];
  position.x += offsetForActiveHexagon.x;
  position.y += offsetForActiveHexagon.y;
  return CGRectMake(position.x, position.y, kHexagonWidth, kHexagonHeight);
}

- (CGPoint)positionForHexagonWithHexCoords:(CGPoint)hexCoords {
  CGFloat x = ((_hexagonPadding + kHexagonWidth) * hexCoords.x)
      + (hexCoords.y * kHexagonWidth / 2)
      + (hexCoords.y * _hexagonPadding / 2)
      + self.collectionView.frame.size.width / 2 - kHexagonWidth / 2;
  CGFloat y = (kHexagonHeight - kHexagonPointHeight + _hexagonPadding) * hexCoords.y
      + self.collectionView.frame.size.height / 2 - kHexagonHeight / 2;
  return CGPointMake(x, y);
}

- (CGPoint)offsetForActiveHexagon {
  if (!_activeCellIndexPath) {
    return CGPointZero;
  }
  CGPoint hexCoords =
      [_delegate hexCoordinatesForItemAtIndexPath:_activeCellIndexPath];
  CGFloat x = ((_hexagonPadding + kHexagonWidth) * hexCoords.x)
      + (hexCoords.y * kHexagonWidth / 2)
      + (hexCoords.y * _hexagonPadding / 2);
  CGFloat y = (kHexagonHeight - kHexagonPointHeight + _hexagonPadding) * hexCoords.y;
  return CGPointMake(-x, -y);
}

@end
