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
  UITapGestureRecognizer *_backgroundTapRecognizer;
}

- (void)loadView {
  BBHiveLayout *layout = [[BBHiveLayout alloc] initWithDelegate:self activeCell:nil];
  _hiveCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                           collectionViewLayout:layout];
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
  BBHexagon *centerHexagon = [BBHexagon centerHexagon];
  [cells addObject:centerHexagon];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(0, 1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(0, -1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(0, -2)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(1, 0)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(1, 1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-1, 0)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-1, -1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-1, 1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-2, 0)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-2, -1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-2, 1)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-3, 2)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-3, 3)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-3, 4)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(0, 2)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(1, 2)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(-1, 2)]];
  [cells addObject:[BBHexagon cellHexagonWithParent:centerHexagon hexCoords:CGPointMake(4, -4)]];
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
  [cell setHexagon:[self hexagonForIndexPath:indexPath]];
  [cell sizeToFit];
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([_activeCell isEqual:indexPath]) {
    [self setActiveCell:nil];
  } else {
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
  _activeCell = activeCell;
  BBHiveLayout *expandedLayout = [[BBHiveLayout alloc] initWithDelegate:self activeCell:activeCell];
  [_hiveCollectionView setCollectionViewLayout:expandedLayout animated:YES];
}

@end
