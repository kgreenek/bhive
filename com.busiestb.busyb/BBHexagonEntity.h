//
//  BBHexagonEntity.h
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 5/4/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface BBHexagonEntity : NSManagedObject

@property(nonatomic, assign) NSNumber *hexCoordsX;
@property(nonatomic, assign) NSNumber *hexCoordsY;
@property(nonatomic, strong) NSNumber *type;
@property(nonatomic, strong) NSNumber *color;
@property(nonatomic, copy) NSString *text;

@end
