//
//  UIButton+Badge.m
//  Pods
//
//  Created by ricky on 15/11/2.
//
//

#import "UIView+Badge.h"

@implementation UIView (Badge)

- (RTDraggableBadge *)rt_setBadge:(NSString *)text
                       withHandle:(void (^)(RTDraggableBadge *badge, RTDragState))block
{
    RTDraggableBadge *badge = (RTDraggableBadge *)[self viewWithTag:2333];
    if (!badge) {
        badge = [RTDraggableBadge badgeWithDragHandle:block];
        badge.text = text;
        [badge sizeToFit];

        CGRect rect = badge.frame;
        rect.origin.x = self.bounds.size.width - rect.size.width;
        rect.origin.y = 0;
        badge.frame = rect;
        badge.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        badge.tag = 2333;
        [self addSubview:badge];
    }
    else {
        badge.text = text;
        badge.dragStateHandle = block;
    }
    return badge;
}

@end
