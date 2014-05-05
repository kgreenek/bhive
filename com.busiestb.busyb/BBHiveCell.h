//
//  BBHiveCell.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BBHiveCell;

@protocol BBHiveCellDelegate<NSObject>

- (void)didFinishEditingCell:(BBHiveCell *)cell;

@end

@class BBHexagon;

@interface BBHiveCell : UICollectionViewCell

@property(nonatomic, weak) id<BBHiveCellDelegate> delegate;
@property(nonatomic, strong) BBHexagon *hexagon;
@property(nonatomic, assign, getter=isActive) BOOL active;
@property(nonatomic, assign, getter=isEditing) BOOL editing;
@property(nonatomic, readonly) NSString *editBoxText;
@property(nonatomic, assign, getter=isTrashHidden) BOOL trashHidden;

// Updates the view from hexagon. Call this whenever hexagon changes.
- (void)update;

- (void)addDidPanTarget:(id)target action:(SEL)action;
- (void)addDidLongPressTarget:(id)target action:(SEL)action;

- (void)removeDidPanTarget:(id)target action:(SEL)action;
- (void)removeDidLongPressTarget:(id)target action:(SEL)action;

@end
