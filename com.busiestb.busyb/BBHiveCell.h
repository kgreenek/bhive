//
//  BBHiveCell.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BBHexagon;

@interface BBHiveCell : UICollectionViewCell

@property(nonatomic, strong) BBHexagon *hexagon;
@property(nonatomic, assign, getter=isActive) BOOL active;
@property(nonatomic, assign, getter=isEditing) BOOL editing;
@property(nonatomic, strong) NSString *text;

@end
