//
//  RTDraggableBadge.h
//  Pods
//
//  Created by ricky on 15/11/1.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RTDragState) {
    RTDragStateStart     = 0,
    RTDragStateDragging,
    RTDragStateDragged,
    RTDragStateCanceled
};

IB_DESIGNABLE
@interface RTDraggableBadge : UIView
@property (nonatomic, strong) IBInspectable UIColor* badgeColor;     // default red
@property (nonatomic, strong) IBInspectable UIColor* textColor;      // default white
@property (nonatomic, strong) IBInspectable NSString *text;
@property (nonatomic, strong) UIFont *font;            // default system 13
@property (nonatomic, assign) IBInspectable CGFloat breakLength;     // default 64
@property (nonatomic, assign) IBInspectable UIEdgeInsets contentInsets;

@property (nonatomic, assign) UIEdgeInsets touchAreaOutsets;        // default 0 0 0 0
@property (nonatomic, assign) BOOL dragEnabled;                                             // default YES
@property (nonatomic, copy) void(^dragStateHandle)(RTDraggableBadge *badge, RTDragState state);

+ (instancetype)badgeWithDragHandle:(void(^)(RTDraggableBadge *badge, RTDragState state))block;

@end
