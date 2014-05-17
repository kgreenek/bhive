//
//  UIView+ColorOfPoint.m
//  com.hexkvlt.bhive
//
//  Created by Kevin Greene on 5/13/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "UIView+ColorOfPoint.h"

#import <QuartzCore/QuartzCore.h>
#import "UIView+ColorOfPoint.h"

@implementation UIView (ColorOfPoint)

- (UIColor *)colorOfPoint:(CGPoint)point {
  unsigned char pixel[4] = {0};
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context =
      CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace,
                            kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
  CGContextTranslateCTM(context, -point.x, -point.y);
  [self.layer renderInContext:context];
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  UIColor *color = [UIColor colorWithRed:pixel[0] / 255
                                   green:pixel[1] / 255
                                    blue:pixel[2] / 255
                                   alpha:pixel[3] / 255];
  return color;
}

- (CGFloat)alphaOfPoint:(CGPoint)point {
  unsigned char pixel[4] = {0};
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context =
      CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace,
                            kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
  CGContextTranslateCTM(context, -point.x, -point.y);
  [self.layer renderInContext:context];
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  return pixel[3] / 255;
}

@end