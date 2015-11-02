//
//  RTDraggableBadge.h
//  Pods
//
//  Created by ricky on 15/11/1.
//
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface RTDraggableBadge : UIControl
@property (nonatomic, strong) IBInspectable UIColor* badgeColor UI_APPEARANCE_SELECTOR;    // default red
@property (nonatomic, strong) IBInspectable UIColor* textColor UI_APPEARANCE_SELECTOR;     // default white
@property (nonatomic, strong) IBInspectable NSString *text;
@property (nonatomic, strong) IBInspectable UIFont *font UI_APPEARANCE_SELECTOR;           // default system 10
@property (nonatomic, assign) IBInspectable CGFloat breakLength UI_APPEARANCE_SELECTOR;    // 0 < this <= 80, default 80
@end
