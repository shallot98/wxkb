/*
 * WXKBTweak - 微信输入法增强插件 v3.1
 * 功能：上下滑动切换中英文输入
 * 作者：老王（修复版 - 修复滑动误判和API级别触发）
 * 适配：rootless越狱 iOS 13.0+
 * 更新：
 *   - 修复点击被误判为滑动的问题
 *   - 改进垂直滑动检测算法（距离、角度、时间）
 *   - 添加WBKeyboardView hooks以更好地触发语言切换
 *   - 使用API级别的languageSelectClicked方法和触摸模拟
 */

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>

// ============================================
// 配置参数
// ============================================
static BOOL tweakEnabled = YES;
static CGFloat swipeThreshold = 50.0;
static BOOL hapticFeedbackEnabled = YES;
static BOOL visualFeedbackEnabled = YES;
static CGFloat swipeSensitivity = 1.0;

// Associated object keys
static const void *kWXKBSwipeGestureKey = &kWXKBSwipeGestureKey;
static const void *kWXKBFeedbackViewKey = &kWXKBFeedbackViewKey;
static const void *kWXKBInitializedKey = &kWXKBInitializedKey;
static const void *kWXKBObserverAttachedKey = &kWXKBObserverAttachedKey;

// ============================================
// 前向声明 - 微信输入法的真实类
// ============================================
@interface WBLanguageSwitchButton : UIButton
@end

@interface WBLanguageSwitchView : UIView
@end

@interface WBKeyFuncLangSwitch : NSObject
@end

@interface WBKeyboardView : UIView
@end

@interface WBMainInputView : UIView
@end

@interface WBKeyView : UIView
- (void)swipeUpBegan;
- (void)swipeUpEnded;
- (void)swipeDownBegan;
- (void)swipeDownEnded;
@end

// WBKeyboardView Category 声明
@interface WBKeyboardView (WXKBTweak)
- (void)wxkb_setupKeyboardGesture;
- (void)wxkb_handleKeyboardSwipe:(NSNotification *)notification;
- (void)wxkb_triggerLanguageSwitch;
- (void)wxkb_simulateTouchOnButton:(UIButton *)button;
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view;
@end

// WBMainInputView Category 声明
@interface WBMainInputView (WXKBTweak)
- (void)wxkb_findAndSaveLanguageButton;
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view;
@end

// 全局变量用于保存找到的按钮引用
static WBLanguageSwitchButton *globalLanguageSwitchButton = nil;
static NSLock *buttonLock = nil;

// ============================================
// 手势识别器
// ============================================
@interface WXKBSwipeGestureRecognizer : UIPanGestureRecognizer
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) BOOL hasTriggered;
@property (nonatomic, assign) BOOL isSwipeDetected;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, weak) UIInputView *attachedView;
@end

@implementation WXKBSwipeGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self.view];
    self.hasTriggered = NO;
    self.isSwipeDetected = NO;
    self.startTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"[WXKBTweak] 手势开始：起点=%.0f,%.0f", self.startPoint.x, self.startPoint.y);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    if (!tweakEnabled || self.hasTriggered) return;

    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];

    CGFloat verticalDistance = currentPoint.y - self.startPoint.y;
    CGFloat horizontalDistance = fabs(currentPoint.x - self.startPoint.x);
    CGFloat totalDistance = sqrt(pow(verticalDistance, 2) + pow(horizontalDistance, 2));

    // 防止误触：必须有一定的总移动距离才开始检测（避免轻微抖动）
    if (totalDistance < 15.0) return;

    // 标记为滑动手势（而不是点击）
    if (totalDistance > 20.0) {
        self.isSwipeDetected = YES;
    }

    // 确保是垂直滑动：垂直距离必须大于水平距离的2倍
    CGFloat absVerticalDistance = fabs(verticalDistance);
    if (absVerticalDistance < horizontalDistance * 2.0) return;
    
    // 水平距离不能太大（防止斜着滑）
    if (horizontalDistance > 50.0) return;

    CGFloat adjustedThreshold = swipeThreshold / swipeSensitivity;

    // 检测上滑或下滑
    if (absVerticalDistance > adjustedThreshold) {
        self.hasTriggered = YES;
        
        NSLog(@"[WXKBTweak] ✅ 手势检测成功！距离=%.2f，方向=%@",
              verticalDistance, verticalDistance < 0 ? @"上滑(English)" : @"下滑(Chinese)");

        // 发送通知触发切换
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WXKBSwitchLanguage"
                                                            object:nil
                                                          userInfo:@{@"direction": @(verticalDistance)}];

        // 震动反馈
        if (hapticFeedbackEnabled) {
            AudioServicesPlaySystemSound(1519);
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    // 计算时间和距离，进一步验证是否为点击
    NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - self.startTime;
    UITouch *touch = [touches anyObject];
    CGPoint endPoint = [touch locationInView:self.view];
    CGFloat totalDistance = sqrt(pow(endPoint.x - self.startPoint.x, 2) + pow(endPoint.y - self.startPoint.y, 2));
    
    // 如果时间很短(<0.2秒)且移动距离很小(<20像素)，判定为点击，不是滑动
    if (duration < 0.2 && totalDistance < 20.0) {
        self.isSwipeDetected = NO;
        NSLog(@"[WXKBTweak] 检测到点击事件（非滑动）：时长=%.3fs, 距离=%.1f", duration, totalDistance);
    }
}

- (void)reset {
    [super reset];
    self.hasTriggered = NO;
    self.isSwipeDetected = NO;
    NSLog(@"[WXKBTweak] 手势重置");
}

@end

// ============================================
// 视觉反馈视图
// ============================================
@interface WXKBFeedbackView : UIView
@property (nonatomic, strong) UILabel *label;
@end

@implementation WXKBFeedbackView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        self.layer.cornerRadius = 10.0;
        self.clipsToBounds = YES;
        self.alpha = 0.0;

        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont boldSystemFontOfSize:16.0];
        [self addSubview:self.label];
    }
    return self;
}

- (void)showWithText:(NSString *)text {
    self.label.text = text;

    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.alpha = 0.0;
            }];
        });
    }];
}

@end

// ============================================
// Hook WBLanguageSwitchButton
// ============================================
%hook WBLanguageSwitchButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        [buttonLock lock];
        globalLanguageSwitchButton = self;
        [buttonLock unlock];
        NSLog(@"[WXKBTweak] ✅ WBLanguageSwitchButton初始化: frame=%@", NSStringFromCGRect(frame));
    }
    return self;
}

- (instancetype)init {
    self = %orig;
    if (self) {
        [buttonLock lock];
        globalLanguageSwitchButton = self;
        [buttonLock unlock];
        NSLog(@"[WXKBTweak] ✅ WBLanguageSwitchButton init");
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [buttonLock lock];
        globalLanguageSwitchButton = self;
        [buttonLock unlock];
        NSLog(@"[WXKBTweak] ✅ 语言切换按钮已显示在window中");
    }
}

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents {
    NSLog(@"[WXKBTweak] 🔥 WBLanguageSwitchButton被点击: event=%lu", (unsigned long)controlEvents);
    %orig;
}

%new
+ (WBLanguageSwitchButton *)sharedButton {
    [buttonLock lock];
    WBLanguageSwitchButton *btn = globalLanguageSwitchButton;
    [buttonLock unlock];
    return btn;
}

%new
- (void)wxkb_performLanguageSwitchDirectly {
    NSLog(@"[WXKBTweak] 🔥 开始直接语言切换");
    if ([self respondsToSelector:@selector(languageSelectClicked)]) {
        NSLog(@"[WXKBTweak] ✅ 调用languageSelectClicked");
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:@selector(languageSelectClicked)];
        #pragma clang diagnostic pop
    } else {
        NSLog(@"[WXKBTweak] ⚠️ languageSelectClicked不存在，执行标准点击");
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

%end

// ============================================
// Hook WBLanguageSwitchView
// ============================================
%hook WBLanguageSwitchView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        NSLog(@"[WXKBTweak] ✅ WBLanguageSwitchView初始化: frame=%@", NSStringFromCGRect(frame));
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        NSLog(@"[WXKBTweak] ✅ WBLanguageSwitchView已显示在window中");
    }
}

%end

// ============================================
// Hook WBKeyFuncLangSwitch (可选的语言切换处理)
// ============================================
%hook WBKeyFuncLangSwitch

- (void)switchToFunc {
    NSLog(@"[WXKBTweak] 🔥 WBKeyFuncLangSwitch.switchToFunc被调用");
    %orig;
}

%end

// ============================================
// Hook WBKeyboardView - 微信键盘视图
// ============================================
%hook WBKeyboardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        NSLog(@"[WXKBTweak] ✅ WBKeyboardView初始化: frame=%@", NSStringFromCGRect(frame));
        
        // 为WBKeyboardView添加手势识别器（更精确的hook点）
        if (tweakEnabled) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self wxkb_setupKeyboardGesture];
            });
        }
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window && tweakEnabled) {
        NSLog(@"[WXKBTweak] ✅ WBKeyboardView已显示在window中");
        [self wxkb_setupKeyboardGesture];
    }
}

%new
- (void)wxkb_setupKeyboardGesture {
    // 检查是否已经添加过手势
    NSNumber *initialized = objc_getAssociatedObject(self, kWXKBInitializedKey);
    if (initialized && [initialized boolValue]) {
        NSLog(@"[WXKBTweak] WBKeyboardView已经添加过手势");
        return;
    }
    
    NSLog(@"[WXKBTweak] 为WBKeyboardView添加手势识别器");
    
    WXKBSwipeGestureRecognizer *swipeGesture = [[WXKBSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wxkb_handleKeyboardSwipe:)];
    swipeGesture.cancelsTouchesInView = NO;
    swipeGesture.delaysTouchesBegan = NO;
    
    [self addGestureRecognizer:swipeGesture];
    objc_setAssociatedObject(self, kWXKBSwipeGestureKey, swipeGesture, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, kWXKBInitializedKey, @YES, OBJC_ASSOCIATION_RETAIN);
    
    // 添加通知观察器
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wxkb_handleKeyboardSwipe:)
                                                 name:@"WXKBSwitchLanguage"
                                               object:nil];
    
    NSLog(@"[WXKBTweak] ✅ WBKeyboardView手势识别器已添加");
}

%new
- (void)wxkb_handleKeyboardSwipe:(NSNotification *)notification {
    NSLog(@"[WXKBTweak] 🎯 WBKeyboardView收到滑动通知");
    
    // 直接调用语言切换
    [self wxkb_triggerLanguageSwitch];
}

%new
- (void)wxkb_triggerLanguageSwitch {
    NSLog(@"[WXKBTweak] 🔥 WBKeyboardView触发语言切换");
    
    // 方法1：查找WBLanguageSwitchButton
    [buttonLock lock];
    WBLanguageSwitchButton *button = globalLanguageSwitchButton;
    [buttonLock unlock];
    
    if (button && button.window) {
        NSLog(@"[WXKBTweak] ✅ 使用全局按钮实例");
        
        // 优先调用languageSelectClicked方法
        if ([button respondsToSelector:@selector(languageSelectClicked)]) {
            NSLog(@"[WXKBTweak] ✅ 调用languageSelectClicked");
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [button performSelector:@selector(languageSelectClicked)];
            #pragma clang diagnostic pop
            return;
        }
        
        // 备用方案：模拟真实的触摸事件
        NSLog(@"[WXKBTweak] ⚠️ 使用模拟触摸事件");
        [self wxkb_simulateTouchOnButton:button];
        return;
    }
    
    // 方法2：在当前视图中查找按钮
    NSLog(@"[WXKBTweak] 🔍 在WBKeyboardView中查找语言切换按钮");
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        WBLanguageSwitchButton *foundButton = [self wxkb_findViewOfClass:WBLanguageSwitchButtonClass inView:self];
        if (foundButton) {
            NSLog(@"[WXKBTweak] ✅ 找到按钮！");
            
            // 保存到全局变量
            [buttonLock lock];
            globalLanguageSwitchButton = foundButton;
            [buttonLock unlock];
            
            // 调用切换方法
            if ([foundButton respondsToSelector:@selector(languageSelectClicked)]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [foundButton performSelector:@selector(languageSelectClicked)];
                #pragma clang diagnostic pop
            } else {
                [self wxkb_simulateTouchOnButton:foundButton];
            }
            return;
        }
    }
    
    NSLog(@"[WXKBTweak] ⚠️ 在WBKeyboardView中未找到语言切换按钮");
}

%new
- (void)wxkb_simulateTouchOnButton:(UIButton *)button {
    NSLog(@"[WXKBTweak] 模拟触摸事件在按钮上");
    
    // 方法1: 使用UIControl的方法发送所有触摸事件
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
    
    // 方法2: 如果方法1不工作，尝试直接操作
    if ([button respondsToSelector:@selector(setHighlighted:)]) {
        [button setHighlighted:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [button setHighlighted:NO];
        });
    }
}

%new
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view {
    if ([view isKindOfClass:targetClass]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        id found = [self wxkb_findViewOfClass:targetClass inView:subview];
        if (found) return found;
    }
    
    return nil;
}

- (void)dealloc {
    NSNumber *initialized = objc_getAssociatedObject(self, kWXKBInitializedKey);
    if (initialized && [initialized boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"[WXKBTweak] WBKeyboardView通知观察器已移除");
    }
    %orig;
}

%end

// ============================================
// Hook WBMainInputView - 微信主输入视图
// ============================================
%hook WBMainInputView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        NSLog(@"[WXKBTweak] ✅ WBMainInputView初始化: frame=%@", NSStringFromCGRect(frame));
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        NSLog(@"[WXKBTweak] ✅ WBMainInputView已显示在window中");
        
        // 查找并保存语言切换按钮
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self wxkb_findAndSaveLanguageButton];
        });
    }
}

%new
- (void)wxkb_findAndSaveLanguageButton {
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        WBLanguageSwitchButton *foundButton = [self wxkb_findViewOfClass:WBLanguageSwitchButtonClass inView:self];
        if (foundButton) {
            [buttonLock lock];
            globalLanguageSwitchButton = foundButton;
            [buttonLock unlock];
            NSLog(@"[WXKBTweak] ✅ 在WBMainInputView中找到并保存了语言切换按钮");
        }
    }
}

%new
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view {
    if ([view isKindOfClass:targetClass]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        id found = [self wxkb_findViewOfClass:targetClass inView:subview];
        if (found) return found;
    }
    
    return nil;
}

%end

// ============================================
// Hook WBKeyView - 微信按键视图（如果存在）
// ============================================
%hook WBKeyView

// 根据逆向报告，WBKeyView有内置的滑动检测方法
// 我们可以拦截这些方法来诊断问题

- (void)swipeUpBegan {
    NSLog(@"[WXKBTweak] 🔥 WBKeyView.swipeUpBegan 被调用（WeChat原生）");
    %orig;
}

- (void)swipeUpEnded {
    NSLog(@"[WXKBTweak] 🔥 WBKeyView.swipeUpEnded 被调用（WeChat原生）");
    %orig;
}

- (void)swipeDownBegan {
    NSLog(@"[WXKBTweak] 🔥 WBKeyView.swipeDownBegan 被调用（WeChat原生）");
    %orig;
}

- (void)swipeDownEnded {
    NSLog(@"[WXKBTweak] 🔥 WBKeyView.swipeDownEnded 被调用（WeChat原生）");
    %orig;
}

%end

// ============================================
// UIInputView Category 声明
// ============================================
@interface UIInputView (WXKBTweak)
- (void)wxkb_setupGestureRecognizer;
- (void)wxkb_handleLanguageSwitch:(NSNotification *)notification;
- (void)wxkb_performLanguageSwitchWithDirection:(CGFloat)direction;
- (id)wxkb_findLanguageSwitchButton;
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view;
- (UIViewController *)wxkb_findInputViewController;
- (UIButton *)wxkb_findLanguageSwitchButtonRecursive:(UIView *)view;
@end

// ============================================
// Hook UIInputView - 核心hook
// ============================================
%hook UIInputView

- (void)didMoveToWindow {
    %orig;

    if (!tweakEnabled || !self.window) return;

    // 检查Bundle ID
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        return;
    }

    NSLog(@"[WXKBTweak] didMoveToWindow: UIInputView已显示");

    // 设置手势识别器
    [self wxkb_setupGestureRecognizer];
}

- (void)didMoveToSuperview {
    %orig;

    if (!tweakEnabled) return;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        return;
    }

    NSLog(@"[WXKBTweak] didMoveToSuperview: 尝试恢复手势识别器");

    // 如果手势不存在，重新设置
    WXKBSwipeGestureRecognizer *gesture = objc_getAssociatedObject(self, kWXKBSwipeGestureKey);
    if (!gesture && self.superview) {
        [self wxkb_setupGestureRecognizer];
    }
}

%new
- (void)wxkb_setupGestureRecognizer {
    @synchronized(self) {
        // 检查是否已经设置过
        NSNumber *initialized = objc_getAssociatedObject(self, kWXKBInitializedKey);
        if (initialized && [initialized boolValue]) {
            NSLog(@"[WXKBTweak] 该UIInputView已初始化过");
            return;
        }

        NSLog(@"[WXKBTweak] 开始设置手势识别器...");

        // 创建手势识别器
        WXKBSwipeGestureRecognizer *swipeGesture = [[WXKBSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wxkb_handleLanguageSwitch:)];
        swipeGesture.cancelsTouchesInView = NO;
        swipeGesture.delaysTouchesBegan = NO;
        swipeGesture.attachedView = self;
        
        [self addGestureRecognizer:swipeGesture];
        objc_setAssociatedObject(self, kWXKBSwipeGestureKey, swipeGesture, OBJC_ASSOCIATION_RETAIN);
        NSLog(@"[WXKBTweak] ✅ 手势识别器已添加");

        // 创建视觉反馈视图
        if (visualFeedbackEnabled) {
            WXKBFeedbackView *feedbackView = [[WXKBFeedbackView alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
            feedbackView.center = CGPointMake(self.bounds.size.width / 2, 30);
            [self addSubview:feedbackView];
            objc_setAssociatedObject(self, kWXKBFeedbackViewKey, feedbackView, OBJC_ASSOCIATION_RETAIN);
            NSLog(@"[WXKBTweak] ✅ 视觉反馈视图已添加");
        }

        // 添加通知观察器
        NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
        if (!observerAttached || ![observerAttached boolValue]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(wxkb_handleLanguageSwitch:)
                                                         name:@"WXKBSwitchLanguage"
                                                       object:nil];
            objc_setAssociatedObject(self, kWXKBObserverAttachedKey, @YES, OBJC_ASSOCIATION_RETAIN);
            NSLog(@"[WXKBTweak] ✅ 通知观察器已添加");
        }

        // 标记为已初始化
        objc_setAssociatedObject(self, kWXKBInitializedKey, @YES, OBJC_ASSOCIATION_RETAIN);
        NSLog(@"[WXKBTweak] ✅ UIInputView初始化完成");
    }
}

%new
- (void)wxkb_handleLanguageSwitch:(NSNotification *)notification {
    CGFloat direction = 0;
    if (notification.userInfo && notification.userInfo[@"direction"]) {
        direction = [notification.userInfo[@"direction"] floatValue];
    }

    [self wxkb_performLanguageSwitchWithDirection:direction];

    // 显示视觉反馈
    if (visualFeedbackEnabled) {
        WXKBFeedbackView *feedbackView = objc_getAssociatedObject(self, kWXKBFeedbackViewKey);
        if (feedbackView) {
            NSString *text = direction < 0 ? @"English" : @"Chinese";
            [feedbackView showWithText:text];
        }
    }
}

%new
- (void)wxkb_performLanguageSwitchWithDirection:(CGFloat)direction {
    NSLog(@"[WXKBTweak] 🎯 开始切换语言，方向=%@", direction < 0 ? @"上滑(English)" : @"下滑(Chinese)");

    // ========================================
    // 方案0：直接调用languageSelectClicked方法（最新发现）
    // ========================================
    [buttonLock lock];
    WBLanguageSwitchButton *button = globalLanguageSwitchButton;
    [buttonLock unlock];

    if (button && button.window) {
        NSLog(@"[WXKBTweak] 🔥 方案0：尝试直接调用languageSelectClicked方法");
        if ([button respondsToSelector:@selector(languageSelectClicked)]) {
            NSLog(@"[WXKBTweak] ✅ 找到languageSelectClicked方法，直接调用！");
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [button performSelector:@selector(languageSelectClicked)];
            #pragma clang diagnostic pop
            return;
        }
        NSLog(@"[WXKBTweak] ⚠️ 按钮没有languageSelectClicked方法");
    }

    // ========================================
    // 方案1：使用保存的全局按钮实例（点击）
    // ========================================
    [buttonLock lock];
    button = globalLanguageSwitchButton;
    [buttonLock unlock];

    if (button && button.window) {
        NSLog(@"[WXKBTweak] ✅ 方案1：使用全局按钮实例，执行点击");
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // ========================================
    // 方案2：通过类名查找并调用languageSelectClicked
    // ========================================
    NSLog(@"[WXKBTweak] 🔍 方案2：通过类名查找按钮");
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        UIButton *foundButton = (UIButton *)[self wxkb_findViewOfClass:WBLanguageSwitchButtonClass inView:self];
        if (foundButton) {
            NSLog(@"[WXKBTweak] ✅ 找到按钮，尝试调用languageSelectClicked");
            [buttonLock lock];
            globalLanguageSwitchButton = (WBLanguageSwitchButton *)foundButton;
            [buttonLock unlock];
            
            if ([foundButton respondsToSelector:@selector(languageSelectClicked)]) {
                NSLog(@"[WXKBTweak] ✅ 成功调用languageSelectClicked");
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [foundButton performSelector:@selector(languageSelectClicked)];
                #pragma clang diagnostic pop
                return;
            }
            
            NSLog(@"[WXKBTweak] ⚠️ 按钮没有languageSelectClicked方法，尝试点击");
            [foundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            return;
        }
    }

    // ========================================
    // 方案3：递归查找任何含有语言/切换关键字的按钮
    // ========================================
    NSLog(@"[WXKBTweak] 🔍 方案3：递归查找语言切换按钮");
    UIButton *recursiveButton = [self wxkb_findLanguageSwitchButtonRecursive:self];
    if (recursiveButton) {
        NSLog(@"[WXKBTweak] ✅ 递归找到按钮");
        [buttonLock lock];
        if ([recursiveButton isKindOfClass:NSClassFromString(@"WBLanguageSwitchButton")]) {
            globalLanguageSwitchButton = (WBLanguageSwitchButton *)recursiveButton;
        }
        [buttonLock unlock];
        
        if ([recursiveButton respondsToSelector:@selector(languageSelectClicked)]) {
            NSLog(@"[WXKBTweak] ✅ 成功调用languageSelectClicked");
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [recursiveButton performSelector:@selector(languageSelectClicked)];
            #pragma clang diagnostic pop
            return;
        }
        
        NSLog(@"[WXKBTweak] ⚠️ 按钮没有languageSelectClicked方法，尝试点击");
        [recursiveButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // ========================================
    // 方案4：尝试调用UIViewController的切换方法
    // ========================================
    NSLog(@"[WXKBTweak] 🔍 方案4：查找输入法控制器方法");
    UIViewController *inputVC = [self wxkb_findInputViewController];
    if (inputVC) {
        SEL selectors[] = {
            @selector(languageSelectClicked),
            @selector(toggleLanguage),
            @selector(switchLanguage),
            @selector(switchToFunc),
            @selector(toggleFunc),
            nil
        };

        for (int i = 0; selectors[i] != nil; i++) {
            if ([inputVC respondsToSelector:selectors[i]]) {
                NSLog(@"[WXKBTweak] ✅ 找到方法: %@", NSStringFromSelector(selectors[i]));
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [inputVC performSelector:selectors[i]];
                #pragma clang diagnostic pop
                return;
            }
        }
    }

    // ========================================
    // 方案5：尝试通过通知触发语言切换
    // ========================================
    NSLog(@"[WXKBTweak] 🔍 方案5：尝试通过内部通知触发切换");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WBLanguageSwitchButtonClicked" 
                                                        object:nil 
                                                      userInfo:@{@"direction": @(direction)}];
    
    // ========================================
    // 方案6：尝试调用WBKeyFuncLangSwitch的方法
    // ========================================
    NSLog(@"[WXKBTweak] 🔍 方案6：查找WBKeyFuncLangSwitch的方法");
    Class WBKeyFuncLangSwitchClass = NSClassFromString(@"WBKeyFuncLangSwitch");
    if (WBKeyFuncLangSwitchClass) {
        SEL selectors[] = {
            @selector(switchToFunc),
            @selector(toggleFunc),
            @selector(switchLanguage),
            nil
        };

        for (int i = 0; selectors[i] != nil; i++) {
            if ([WBKeyFuncLangSwitchClass respondsToSelector:selectors[i]]) {
                NSLog(@"[WXKBTweak] ✅ 找到WBKeyFuncLangSwitch方法: %@", NSStringFromSelector(selectors[i]));
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [WBKeyFuncLangSwitchClass performSelector:selectors[i]];
                #pragma clang diagnostic pop
                return;
            }
        }
    }

    NSLog(@"[WXKBTweak] ⚠️ 所有6个方案都未成功，需要更多诊断信息");
}

%new
- (id)wxkb_findViewOfClass:(Class)targetClass inView:(UIView *)view {
    if ([view isKindOfClass:targetClass]) {
        return view;
    }

    for (UIView *subview in view.subviews) {
        id found = [self wxkb_findViewOfClass:targetClass inView:subview];
        if (found) return found;
    }

    return nil;
}

%new
- (UIViewController *)wxkb_findInputViewController {
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

%new
- (UIButton *)wxkb_findLanguageSwitchButtonRecursive:(UIView *)view {
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        NSString *title = button.titleLabel.text ?: @"";
        NSString *accessibilityLabel = button.accessibilityLabel ?: @"";
        NSString *className = NSStringFromClass([button class]);

        // 检查类名
        if ([className containsString:@"Language"] || [className containsString:@"Switch"]) {
            NSLog(@"[WXKBTweak] 通过类名找到按钮: %@", className);
            return button;
        }

        // 检查标题和标签
        NSArray *keywords = @[@"中", @"EN", @"英", @"CH", @"中英", @"English", @"Chinese", @"语言"];
        for (NSString *keyword in keywords) {
            if ([title containsString:keyword] || [accessibilityLabel containsString:keyword]) {
                NSLog(@"[WXKBTweak] 通过关键字找到按钮: %@", keyword);
                return button;
            }
        }
    }

    for (UIView *subview in view.subviews) {
        UIButton *found = [self wxkb_findLanguageSwitchButtonRecursive:subview];
        if (found) return found;
    }

    return nil;
}

- (void)dealloc {
    NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
    if (observerAttached && [observerAttached boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"[WXKBTweak] 通知观察器已移除");
    }
    %orig;
}

%end

// ============================================
// Hook UIInputViewController
// ============================================
%hook UIInputViewController

- (void)viewDidLoad {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        NSLog(@"[WXKBTweak] UIInputViewController已加载: %@", NSStringFromClass([self class]));
    }
}

%end

// ============================================
// 加载配置
// ============================================
static void loadPreferences() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist"];

    if (prefs) {
        tweakEnabled = [prefs[@"enabled"] boolValue] ?: YES;
        swipeThreshold = [prefs[@"threshold"] floatValue] ?: 50.0;
        hapticFeedbackEnabled = [prefs[@"haptic"] boolValue] ?: YES;
        visualFeedbackEnabled = [prefs[@"visual"] boolValue] ?: YES;
        swipeSensitivity = [prefs[@"sensitivity"] floatValue] ?: 1.0;

        NSLog(@"[WXKBTweak] 配置已加载: enabled=%d, threshold=%.2f, haptic=%d, visual=%d, sensitivity=%.2f",
              tweakEnabled, swipeThreshold, hapticFeedbackEnabled, visualFeedbackEnabled, swipeSensitivity);
    } else {
        NSLog(@"[WXKBTweak] 使用默认配置");
        tweakEnabled = YES;
        swipeThreshold = 50.0;
        hapticFeedbackEnabled = YES;
        visualFeedbackEnabled = YES;
        swipeSensitivity = 1.0;
    }
}

// ============================================
// 构造函数 - 插件入口
// ============================================
%ctor {
    @autoreleasepool {
        NSLog(@"[WXKBTweak] ========================================");
        NSLog(@"[WXKBTweak] WXKBTweak v3.1 已加载");
        NSLog(@"[WXKBTweak] 修复版本：滑动误判修复 + API级别触发");
        NSLog(@"[WXKBTweak] ========================================");

        // 初始化锁
        buttonLock = [[NSLock alloc] init];

        // 加载用户配置
        loadPreferences();

        // 监听配置变化通知
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            (CFNotificationCallback)loadPreferences,
            CFSTR("com.laowang.wxkbtweak/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );

        NSLog(@"[WXKBTweak] 初始化完成，等待微信输入法加载...");
    }
}
