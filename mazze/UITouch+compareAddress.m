//
//  UITouch+compareAddress.m
//  mazze
//
//  Created by Jarod Luebbert on 10/24/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "UITouch+compareAddress.h"

@implementation UITouch (compareAddress)
- (NSComparisonResult)compareAddress:(id)obj
{
    if ((__bridge void *)self < (__bridge void *)obj) return NSOrderedAscending;
    else if ((__bridge void *)self == (__bridge void *)obj) return NSOrderedSame;
    else return NSOrderedDescending;
}
@end
