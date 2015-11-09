//
//  RTDraggableBadge.m
//  Pods
//
//  Created by ricky on 15/11/1.
//
//

#import "RTDraggableBadge.h"


typedef struct {
    CGFloat a, b, c;    // a * x + b * y + c = 0
} RTLine;

FOUNDATION_EXPORT inline RTLine RTLineMakeWithTwoPoints(CGPoint p0, CGPoint p1)
{
    return (RTLine){p0.y - p1.y, p1.x - p0.x, p0.x * p1.y - p0.y * p1.x};
}

FOUNDATION_EXPORT inline RTLine RTLineMakeWithPointAndSlope(CGPoint p, CGFloat slope)
{
    if (isnan(slope))
        return (RTLine){1, 0, -p.x};
    return (RTLine){slope, -1, p.y - slope * p.x};
}

FOUNDATION_EXPORT inline CGFloat RTLineTestPoint(RTLine line, CGPoint point)
{
    return line.a * point.x + line.b * point.y + line.c;
}

FOUNDATION_EXPORT inline CGFloat RTLinePointDistance(RTLine line, CGPoint point)
{
    return fabs(line.a * point.x + line.b * point.y + line.c) / sqrt(line.a * line.a + line.b * line.b);
}

FOUNDATION_EXPORT inline CGFloat RTSign(CGFloat value)
{
    if (value >= 0) return 1.f;
    return -1.f;
}

CGPoint RTSolveIntersectionPoint(RTLine l0, RTLine l1)
{
    CGFloat d = l0.a * l1.b - l0.b * l1.a;
    return (CGPoint){
        (l0.b * l1.c - l0.c * l1.b) / d,
        (l1.a * l0.c - l1.c * l0.a) / d
    };
}

static CGPoint CGPointInterpolate(const CGPoint p0, const CGPoint p1, const CGFloat ratio)
{
    return CGPointMake(p0.x * ratio + p1.x * (1 - ratio),
                       p0.y * ratio + p1.y * (1 - ratio));
}

static CGFloat CGPointDistance(const CGPoint p0, const CGPoint p1)
{
    CGFloat dx = p0.x - p1.x;
    CGFloat dy = p0.y - p1.y;
    return sqrt(dx * dx + dy * dy);
}

@interface RTDraggableBadge () <UIGestureRecognizerDelegate>
@property (nonatomic, strong  ) UIView       *containerView;
@property (nonatomic, weak    ) UIView       *originSuperView;
@property (nonatomic, assign  ) CGPoint       originPosition;
@property (nonatomic, strong  ) NSArray      *originContraints;
@property (nonatomic, strong) CAShapeLayer   *shapeLayer;
@property (nonatomic, strong) UILabel        *textLabel;
@property (nonatomic, assign, getter=isBreaking) BOOL breaking;
@property (nonatomic, assign) BOOL breaked;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@end

@implementation RTDraggableBadge

#pragma mark - Overrides

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size = [self.textLabel sizeThatFits:size];
    size = CGRectIntegral((CGRect){{0, 0}, size}).size;

    CGFloat padding = MIN(size.width, size.height) / 2;
    size.width += padding + self.contentInsets.left + self.contentInsets.right;
    size.height += self.contentInsets.top + self.contentInsets.bottom;
    size.width = MAX(size.height, size.width);
    return size;
}

- (CGSize)intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}

- (UIView *)viewForBaselineLayout
{
    return self.textLabel;
}

- (void)drawRect:(CGRect)rect
{
    [self.badgeColor setFill];
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:MIN(rect.size.width, rect.size.height) / 2] fill];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    self.containerView = newWindow;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    self.layer.cornerRadius = radius;

    CGRect contentRect = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
    CGPoint center = CGPointMake(CGRectGetMidX(contentRect),
                                 CGRectGetMidY(contentRect));
    [_textLabel sizeToFit];
    _textLabel.center = center;
    _shapeLayer.position = center;

}

- (BOOL)pointInside:(CGPoint)point
          withEvent:(UIEvent *)event
{
    CGRect bounds = self.bounds;
    CGRect rect = CGRectMake(bounds.origin.x - self.touchAreaOutsets.left, bounds.origin.y - self.touchAreaOutsets.top,
                             bounds.size.width + self.touchAreaOutsets.left + self.touchAreaOutsets.right, bounds.size.height + self.touchAreaOutsets.top + self.touchAreaOutsets.bottom);
    return CGRectContainsPoint(rect, point);
}

#pragma mark - Methods

+ (instancetype)badgeWithDragHandle:(void (^)(RTDraggableBadge *badge, RTDragState state))block
{
    RTDraggableBadge *badge = [[RTDraggableBadge alloc] init];
    badge.dragStateHandle = block;
    return badge;
}

- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
    self.contentMode = UIViewContentModeRedraw;
    self.contentInsets = UIEdgeInsetsMake(1.f, 1.25, 1.f, 1.25f);
    self.font = [RTDraggableBadge appearance].font ?: [UIFont systemFontOfSize:13.f];
    self.badgeColor = [RTDraggableBadge appearance].badgeColor ?: [UIColor colorWithRed:1
                                                                                  green:0.231
                                                                                   blue:0.188
                                                                                  alpha:1];
    self.textColor = [RTDraggableBadge appearance].textColor ?: [UIColor whiteColor];
    self.breakLength = [RTDraggableBadge appearance].breakLength ?: 64.f;
    [self bringSubviewToFront:self.textLabel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onPan:)];
    self.panGesture = pan;
    [self addGestureRecognizer:pan];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGFloat padding = MIN(bounds.size.width, bounds.size.height) / 4;
    return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, padding, 0, padding));
}

- (CAShapeLayer *)shapeLayer
{
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        [self.layer addSublayer:_shapeLayer];
    }
    return _shapeLayer;
}

- (void)setDragEnabled:(BOOL)dragEnabled
{
    self.panGesture.enabled = dragEnabled;
}

- (BOOL)dragEnabled
{
    return self.panGesture.enabled;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setFont:(UIFont *)font
{
    self.textLabel.font = font;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (UIFont *)font
{
    return self.textLabel.font;
}

- (void)setText:(NSString *)text
{
    self.hidden = !text.length;
    self.textLabel.text = text;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (NSString *)text
{
    return self.textLabel.text;
}

- (void)setTextColor:(UIColor *)textColor
{
    self.textLabel.textColor = textColor;
}

- (UIColor *)textColor
{
    return self.textLabel.textColor;
}

- (void)setBadgeColor:(UIColor *)badgeColor
{
    _badgeColor = badgeColor;
    self.shapeLayer.fillColor = _badgeColor.CGColor;
}

- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_textLabel];
    }
    return _textLabel;
}

/*
- (UIBezierPath *)calculatePathWithOriginCenter:(CGPoint)center
{
    const CGFloat dx = -center.x;
    const CGFloat dy = -center.y;
    const CGFloat distance = sqrt(dx * dx + dy * dy);
    const CGFloat controlRatio = distance / self.breakLength;
    const CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    const CGFloat s_radius = radius / 2;
    CGFloat ratio = s_radius / (radius + s_radius);

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat theta = atan2(dy, dx);
    CGPoint C0 = center;
    CGPoint Px = CGPointMake(C0.x + dx * ratio, C0.y + dy * ratio);
    CGFloat alpha = MAX(acos(s_radius / distance / ratio), M_PI_4);
    if (distance <= radius + s_radius) {

    }
    else {
        CGPoint P0 = CGPointMake(C0.x + s_radius * cos(theta + alpha),
                                 C0.y + s_radius * sin(theta + alpha));
        CGPoint P1 = CGPointMake(C0.x + s_radius * cos(theta - alpha),
                                 C0.y + s_radius * sin(theta - alpha));
        CGPoint P2 = CGPointMake(radius * cos(M_PI + (theta + alpha)),
                                 radius * sin(M_PI + (theta + alpha)));
        CGPoint P3 = CGPointMake(radius * cos(M_PI + theta - alpha),
                                 radius * sin(M_PI + theta - alpha));


        [path moveToPoint:P0];
        [path addArcWithCenter:C0
                        radius:s_radius
                    startAngle:theta + alpha
                      endAngle:theta - alpha
                     clockwise:YES];
        [path addQuadCurveToPoint:P2
                     controlPoint:Px];
        [path addArcWithCenter:CGPointZero
                        radius:radius
                    startAngle:M_PI + (theta + alpha)
                      endAngle:M_PI + theta - alpha
                     clockwise:YES];
        [path addQuadCurveToPoint:P0
                     controlPoint:Px];
        [path closePath];

    }
    return path;
}
 */

- (UIBezierPath *)calculatePathWithOriginCenter2:(CGPoint)center
{
    const CGFloat dx = -center.x;
    const CGFloat dy = -center.y;
    const CGFloat distance = sqrt(dx * dx + dy * dy);
    const CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;

    if (radius == 0)
        return nil;

    const CGFloat s_radius = radius / 2;
    const CGPoint sourceCenter = CGPointMake(radius * center.x / (radius - s_radius),
                                             radius * center.y / (radius - s_radius));
    const RTLine centerLine = RTLineMakeWithTwoPoints(center, CGPointZero);
    CGFloat ratio = s_radius / (radius + s_radius);

    CGFloat theta = atan2(dy, dx);
    CGPoint C0 = center;
    CGPoint Px = CGPointMake(C0.x + dx * ratio, C0.y + dy * ratio);
    CGFloat alpha = M_PI - acos(radius / sqrt(sourceCenter.x * sourceCenter.x + sourceCenter.y * sourceCenter.y));

    UIBezierPath *path = [UIBezierPath bezierPath];
    if (distance <= radius - s_radius) {
        [path moveToPoint:CGPointMake(radius * cos(theta), radius * sin(theta))];
        [path addArcWithCenter:CGPointZero
                        radius:radius
                    startAngle:theta
                      endAngle:2 * M_PI + theta
                     clockwise:YES];
        [path closePath];
    }
    else if (distance <= radius + s_radius) {

        CGPoint P0 = CGPointMake(C0.x + s_radius * cos(theta + alpha),
                                 C0.y + s_radius * sin(theta + alpha));
        CGPoint P2 = CGPointMake(radius * cos(theta - alpha),
                                 radius * sin(theta - alpha));

        [path moveToPoint:P0];
        [path addArcWithCenter:C0
                        radius:s_radius
                    startAngle:theta + alpha
                      endAngle:theta - alpha
                     clockwise:YES];
        [path addLineToPoint:P2];
        [path addArcWithCenter:CGPointZero
                        radius:radius
                    startAngle:theta - alpha
                      endAngle:theta + alpha
                     clockwise:YES];
        [path addLineToPoint:P0];
        [path closePath];
    }
    else {
        const CGFloat s_delta = (distance - radius - s_radius) / (self.breakLength) * alpha * 0.8;
        const CGFloat delta = s_delta / 2;

        CGPoint P0 = CGPointMake(C0.x + s_radius * cos(theta + alpha - s_delta),
                                 C0.y + s_radius * sin(theta + alpha - s_delta));
        RTLine L0 = RTLineMakeWithPointAndSlope(P0, tan(theta + alpha - s_delta + M_PI_2));

        CGPoint P1 = CGPointMake(C0.x + s_radius * cos(theta - alpha + s_delta),
                                 C0.y + s_radius * sin(theta - alpha + s_delta));
        RTLine L1 = RTLineMakeWithPointAndSlope(P1, tan(theta - alpha + s_delta + M_PI_2));

        CGPoint P2 = CGPointMake(radius * cos(theta - alpha - delta),
                                 radius * sin(theta - alpha - delta));
        RTLine L2 = RTLineMakeWithPointAndSlope(P2, tan(theta - alpha - delta + M_PI_2));

        CGPoint P3 = CGPointMake(radius * cos(theta + alpha + delta),
                                 radius * sin(theta + alpha + delta));
        RTLine L3 = RTLineMakeWithPointAndSlope(P3, tan(theta + alpha + delta + M_PI_2));


        RTLine Lx = RTLineMakeWithPointAndSlope(Px, tan(theta + M_PI_2));

        // move to P0
        [path moveToPoint:P0];

        // arc to P1
        [path addArcWithCenter:C0
                        radius:s_radius
                    startAngle:theta + alpha - s_delta
                      endAngle:theta - alpha + s_delta
                     clockwise:YES];

        CGPoint control1 = RTSolveIntersectionPoint(Lx, L1);
        CGPoint control1_ = RTSolveIntersectionPoint(centerLine, L1);
        if (CGPointDistance(P1, control1) > CGPointDistance(P1, control1_)) {
            control1 = control1_;
        }
        CGPoint control2 = RTSolveIntersectionPoint(Lx, L2);
        CGPoint control2_ = RTSolveIntersectionPoint(centerLine, L2);
        if (CGPointDistance(P2, control2) > CGPointDistance(P2, control2_)) {
            control2 = control2_;
        }

        // curve to P2
        [path addCurveToPoint:P2
                controlPoint1:control1
                controlPoint2:control2];

        // arc to P3
        [path addArcWithCenter:CGPointZero
                        radius:radius
                    startAngle:theta - alpha - delta
                      endAngle:theta + alpha + delta
                     clockwise:YES];

        CGPoint control3 = RTSolveIntersectionPoint(Lx, L3);
        CGPoint control3_ = RTSolveIntersectionPoint(centerLine, L3);
        if (CGPointDistance(P3, control3) > CGPointDistance(P3, control3_)) {
            control3 = control3_;
        }
        CGPoint control0 = RTSolveIntersectionPoint(Lx, L0);
        CGPoint control0_ = RTSolveIntersectionPoint(centerLine, L0);
        if (CGPointDistance(P0, control0) > CGPointDistance(P0, control0_)) {
            control0 = control0_;
        }

        [path addCurveToPoint:P0
                controlPoint1:control3
                controlPoint2:control0];
        [path closePath];
    }

    return path;
}

- (void)updateShape
{
    CGFloat dx = self.transform.tx;
    CGFloat dy = self.transform.ty;
    const CGFloat distance = sqrt(dx * dx + dy * dy);
    if (distance < self.breakLength) {
        self.shapeLayer.path = [self calculatePathWithOriginCenter2:CGPointMake(-dx, -dy)].CGPath;
        self.breaked = NO;
    }
    else {
        if (self.breaked)
            return;
        if (self.isBreaking)
            return;
        self.shapeLayer.path = nil;

        CAKeyframeAnimation *animate = [CAKeyframeAnimation animationWithKeyPath:@"path"];
        CGPoint point = CGPointMake(-dx, -dy);

        const NSInteger valueCount = 31;
        NSMutableArray *values = [NSMutableArray arrayWithCapacity:valueCount + 1];
        for (NSInteger i = valueCount; i >= 0; --i) {
            CGPoint p = CGPointInterpolate(point, CGPointZero, 1.f * i / valueCount);
            UIBezierPath *path = [self calculatePathWithOriginCenter2:p];
            [values addObject:(__bridge id)path.CGPath];
        }
        animate.values = values;
        animate.calculationMode = kCAAnimationDiscrete;
        animate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animate.duration = 0.12f;
        animate.delegate = self;
        [self.shapeLayer addAnimation:animate
                               forKey:@"Breaking"];
    }
}

- (void)onPan:(UIPanGestureRecognizer *)pan
{
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.originSuperView = self.superview;
            self.originPosition = self.center;
            self.originContraints = self.superview.constraints;
            self.translatesAutoresizingMaskIntoConstraints = YES;
            CGPoint newCenter = [self.superview convertPoint:self.center
                                                      toView:self.containerView];
            [self.containerView addSubview:self];
            self.center = newCenter;

            if (self.dragStateHandle) {
                self.dragStateHandle(self, RTDragStateStart);
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [pan translationInView:self.containerView];
            self.transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
            [self updateShape];
            if (self.dragStateHandle) {
                self.dragStateHandle(self, RTDragStateDragging);
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [UIView animateWithDuration:0.35
                                  delay:0
                 usingSpringWithDamping:.4f
                  initialSpringVelocity:10.f
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.transform = CGAffineTransformIdentity;
                                 self.shapeLayer.path = NULL;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     [self.originSuperView addSubview:self];
                                     self.center = self.originPosition;
                                     self.breaked = NO;
                                     [self.originSuperView addConstraints:self.originContraints];
                                 }
                             }];

            if (pan.state == UIGestureRecognizerStateEnded) {
                if (self.breaked && self.dragStateHandle) {
                    self.dragStateHandle(self, RTDragStateDragged);
                }
            }
            else if (self.dragStateHandle) {
                self.dragStateHandle(self, RTDragStateCanceled);
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - CAAnimation Delegate

- (void)animationDidStart:(CAAnimation *)anim
{
    self.breaking = YES;
}

- (void)animationDidStop:(CAAnimation *)anim
                finished:(BOOL)flag
{
    self.breaking = !flag;
    self.breaked = flag;
}

@end
