//
//  BBHiveLayout.h
//  com.busiestb.busyb
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
                      activeCell:(NSIndexPath *)activeCellIndexPath;

@end
