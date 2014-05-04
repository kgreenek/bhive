//
//  BBHiveViewController.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHiveViewController.h"

#import "BBHexagon.h"
#import "BBHiveCell.h"
#import "BBHiveLayout.h"

static NSString * kHiveCellIdentifier = @"HiveCell";

@interface BBHiveViewController ()<UICollectionViewDataSource,
                                   UICollectionViewDelegate,
                                   BBHiveLayoutDelegate>
@end

@implementation BBHiveViewController {
  NSMutableArray *_sections;
  UICollectionView *_hiveCollectionView;
  NSIndexPath *_activeCell;
  BBHiveCell *_panningCell;
  BOOL _panningCellIsNew;
  BBHiveLayout *_hiveLayout;
}

- (void)loadView {
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self activeCell:nil];
  _hiveCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                           collectionViewLayout:_hiveLayout];
  _hiveCollectionView.scrollEnabled = NO;
  _hiveCollectionView.dataSource = self;
  _hiveCollectionView.delegate = self;
  [_hiveCollectionView registerClass:[BBHiveCell class]
          forCellWithReuseIdentifier:kHiveCellIdentifier];
  _hiveCollectionView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _hiveCollectionView.backgroundView =
      [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hexa-bg"]];
  self.view = _hiveCollectionView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  NSMutableArray *cells = [NSMutableArray array];
  [cells addObject:[BBHexagon centerHexagon]];
  _sections = [NSMutableArray array];
  [_sections addObject:cells];
  [_hiveCollectionView reloadData];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return [_sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [_sections[section] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  BBHiveCell *cell =
      [_hiveCollectionView dequeueReusableCellWithReuseIdentifier:kHiveCellIdentifier
                                                     forIndexPath:indexPath];
  cell.hexagon = [self hexagonForIndexPath:indexPath];
  [cell addGestureRecognizer:
      [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanHexagon:)]];
  [cell sizeToFit];
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([_activeCell isEqual:indexPath]) {
    [self setActiveCell:nil];
  } else if (indexPath.item != 0) {
    [self setActiveCell:indexPath];
  }
}

#pragma mark BBHiveCollectionViewLayoutDelegate

- (CGPoint)hexCoordinatesForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self hexagonForIndexPath:indexPath].hexCoords;
}

#pragma mark Private Methods

- (BBHexagon *)hexagonForIndexPath:(NSIndexPath *)indexPath {
  return _sections[indexPath.section][indexPath.item];
}

- (void)setActiveCell:(NSIndexPath *)activeCell {
  if ([_activeCell isEqual:activeCell]) {
    return;
  }
  if (_activeCell) {
    [(BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCell] setTextBoxHidden:YES];
  }
  _activeCell = activeCell;
  [(BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCell] setTextBoxHidden:NO];
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self activeCell:activeCell];
  [_hiveCollectionView setCollectionViewLayout:_hiveLayout animated:YES];
}

- (void)didPanHexagon:(UIPanGestureRecognizer *)recognizer {
  if (_activeCell) {
    return;
  }
  CGPoint location = [recognizer locationInView:recognizer.view.superview];
  if (recognizer.state == UIGestureRecognizerStateEnded) {
    [_panningCell removeFromSuperview];
    CGPoint hexCoords = [_hiveLayout nearestHexCoordsFromScreenCoords:location];
    BBHexagon *hexagon;
    if ([self hexagonAtHexCoords:hexCoords] != nil) {
      if (_panningCellIsNew) {
        _panningCell = nil;
        return;
      }
      hexagon = _panningCell.hexagon;
    } else {
      hexagon = [BBHexagon hexagonfromHexagon:_panningCell.hexagon withHexCoords:hexCoords];
    }
    [_sections[0] addObject:hexagon];
    [UIView animateWithDuration:0 animations:^{
      [_hiveCollectionView performBatchUpdates:^{
        [_hiveCollectionView insertItemsAtIndexPaths:
            @[ [NSIndexPath indexPathForItem:[_sections[0] count] - 1 inSection:0] ]];
      } completion:nil];
    }];
    _panningCell = nil;
    return;
  }
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    if (_panningCell) {
      // This really should never be able to happen.
      return;
    }
    _panningCell = [[BBHiveCell alloc] init];
    BBHexagon *hexagon = [(BBHiveCell *)recognizer.view hexagon];
    if (hexagon.type == kBBHexagonTypeCell) {
      NSUInteger item = [_sections[0] indexOfObject:hexagon];
      [_sections[0] removeObject:hexagon];
      [UIView animateWithDuration:0 animations:^{
        [_hiveCollectionView performBatchUpdates:^{
          [_hiveCollectionView deleteItemsAtIndexPaths:
              @[ [NSIndexPath indexPathForItem:item inSection:0] ]];
        } completion:nil];
      }];
      _panningCell.hexagon = hexagon;
      _panningCellIsNew = NO;
    } else {
      _panningCell.hexagon = [BBHexagon cellHexagon];
      _panningCellIsNew = YES;
    }
    [_panningCell sizeToFit];
    [_hiveCollectionView addSubview:_panningCell];
  }
  _panningCell.center = location;
}

- (BBHexagon *)hexagonAtHexCoords:(CGPoint)hexCoords {
  // TODO: Optimize this. Blech.
  for (BBHexagon *hexagon in _sections[0]) {
    if (hexagon.hexCoords.x == hexCoords.x && hexagon.hexCoords.y == hexCoords.y) {
      return hexagon;
    }
  }
  return nil;
}

@end
