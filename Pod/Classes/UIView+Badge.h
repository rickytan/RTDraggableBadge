//
//  UIButton+Badge.h
//  Pods
//
//  Created by ricky on 15/11/2.
//
//

#import <UIKit/UIKit.h>
#import "RTDraggableBadge.h"

@interface UIView (Badge)
- (RTDraggableBadge *)rt_setBadge:(NSString *)text
                       withHandle:(void(^)(RTDraggableBadge *badge, RTDragState state))block;
@end
