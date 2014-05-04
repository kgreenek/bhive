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
                                   BBHiveLayoutDelegate,
                                   BBHiveCellDelegate>
@end

@implementation BBHiveViewController {
  NSMutableArray *_sections;
  UICollectionView *_hiveCollectionView;
  UITapGestureRecognizer *_backgroundTapRecognizer;
  NSIndexPath *_activeCellPath;
  BBHiveCell *_panningCell;
  BOOL _panningCellIsNew;
  BBHiveLayout *_hiveLayout;
}

- (void)dealloc {
  [_backgroundTapRecognizer removeTarget:self action:@selector(didTapBackground)];
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
  _hiveCollectionView.backgroundView.userInteractionEnabled = YES;
  _backgroundTapRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(didTapBackground)];
  [_hiveCollectionView.backgroundView addGestureRecognizer:_backgroundTapRecognizer];
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
  [cell addDidPanTarget:self action:@selector(didPanHexagon:)];
  [cell addDidLongPressTarget:self action:@selector(didLongPressHexagon:)];
  cell.delegate = self;
  [cell sizeToFit];
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (_panningCell) {
    // This happens if the user is panning with one finger, and taps on a different
    // cell with another finger.
    return;
  }
  if ([_activeCellPath isEqual:indexPath] || indexPath.item == 0) {
    [self didTapBackground];
  } else if (indexPath.item != 0) {
    [self setActiveCellPath:indexPath];
  }
}

#pragma mark BBHiveCollectionViewLayoutDelegate

- (CGPoint)hexCoordinatesForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self hexagonForIndexPath:indexPath].hexCoords;
}

#pragma mark BBHiveCellDelegate

- (void)didFinishEditingCell:(BBHiveCell *)cell {
  NSUInteger index = [_sections[0] indexOfObject:cell.hexagon];
  BBHexagon *hexagon = [BBHexagon hexagonfromHexagon:cell.hexagon
                                            withText:cell.editBoxText];
  _sections[0][index] = hexagon;
  cell.hexagon = hexagon;
}

#pragma mark Private Methods

- (BBHexagon *)hexagonForIndexPath:(NSIndexPath *)indexPath {
  return _sections[indexPath.section][indexPath.item];
}

- (void)setActiveCellPath:(NSIndexPath *)activeCellPath {
  if ([_activeCellPath isEqual:activeCellPath] || (!_activeCellPath && !activeCellPath)) {
    return;
  }
  BBHiveCell *previousActiveCell =
      (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCellPath];
  previousActiveCell.editing = NO;
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

- (void)didTapBackground {
  BBHiveCell *activeCell =
      (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:_activeCellPath];
  if (activeCell.editing) {
    activeCell.editing = NO;
  } else {
    [self setActiveCellPath:nil];
  }
}

- (void)didLongPressHexagon:(UILongPressGestureRecognizer *)recognizer {
  BBHiveCell *cell = (BBHiveCell *)recognizer.view;
  NSUInteger item = [_sections[0] indexOfObject:cell.hexagon];
  if (item == _activeCellPath.item) {
    cell.editing = YES;
  }
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
  [self centerHiveCell].trashHidden = NO;
}

- (void)panningDidEndWithRecognizer:(UIPanGestureRecognizer *)recognizer {
  CGPoint location = [recognizer locationInView:recognizer.view.superview];
  CGPoint hexCoords = [_hiveLayout nearestHexCoordsFromScreenCoords:location];
  CGSize hexagonSize = [_panningCell sizeThatFits:CGSizeZero];
  BBHexagon *hexagon;
  CGRect hexagonFrame = [_hiveLayout frameForHexagonAtHexCoords:hexCoords];
  BOOL offscreen = !CGRectContainsRect(_hiveCollectionView.bounds, hexagonFrame);
  BBHexagon *overlappingHexagon = [self hexagonAtHexCoords:hexCoords];
  if (overlappingHexagon != nil || offscreen) {
    if (_panningCellIsNew || overlappingHexagon.type == kBBHexagonTypeCenter) {
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
            [self centerHiveCell].trashHidden = YES;
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
  NSIndexPath *indexPath =
      [NSIndexPath indexPathForItem:[_sections[0] count] - 1 inSection:0];
  // Wrap this in an animation block with 0 duration to disable the shitty fade-in animation.
  [UIView animateWithDuration:0
      animations:^{
        [_hiveCollectionView insertItemsAtIndexPaths:@[ indexPath ]];
      }];
  [self centerHiveCell].trashHidden = YES;
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

- (BBHiveCell *)centerHiveCell {
  return (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:
      [NSIndexPath indexPathForItem:0 inSection:0]];
}

@end
