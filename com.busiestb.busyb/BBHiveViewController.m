//
//  BBHiveViewController.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBHiveViewController.h"

#import <CoreData/CoreData.h>

#import "BBHexagon.h"
#import "BBHexagonEntity.h"
#import "BBHiveCell.h"
#import "BBHiveLayout.h"

static NSString * const kHiveCellIdentifier = @"HiveCell";
static NSString * const kHexagonEntityName = @"Hexagon";

@interface BBHiveViewController ()<UICollectionViewDataSource,
                                   UICollectionViewDelegate,
                                   BBHiveLayoutDelegate,
                                   BBHiveCellDelegate>
@end

@implementation BBHiveViewController {
  NSMutableArray *_hexagons;
  UICollectionView *_hiveCollectionView;
  UITapGestureRecognizer *_backgroundTapRecognizer;
  NSIndexPath *_activeCellPath;
  BBHiveCell *_panningCell;
  BOOL _panningCellIsNew;
  BBHiveLayout *_hiveLayout;
  NSManagedObjectContext *_managedObjectContext;
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
  [self setupManagedObjectContext];
  [self setupHexagons];
  [_hiveCollectionView reloadData];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [_hexagons count];
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
  cell.hexagon.text = cell.editBoxText;
  [cell update];
  [_managedObjectContext save:NULL];
}

#pragma mark Private Methods

- (BBHexagon *)hexagonForIndexPath:(NSIndexPath *)indexPath {
  return _hexagons[indexPath.item];
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
  NSUInteger item = [_hexagons indexOfObject:cell.hexagon];
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
    NSUInteger item = [_hexagons indexOfObject:hexagon];
    [_hexagons removeObject:hexagon];
    // Wrap this in an animation block with 0 duration to disable the shitty fade-out animation.
    [UIView animateWithDuration:0
        animations:^{
          [_hiveCollectionView deleteItemsAtIndexPaths:
              @[ [NSIndexPath indexPathForItem:item inSection:0] ]];
        }];
    _panningCell.hexagon = hexagon;
    _panningCellIsNew = NO;
  } else {
    _panningCell.hexagon = [self newCellHexagon];
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
      [_managedObjectContext deleteObject:_panningCell.hexagon.entity];
      [_managedObjectContext save:NULL];
      return;
    }
  } else {
    _panningCell.hexagon.hexCoords = hexCoords;
    [_managedObjectContext save:NULL];
  }
  [_hexagons addObject:_panningCell.hexagon];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[_hexagons count] - 1 inSection:0];
  // Wrap this in an animation block with 0 duration to disable the shitty fade-in animation.
  [UIView animateWithDuration:0
      animations:^{
        [_hiveCollectionView insertItemsAtIndexPaths:@[ indexPath ]];
      }];
  [_panningCell removeFromSuperview];
  _panningCell = nil;
  [self centerHiveCell].trashHidden = YES;
  if (_panningCellIsNew) {
    [self setActiveCellPath:indexPath];
  }
}

- (BBHexagon *)hexagonAtHexCoords:(CGPoint)hexCoords {
  // TODO: Optimize this. Blech.
  for (BBHexagon *hexagon in _hexagons) {
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

- (void)setupManagedObjectContext {
  NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
  NSURL *url = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                      inDomains:NSUserDomainMask][0];
  url = [url URLByAppendingPathComponent:@"hexagons.sqlite"];
  _managedObjectContext =
       [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  _managedObjectContext.persistentStoreCoordinator =
      [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
  NSError* error;
  [_managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                 configuration:nil
                                                                           URL:url
                                                                       options:nil
                                                                         error:&error];
  if (error) {
    NSLog(@"ERROR: Could not setup NSManagedObjectContext %@", error);
  }
}

- (void)setupHexagons {
  _hexagons = [NSMutableArray array];
  NSArray *hexagonEntities = [self allHexagons];
  if (![hexagonEntities count]) {
    [_hexagons addObject:[self newCenterHexagon]];
    [_managedObjectContext save:NULL];
  } else {
    for (BBHexagonEntity *entity in hexagonEntities) {
      [_hexagons addObject:[[BBHexagon alloc] initWithEntity:entity]];
    }
  }
}

- (NSArray *)allHexagons {
  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kHexagonEntityName];
  return [_managedObjectContext executeFetchRequest:request error:NULL];
}

- (BBHexagon *)newCenterHexagon {
  BBHexagonEntity *hexagonEntity =
      [NSEntityDescription insertNewObjectForEntityForName:kHexagonEntityName
                                    inManagedObjectContext:_managedObjectContext];
  return [BBHexagon centerHexagonWithEntity:hexagonEntity];
}

- (BBHexagon *)newCellHexagon {
  BBHexagonEntity *hexagonEntity =
      [NSEntityDescription insertNewObjectForEntityForName:kHexagonEntityName
                                    inManagedObjectContext:_managedObjectContext];
  return [BBHexagon cellHexagonWithEntity:hexagonEntity];
}

+ (BBHexagonColor)randomHexagonColor {
  return arc4random() % kBBHexagonColorNumColors;
}

@end
