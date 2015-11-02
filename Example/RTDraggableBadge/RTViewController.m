//
//  RTViewController.m
//  RTDraggableBadge
//
//  Created by rickytan on 11/01/2015.
//  Copyright (c) 2015 rickytan. All rights reserved.
//

@import RTDraggableBadge;

#import "RTViewController.h"

@interface RTViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet RTDraggableBadge *badge;

@end

@implementation RTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[RTDraggableBadge appearance] setBadgeColor:[UIColor blueColor]];

    [self.button rt_setBadge:@"new"
                  withHandle:^(RTDraggableBadge *badge, RTDragState state) {
                      if (state == RTDragStateDragged) {
                          badge.text = @"n";
                      }
                  }];

    self.badge.font = [UIFont systemFontOfSize:36];
    self.badge.breakLength = 120.f;
    [self.badge setDragStateHandle:^(RTDraggableBadge *badge, RTDragState state) {
        if (state == RTDragStateDragged) {
            badge.text = @"0";
        }
        if (state == RTDragStateStart) {
            /*
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                badge.dragEnabled = NO;
            });
             */
        }
        if (state == RTDragStateCanceled) {
            NSLog(@"Canceled");
        }
    }];

    [self.badge performSelector:@selector(setText:)
                     withObject:@"0"
                     afterDelay:2];

    __block NSInteger count = 12;
    [self.tabBarItem rt_setBadgeValue:[@(count) stringValue]
                           withHandle:^(RTDraggableBadge *badge, RTDragState state) {
                               if (state == RTDragStateDragged) {
                                   badge.text = [@(--count) stringValue];
                               }
                           }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self.badge sizeToFit];
    self.badge.center = self.view.center;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
