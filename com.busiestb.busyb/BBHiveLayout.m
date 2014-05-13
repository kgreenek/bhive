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

@interface BBHiveLayout ()

// The active size is the view's size that doesn't overlap with the keyboard.
@property(nonatomic, readonly) CGSize activeSize;

@end

@implementation BBHiveLayout {
  CGFloat _hexagonPadding;
  NSDictionary *_layoutInfo;
  NSIndexPath *_activeCellIndexPath;
  CGSize _keyboardSize;
  BOOL _animatingBoundsChange;
}

- (instancetype)initWithDelegate:(id<BBHiveLayoutDelegate>)delegate
                  activeCellPath:(NSIndexPath *)activeCellIndexPath
                    keyboardSize:(CGSize)keyboardSize {
  self = [super init];
  if (self) {
    _delegate = delegate;
    _hexagonPadding = (activeCellIndexPath == nil)
        ? kDefaultHexagonPadding : kCellActiveHexagonPadding;
    _activeCellIndexPath = activeCellIndexPath;
    _keyboardSize = keyboardSize;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGPoint)nearestHexCoordsFromScreenCoords:(CGPoint)screenCoords {
  screenCoords.x -= self.collectionView.bounds.size.width / 2;
  screenCoords.y -= self.collectionView.bounds.size.height / 2;
  CGFloat y = roundf(screenCoords.y / (kHexagonHeight - kHexagonPointHeight + _hexagonPadding));
  CGFloat x = roundf(screenCoords.x / (kHexagonWidth + _hexagonPadding) - y / 2);
  return CGPointMake(x, y);
}

- (CGRect)frameForHexagonAtHexCoords:(CGPoint)hexCoords {
  CGPoint position = [self positionForHexagonWithHexCoords:hexCoords];
  CGPoint offsetForActiveHexagon = [self offsetForActiveHexagon];
  position.x += offsetForActiveHexagon.x;
  position.y += offsetForActiveHexagon.y;
  return CGRectMake(position.x, position.y, kHexagonWidth, kHexagonHeight);
}

#pragma mark Overriden Methods

- (void)prepareLayout {
  NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
  for (NSInteger section = 0; section < [self.collectionView numberOfSections]; ++section) {
    for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
      UICollectionViewLayoutAttributes *itemAttributes =
          [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
      itemAttributes.frame = [self frameForHexagonAtIndexpath:indexPath];
      itemAttributes.zIndex = [indexPath isEqual:_activeCellIndexPath] ? 1 : 0;
      // A new zIndex doesn't get set until a view is recycled when we transition from one layout
      // to another, so we have to fake it with this transform in the z direction.
      itemAttributes.transform3D = CATransform3DMakeTranslation(0, 0, itemAttributes.zIndex);
      cellLayoutInfo[indexPath] = itemAttributes;
    }
  }
  _layoutInfo = @{ kHiveCellIdentifier : cellLayoutInfo };
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
      if (attrs.frame.origin.x < minX) {
        minX = attrs.frame.origin.x;
      }
      if (attrs.frame.origin.x + attrs.size.width > maxX) {
        maxX = attrs.frame.origin.x + attrs.size.width;
      }
      if (attrs.frame.origin.y < minY) {
        minY = attrs.frame.origin.y;
      }
      if (attrs.frame.origin.y + attrs.size.height > maxY) {
        maxY = attrs.frame.origin.y + attrs.size.height;
      }
    }
  }
  // We would expect to just return contentSize here, but if the contentSize is smaller than the
  // collectionView's frame, the contentOffset gets borked by an Apple bug. As a workaround,
  // always make sure the returned contentSize is at least as big as the collectionView frame.
  CGSize contentSize = CGSizeMake(maxX - minX, maxY - minY);
  CGRect collectionViewFrame = self.collectionView.bounds;
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

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
  return CGPointMake(0, 0);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
  return YES;
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds {
  [super prepareForAnimatedBoundsChange:oldBounds];
  _animatingBoundsChange = YES;
}

- (void)finalizeAnimatedBoundsChange {
  [super finalizeAnimatedBoundsChange];
  _animatingBoundsChange = NO;
}

- (UICollectionViewLayoutAttributes *)
    initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
  if (_animatingBoundsChange) {
    // If the view is rotating, appearing items should animate from their current attributes
    // (specify 'nil').
    return nil;
  }
  return [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)
    finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
  if (_animatingBoundsChange) {
    // If the view is rotating, disappearing items should animate to their new attributes.
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
  }
  return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
}

#pragma mark Private Methods

- (CGRect)frameForHexagonAtIndexpath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:_activeCellIndexPath]) {
    // Center the active hexagon.
    return CGRectMake(self.activeSize.width / 2 - kActiveHexagonWidth / 2,
                      self.activeSize.height / 2 - kActiveHexagonHeight / 2,
                      kActiveHexagonWidth,
                      kActiveHexagonHeight);
  }
  CGPoint hexCoords = [_delegate hexCoordinatesForItemAtIndexPath:indexPath];
  return [self frameForHexagonAtHexCoords:hexCoords];
}

- (CGPoint)positionForHexagonWithHexCoords:(CGPoint)hexCoords {
  CGFloat x = ((_hexagonPadding + kHexagonWidth) * hexCoords.x)
      + (hexCoords.y * kHexagonWidth / 2)
      + (hexCoords.y * _hexagonPadding / 2)
      + self.collectionView.bounds.size.width / 2 - kHexagonWidth / 2;
  CGFloat y = (kHexagonHeight - kHexagonPointHeight + _hexagonPadding) * hexCoords.y
      + self.collectionView.bounds.size.height / 2 - kHexagonHeight / 2;
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

- (CGSize)activeSize {
  // NOTE: This assumes that the collection view occupies the full screen.
  return CGSizeMake(self.collectionView.bounds.size.width,
                    self.collectionView.bounds.size.height - _keyboardSize.height);
}

@end
