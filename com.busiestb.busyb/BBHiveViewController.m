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
  NSIndexPath *_activeCellPath;
  BBHiveCell *_panningCell;
  BOOL _panningCellIsNew;
  BBHiveLayout *_hiveLayout;
}

- (void)loadView {
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self activeCellPath:nil];
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
  UIPanGestureRecognizer *recognizer =
      [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanHexagon:)];
  recognizer.maximumNumberOfTouches = 1;
  [cell addGestureRecognizer:recognizer];
  [cell sizeToFit];
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([_activeCellPath isEqual:indexPath]) {
    [self setActiveCellPath:nil];
  } else if (indexPath.item != 0) {
    [self setActiveCellPath:indexPath];
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

- (void)setActiveCellPath:(NSIndexPath *)activeCellPath {
  if ([_activeCellPath isEqual:activeCellPath]) {
    return;
  }
  BBHiveCell *previousActiveCell =
      (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCellPath];
  _activeCellPath = activeCellPath;
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self activeCellPath:activeCellPath];
  BBHiveCell *activeCell =
      (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCellPath];
  previousActiveCell.active = NO;
  [_hiveCollectionView setCollectionViewLayout:_hiveLayout
      animated:YES
      completion:^(BOOL finished) {
        // Wait to make the cell active so the animations don't interfere.
        activeCell.active = YES;
      }];
}

- (void)didPanHexagon:(UIPanGestureRecognizer *)recognizer {
  if (_activeCellPath) {
    return;
  }
  if (recognizer.state == UIGestureRecognizerStateEnded) {
    [self panningDidEndWithRecognizer:recognizer];
    return;
  }
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    if (_panningCell) {
      // This can happen if the user it trying to drag multiple hexagons at the same time.
      recognizer.enabled = NO;
      recognizer.enabled = YES;
      return;
    }
    [self panningDidBeginWithRecognizer:recognizer];
  }
  _panningCell.center = [recognizer locationInView:recognizer.view.superview];
}

- (void)panningDidBeginWithRecognizer:(UIPanGestureRecognizer *)recognizer {
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
  CGSize size = [_panningCell sizeThatFits:CGSizeZero];
  _panningCell.frame = CGRectMake(0, 0, size.width * 1.5, size.height * 1.5);
  [_hiveCollectionView addSubview:_panningCell];
}

- (void)panningDidEndWithRecognizer:(UIPanGestureRecognizer *)recognizer {
  CGPoint location = [recognizer locationInView:recognizer.view.superview];
  CGPoint hexCoords = [_hiveLayout nearestHexCoordsFromScreenCoords:location];
  CGSize hexagonSize = [_panningCell sizeThatFits:CGSizeZero];
  BBHexagon *hexagon;
  CGRect hexagonFrame = [_hiveLayout frameForHexagonAtHexCoords:hexCoords];
  BOOL offscreen = !CGRectContainsRect(_hiveCollectionView.bounds, hexagonFrame);
  if ([self hexagonAtHexCoords:hexCoords] != nil || offscreen) {
    if (_panningCellIsNew) {
      // Animate the cell back to the center to communicate that it couldn't be created.
      [UIView animateWithDuration:0.15
          animations:^{
            _panningCell.frame =
                CGRectMake(_hiveCollectionView.bounds.size.width / 2 - hexagonSize.width / 2,
                           _hiveCollectionView.bounds.size.height / 2 - hexagonSize.height / 2,
                           hexagonSize.width,
                           hexagonSize.height);
            _panningCell.alpha = 0.4;
          }
          completion:^(BOOL finished) {
            [_panningCell removeFromSuperview];
            _panningCell = nil;
          }];
      return;
    }
    hexagon = _panningCell.hexagon;
  } else {
    hexagon = [BBHexagon hexagonfromHexagon:_panningCell.hexagon withHexCoords:hexCoords];
  }
  [_panningCell removeFromSuperview];
  _panningCell = nil;
  [_sections[0] addObject:hexagon];
  NSIndexPath *activeIndexPath =
      [NSIndexPath indexPathForItem:[_sections[0] count] - 1 inSection:0];
  // Wrap this in an animation block with 0 duration to disable the shitty fade-in animation.
  [UIView animateWithDuration:0
      animations:^{
        [_hiveCollectionView insertItemsAtIndexPaths:@[ activeIndexPath ]];
      }];
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
