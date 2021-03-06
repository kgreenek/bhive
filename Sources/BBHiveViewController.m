//
//  BBHiveViewController.m
//  com.hexkvlt.bhive
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
  CGSize _keyboardSize;
  UIPanGestureRecognizer *_activePanGestureRecognizer;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _keyboardSize = CGSizeZero;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    _backgroundTapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(didTapBackground)];
  }
  return self;
}

- (void)dealloc {
  [_backgroundTapRecognizer removeTarget:self action:@selector(didTapBackground)];
}

- (void)loadView {
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self
                                        activeCellPath:nil
                                          keyboardSize:_keyboardSize];
  _hiveCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                           collectionViewLayout:_hiveLayout];
  _hiveCollectionView.scrollEnabled = NO;
  _hiveCollectionView.dataSource = self;
  _hiveCollectionView.delegate = self;
  [_hiveCollectionView registerClass:
      [BBHiveCell class] forCellWithReuseIdentifier:kHiveCellIdentifier];
  _hiveCollectionView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self updateBackgroundImageWithOrientation:
      [[UIApplication sharedApplication] statusBarOrientation]];
  self.view = _hiveCollectionView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupManagedObjectContext];
  [self setupHexagons];
  [_hiveCollectionView reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  [self updateBackgroundImageWithOrientation:toInterfaceOrientation];
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
  if (indexPath.item == 0) {
    [self didTapBackground];
  } else if ([_activeCellPath isEqual:indexPath]) {
    BBHiveCell *cell = (BBHiveCell *)[_hiveCollectionView cellForItemAtIndexPath:indexPath];
    cell.editing = !cell.editing;
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
  previousActiveCell.active = NO;
  _activeCellPath = activeCellPath;
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self
                                        activeCellPath:activeCellPath
                                          keyboardSize:_keyboardSize];
  __weak BBHiveViewController *weakSelf = self;
  [_hiveCollectionView setCollectionViewLayout:_hiveLayout
      animated:YES
      completion:^(BOOL finished) {
        if (finished) {
          // Wait to make the cell active so the animations don't interfere.
          BBHiveViewController *strongSelf = weakSelf;
          if (strongSelf && strongSelf->_activeCellPath) {
            BBHiveCell *activeCell = (BBHiveCell *)[strongSelf->_hiveCollectionView
                cellForItemAtIndexPath:strongSelf->_activeCellPath];
            activeCell.active = YES;
          }
        }
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

- (void)didPanHexagon:(UIPanGestureRecognizer *)recognizer {
  if (_activeCellPath) {
    return;
  }
  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      [self panningDidBeginWithRecognizer:recognizer];
      // Fall through.
    case UIGestureRecognizerStateChanged:
      _panningCell.center = [recognizer locationInView:recognizer.view.superview];
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      [self panningDidEndWithRecognizer:recognizer];
      break;
    case UIGestureRecognizerStatePossible:
    case UIGestureRecognizerStateFailed:
      break;
  }
}

- (void)panningDidBeginWithRecognizer:(UIPanGestureRecognizer *)recognizer {
  if (_activePanGestureRecognizer) {
    // This can happen if the user it trying to drag multiple hexagons at the same time.
    UIPanGestureRecognizer *oldActiveRecognizer = _activePanGestureRecognizer;
    _activePanGestureRecognizer = recognizer;
    oldActiveRecognizer.enabled = NO;
    oldActiveRecognizer.enabled = YES;
    return;
  } else if (_panningCell) {
    NSLog(@"WARN: Panning cell is non-nil");
    return;
  }
  _activePanGestureRecognizer = recognizer;
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
  if (recognizer != _activePanGestureRecognizer) {
    // This can happen when the user tried to pan multiple hexagons simultaneously using multiple
    // fingers.
    return;
  }
  _activePanGestureRecognizer = nil;
  if (!_panningCell) {
    NSLog(@"WARN: Panning cell is already nil");
    return;
  }
  CGPoint location = [recognizer locationInView:recognizer.view.superview];
  CGPoint hexCoords = [_hiveLayout nearestHexCoordsFromScreenCoords:location];
  CGSize hexagonSize = [_panningCell sizeThatFits:CGSizeZero];
  CGRect hexagonFrame = [_hiveLayout frameForHexagonAtHexCoords:hexCoords];
  BOOL offscreen = !CGRectContainsRect(_hiveCollectionView.bounds, hexagonFrame);
  BBHexagon *overlappingHexagon = [self hexagonAtHexCoords:hexCoords];
  if (overlappingHexagon != nil || offscreen) {
    if (_panningCellIsNew || overlappingHexagon.type == kBBHexagonTypeCenter) {
      BBHiveCell *panningCell = _panningCell;
      _panningCell = nil;
      // Animate the cell back to the center to communicate that it couldn't be created.
      [UIView animateWithDuration:0.15
          animations:^{
            panningCell.frame =
                CGRectMake(_hiveCollectionView.bounds.size.width / 2 - hexagonSize.width / 2,
                           _hiveCollectionView.bounds.size.height / 2 - hexagonSize.height / 2,
                           hexagonSize.width,
                           hexagonSize.height);
            panningCell.alpha = 0.4;
          }
          completion:^(BOOL finished) {
            [panningCell removeFromSuperview];
            [self centerHiveCell].trashHidden = _activePanGestureRecognizer == nil;
          }];
      [_managedObjectContext deleteObject:panningCell.hexagon.entity];
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
  NSManagedObjectModel *model =
      [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
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

- (void)keyboardWillShow:(NSNotification *)notification {
  // The notification gives us the frame w.r.t. the window. However, the window is always in
  // portrait and contains transforms. We must convert it w.r.t. the view's frame or the height
  // and width will be swapped when in landscape.
  CGRect keyboardFrameInWindow =
      [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
  CGRect keyboardFrame = [_hiveCollectionView convertRect:keyboardFrameInWindow
                                                 fromView:_hiveCollectionView.window];
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self
                                        activeCellPath:_activeCellPath
                                          keyboardSize:keyboardFrame.size];
  [_hiveCollectionView setCollectionViewLayout:_hiveLayout animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  _hiveLayout = [[BBHiveLayout alloc] initWithDelegate:self
                                        activeCellPath:_activeCellPath
                                          keyboardSize:CGSizeZero];
  [_hiveCollectionView setCollectionViewLayout:_hiveLayout animated:YES];
}

- (void)setBackgoundView:(UIView *)backgroundView {
  [_hiveCollectionView.backgroundView removeFromSuperview];
  [_hiveCollectionView.backgroundView removeGestureRecognizer:_backgroundTapRecognizer];
  _hiveCollectionView.backgroundView = backgroundView;
  _hiveCollectionView.backgroundView.userInteractionEnabled = YES;
  [_hiveCollectionView.backgroundView addGestureRecognizer:_backgroundTapRecognizer];
}

- (void)updateBackgroundImageWithOrientation:(UIInterfaceOrientation)orientation {
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    [self setBackgoundView:
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hex-bg-landscape"]]];
  } else {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    if (width == 375) {
      // For the iPhone 6, there is no standard way to support the right screen size (the @3x asset
      // gets stretched for the iPhone 6). So we have to hard-code a specific value just for the 6.
      // All other screen sizes work with the regular hex-bg image set.
      [self setBackgoundView:
          [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hex-bg-375w"]]];
    } else {
      [self setBackgoundView:
          [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hex-bg"]]];
    }
  }
}

+ (BBHexagonColor)randomHexagonColor {
  return arc4random() % kBBHexagonColorNumColors;
}

@end
