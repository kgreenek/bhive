//
//  BBHiveLayout.h
//  com.hexkvlt.bhive
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BBHiveLayoutDelegate<NSObject>

- (CGPoint)hexCoordinatesForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface BBHiveLayout : UICollectionViewLayout

@property(nonatomic, weak) id<BBHiveLayoutDelegate> delegate;

- (instancetype)initWithDelegate:(id<BBHiveLayoutDelegate>)delegate
                  activeCellPath:(NSIndexPath *)activeCellIndexPath
                    keyboardSize:(CGSize)keyboardSize;

- (CGPoint)nearestHexCoordsFromScreenCoords:(CGPoint)screenCoords;
- (CGRect)frameForHexagonAtHexCoords:(CGPoint)hexCoords;

@end
