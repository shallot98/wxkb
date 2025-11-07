/*
 * WXKBTweak - 微信输入法增强插件 v2.0
 * 功能：上下滑动切换中英文输入
 * 作者：老王（艹，这次是基于真实类名写的，更tm靠谱！）
 * 适配：rootless越狱 iOS 13.0+
 *
 * 基于逆向分析的真实类名：
 * - WBLanguageSwitchButton
 * - WBLanguageSwitchView
 * - WBKeyFuncLangSwitch
 */

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ============================================
// 配置参数 - 老王精心调教的参数
// ============================================
static BOOL tweakEnabled = YES;                    // 插件总开关
static CGFloat swipeThreshold = 50.0;              // 滑动阈值（像素）
static BOOL hapticFeedbackEnabled = YES;           // 震动反馈开关
static BOOL visualFeedbackEnabled = YES;           // 视觉反馈开关
static CGFloat swipeSensitivity = 1.0;             // 灵敏度系数 (0.5-2.0)

// ============================================
// 前向声明 - 微信输入法的真实类
// ============================================
@interface WBLanguageSwitchButton : UIButton
// 老王注：这是微信输入法的语言切换按钮
@end

@interface WBLanguageSwitchView : UIView
// 老王注：这是微信输入法的语言切换视图
@end

@interface WBKeyFuncLangSwitch : NSObject
// 老王注：这是微信输入法的语言切换功能类
@end

// ============================================
// 手势识别器 - 老王自己写的SB手势识别
// ============================================
@interface WXKBSwipeGestureRecognizer : UIPanGestureRecognizer
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) BOOL hasTriggered;
@end

@implementation WXKBSwipeGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self.view];
    self.hasTriggered = NO;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    if (!tweakEnabled || self.hasTriggered) return;

    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];

    // 计算垂直滑动距离（老王的数学还不错吧）
    CGFloat verticalDistance = currentPoint.y - self.startPoint.y;
    CGFloat horizontalDistance = fabs(currentPoint.x - self.startPoint.x);

    // 确保是垂直滑动，不是tm乱滑
    if (horizontalDistance > 30.0) return;

    // 应用灵敏度系数
    CGFloat adjustedThreshold = swipeThreshold / swipeSensitivity;

    // 检测上滑或下滑
    if (fabs(verticalDistance) > adjustedThreshold) {
        self.hasTriggered = YES;

        // 触发切换（艹，终于到关键部分了）
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WXKBSwitchLanguage"
                                                            object:nil
                                                          userInfo:@{@"direction": @(verticalDistance)}];

        // 震动反馈 - 让用户知道老王的插件在工作
        if (hapticFeedbackEnabled) {
            AudioServicesPlaySystemSound(1519); // 轻微震动
        }

        NSLog(@"[WXKBTweak] 老王：检测到滑动！距离=%.2f，方向=%@",
              verticalDistance, verticalDistance < 0 ? @"上滑" : @"下滑");
    }
}

- (void)reset {
    [super reset];
    self.hasTriggered = NO;
}

@end

// ============================================
// 视觉反馈视图 - 老王设计的漂亮UI
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

        // 创建文字标签
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
// Hook微信输入法的语言切换按钮
// ============================================
%hook WBLanguageSwitchButton

static WBLanguageSwitchButton *languageSwitchButton = nil;

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        languageSwitchButton = self;
        NSLog(@"[WXKBTweak] 老王：找到语言切换按钮！%@", self);
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        NSLog(@"[WXKBTweak] 老王：语言切换按钮已显示！");
    }
}

%end

// ============================================
// Hook微信输入法的语言切换视图
// ============================================
%hook WBLanguageSwitchView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        NSLog(@"[WXKBTweak] 老王：找到语言切换视图！%@", self);
    }
    return self;
}

%end

// ============================================
// UIInputView Category - 声明所有helper方法
// ============================================
@interface UIInputView (WXKBTweak)
- (void)handleLanguageSwitch:(NSNotification *)notification;
- (void)performLanguageSwitchWithDirection:(CGFloat)direction;
- (id)findLanguageSwitchButton;
- (id)findViewOfClass:(Class)targetClass inView:(UIView *)view;
- (UIViewController *)findInputViewController;
- (void)findAndTapLanguageSwitchButton;
- (void)searchButtonInView:(UIView *)view;
- (void)searchButtonInView:(UIView *)view depth:(NSInteger)depth maxDepth:(NSInteger)maxDepth;
@end

// ============================================
// Hook键盘主视图 - 添加手势识别
// ============================================
%hook UIInputView

static WXKBSwipeGestureRecognizer *swipeGesture = nil;
static WXKBFeedbackView *feedbackView = nil;
static BOOL hasSetupGesture = NO;

- (void)didMoveToWindow {
    %orig;

    if (!tweakEnabled || !self.window) return;

    // 检查是否是微信输入法（通过Bundle ID判断）
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        return;
    }

    // 避免重复设置（老王的优化）
    if (hasSetupGesture) {
        // 只更新feedbackView的位置
        if (feedbackView && visualFeedbackEnabled) {
            feedbackView.center = CGPointMake(self.bounds.size.width / 2, 30);
        }
        return;
    }

    // 添加手势识别器（老王的核心代码）
    swipeGesture = [[WXKBSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    swipeGesture.cancelsTouchesInView = NO;
    swipeGesture.delaysTouchesBegan = NO;
    [self addGestureRecognizer:swipeGesture];

    NSLog(@"[WXKBTweak] 老王：手势识别器已安装！");

    // 添加视觉反馈视图
    if (visualFeedbackEnabled) {
        feedbackView = [[WXKBFeedbackView alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
        feedbackView.center = CGPointMake(self.bounds.size.width / 2, 30);
        [self addSubview:feedbackView];
    }

    // 监听切换通知（只添加一次）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLanguageSwitch:)
                                                 name:@"WXKBSwitchLanguage"
                                               object:nil];

    hasSetupGesture = YES;
    NSLog(@"[WXKBTweak] 老王：初始化完成！");
}

%new
- (void)handleLanguageSwitch:(NSNotification *)notification {
    CGFloat direction = [notification.userInfo[@"direction"] floatValue];

    // 执行切换逻辑
    [self performLanguageSwitchWithDirection:direction];

    // 显示视觉反馈
    if (visualFeedbackEnabled && feedbackView) {
        NSString *text = direction < 0 ? @"English" : @"Chinese";
        [feedbackView showWithText:text];
    }
}

%new
- (void)performLanguageSwitchWithDirection:(CGFloat)direction {
    /*
     * 老王注：核心切换逻辑 - 修复版
     * 问题：之前的方法都没找到正确的按钮
     * 解决：更激进的查找策略
     */

    NSLog(@"[WXKBTweak] 老王：开始切换，方向=%@", direction < 0 ? @"英文" : @"中文");

    // 方案1：直接点击保存的按钮
    if (languageSwitchButton && [languageSwitchButton isKindOfClass:[UIButton class]]) {
        NSLog(@"[WXKBTweak] 老王：使用保存的切换按钮！");
        [languageSwitchButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // 方案2：查找WBLanguageSwitchButton类型
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        id switchBtn = [self findViewOfClass:WBLanguageSwitchButtonClass inView:self];
        if (switchBtn) {
            NSLog(@"[WXKBTweak] 老王：找到WBLanguageSwitchButton！");
            [(UIButton *)switchBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
            return;
        }
    }

    // 方案3：暴力查找所有UIButton，找切换按钮
    NSLog(@"[WXKBTweak] 老王：开始暴力查找所有按钮...");
    UIButton *foundButton = [self findLanguageSwitchButtonRecursive:self];
    if (foundButton) {
        NSLog(@"[WXKBTweak] 老王：暴力查找成功！点击按钮！");
        [foundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // 方案4：查找输入法控制器并尝试调用方法
    UIViewController *inputVC = [self findInputViewController];
    if (inputVC) {
        NSLog(@"[WXKBTweak] 老王：找到输入法控制器：%@", NSStringFromClass([inputVC class]));

        // 尝试更多可能的方法
        SEL selectors[] = {
            @selector(switchInputMode),
            @selector(toggleLanguage),
            @selector(switchLanguage),
            @selector(changeLanguage),
            @selector(switchToEnglish),
            @selector(switchToChinese),
            @selector(toggleInputMode),
            nil
        };

        for (int i = 0; selectors[i] != nil; i++) {
            if ([inputVC respondsToSelector:selectors[i]]) {
                NSLog(@"[WXKBTweak] 老王：找到方法！%@", NSStringFromSelector(selectors[i]));
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [inputVC performSelector:selectors[i]];
                #pragma clang diagnostic pop
                return;
            }
        }
    }

    NSLog(@"[WXKBTweak] 老王：艹，所有方法都失败了！需要更深入的逆向分析！");
}

%new
- (id)findLanguageSwitchButton {
    // 递归查找WBLanguageSwitchButton
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        return [self findViewOfClass:WBLanguageSwitchButtonClass inView:self];
    }
    return nil;
}

%new
- (id)findViewOfClass:(Class)targetClass inView:(UIView *)view {
    if ([view isKindOfClass:targetClass]) {
        return view;
    }

    for (UIView *subview in view.subviews) {
        id found = [self findViewOfClass:targetClass inView:subview];
        if (found) return found;
    }

    return nil;
}

%new
- (UIViewController *)findInputViewController {
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
- (UIButton *)findLanguageSwitchButtonRecursive:(UIView *)view {
    // 暴力递归查找切换按钮（老王的新方法）
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        NSString *title = button.titleLabel.text ?: @"";
        NSString *accessibilityLabel = button.accessibilityLabel ?: @"";
        NSString *className = NSStringFromClass([button class]);

        NSLog(@"[WXKBTweak] 老王：检查按钮 - 类:%@ 标题:%@ label:%@", className, title, accessibilityLabel);

        // 检查类名
        if ([className containsString:@"Language"] || [className containsString:@"Switch"]) {
            NSLog(@"[WXKBTweak] 老王：通过类名找到！");
            return button;
        }

        // 检查标题和label
        NSArray *keywords = @[@"中", @"EN", @"英", @"CH", @"中英", @"English", @"Chinese", @"语言", @"切换"];
        for (NSString *keyword in keywords) {
            if ([title containsString:keyword] || [accessibilityLabel containsString:keyword]) {
                NSLog(@"[WXKBTweak] 老王：通过关键字找到！");
                return button;
            }
        }
    }

    // 递归查找子视图
    for (UIView *subview in view.subviews) {
        UIButton *found = [self findLanguageSwitchButtonRecursive:subview];
        if (found) return found;
    }

    return nil;
}

%new
- (void)findAndTapLanguageSwitchButton {
    // 递归查找可能的切换按钮
    [self searchButtonInView:self];
}

%new
- (void)searchButtonInView:(UIView *)view {
    // 限制递归深度，避免性能问题（老王的优化）
    static NSInteger maxDepth = 5;
    [self searchButtonInView:view depth:0 maxDepth:maxDepth];
}

%new
- (void)searchButtonInView:(UIView *)view depth:(NSInteger)depth maxDepth:(NSInteger)maxDepth {
    // 超过最大深度就不再搜索
    if (depth > maxDepth) {
        return;
    }

    for (UIView *subview in view.subviews) {
        // 优先检查WBLanguageSwitchButton类型
        Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
        if (WBLanguageSwitchButtonClass && [subview isKindOfClass:WBLanguageSwitchButtonClass]) {
            NSLog(@"[WXKBTweak] 老王：找到WBLanguageSwitchButton！");
            [(UIButton *)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
            return;
        }

        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            NSString *title = button.titleLabel.text ?: @"";
            NSString *accessibilityLabel = button.accessibilityLabel ?: @"";

            // 查找包含"中英"、"EN"、"CH"等关键字的按钮
            NSArray *keywords = @[@"中", @"EN", @"英", @"CH", @"中英", @"English", @"Chinese"];
            for (NSString *keyword in keywords) {
                if ([title containsString:keyword] || [accessibilityLabel containsString:keyword]) {
                    NSLog(@"[WXKBTweak] 老王：找到切换按钮！标题=%@, label=%@", title, accessibilityLabel);
                    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                    return;
                }
            }
        }

        // 递归搜索子视图
        [self searchButtonInView:subview depth:depth + 1 maxDepth:maxDepth];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

%end

// ============================================
// Hook输入法控制器（如果能找到的话）
// ============================================

// 尝试hook可能的输入法控制器基类
%hook UIInputViewController

- (void)viewDidLoad {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        NSLog(@"[WXKBTweak] 老王：输入法控制器加载完成！%@", NSStringFromClass([self class]));
    }
}

%end

// ============================================
// 加载配置 - 从Preferences读取用户设置
// ============================================
static void loadPreferences() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist"];

    if (prefs) {
        tweakEnabled = [prefs[@"enabled"] boolValue];
        swipeThreshold = [prefs[@"threshold"] floatValue] ?: 50.0;
        hapticFeedbackEnabled = [prefs[@"haptic"] boolValue];
        visualFeedbackEnabled = [prefs[@"visual"] boolValue];
        swipeSensitivity = [prefs[@"sensitivity"] floatValue] ?: 1.0;

        NSLog(@"[WXKBTweak] 老王：配置加载成功！enabled=%d, threshold=%.2f", tweakEnabled, swipeThreshold);
    } else {
        NSLog(@"[WXKBTweak] 老王：使用默认配置");
    }
}

// ============================================
// 构造函数 - 插件入口
// ============================================
%ctor {
    @autoreleasepool {
        NSLog(@"[WXKBTweak] ========================================");
        NSLog(@"[WXKBTweak] 老王的微信输入法增强插件 v2.0 已加载！");
        NSLog(@"[WXKBTweak] 基于真实类名逆向分析版本");
        NSLog(@"[WXKBTweak] 艹，这次代码写得更tm靠谱了！");
        NSLog(@"[WXKBTweak] ========================================");

        // 加载用户配置
        loadPreferences();

        // 监听配置变化
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            (CFNotificationCallback)loadPreferences,
            CFSTR("com.laowang.wxkbtweak/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
}
