//
//  UITabBarItem+Badge.m
//  Pods
//
//  Created by ricky on 15/11/2.
//
//

#import "UITabBarItem+Badge.h"
#import "UIView+Badge.h"

@implementation UITabBarItem (Badge)

- (RTDraggableBadge *)rt_setBadgeValue:(NSString *)text
                            withHandle:(void (^)(RTDraggableBadge *, RTDragState))block
{
    UIView *view = [self valueForKeyPath:[NSString stringWithFormat:@"%@i%@", @"_v", @"ew"]];
    return [view rt_setBadge:text
                  withHandle:block];
}

@end
