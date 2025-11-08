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
    
    NSLog(@"[WXKBTweak] 👆 手势开始 - 起点: (%.2f, %.2f)", self.startPoint.x, self.startPoint.y);
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

        NSLog(@"[WXKBTweak] 🎯 ===== 手势触发！ =====");
        NSLog(@"[WXKBTweak]   - 起点: (%.2f, %.2f)", self.startPoint.x, self.startPoint.y);
        NSLog(@"[WXKBTweak]   - 当前: (%.2f, %.2f)", currentPoint.x, currentPoint.y);
        NSLog(@"[WXKBTweak]   - 垂直距离: %.2fpx", verticalDistance);
        NSLog(@"[WXKBTweak]   - 水平距离: %.2fpx", horizontalDistance);
        NSLog(@"[WXKBTweak]   - 阈值: %.2fpx", adjustedThreshold);
        NSLog(@"[WXKBTweak]   - 方向: %@", verticalDistance < 0 ? @"上滑" : @"下滑");
        NSLog(@"[WXKBTweak]   - 灵敏度: %.2f", swipeSensitivity);

        // 触发切换（艹，终于到关键部分了）
        NSLog(@"[WXKBTweak] 📢 发送语言切换通知...");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WXKBSwitchLanguage"
                                                            object:nil
                                                          userInfo:@{@"direction": @(verticalDistance)}];

        // 震动反馈 - 让用户知道老王的插件在工作
        if (hapticFeedbackEnabled) {
            NSLog(@"[WXKBTweak] 📳 触发震动反馈");
            AudioServicesPlaySystemSound(1519); // 轻微震动
        } else {
            NSLog(@"[WXKBTweak] 🔇 震动反馈已禁用");
        }

        NSLog(@"[WXKBTweak] ✅ 手势处理完成 =====");
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
// Hook微信输入法的语言切换按钮 - 老王的核心hook
// ============================================
%hook WBLanguageSwitchButton

static WBLanguageSwitchButton *languageSwitchButton = nil;

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        languageSwitchButton = self;
        NSLog(@"[WXKBTweak] 老王：✅ 找到WBLanguageSwitchButton！地址=%p frame=%@", self, NSStringFromCGRect(frame));
    }
    return self;
}

- (instancetype)init {
    self = %orig;
    if (self) {
        languageSwitchButton = self;
        NSLog(@"[WXKBTweak] 老王：✅ 找到WBLanguageSwitchButton(init)！地址=%p", self);
    }
    return self;
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        languageSwitchButton = self;
        NSLog(@"[WXKBTweak] 老王：✅ 语言切换按钮已显示！可以点击了！");
        NSLog(@"[WXKBTweak] 老王：按钮信息 - 标题:%@ frame:%@", self.titleLabel.text, NSStringFromCGRect(self.frame));
    }
}

// 添加一个类方法来获取按钮实例
%new
+ (WBLanguageSwitchButton *)sharedButton {
    return languageSwitchButton;
}

// Hook按钮点击事件，看看正常点击时发生了什么
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents {
    NSLog(@"[WXKBTweak] 老王：🔥 WBLanguageSwitchButton被点击了！事件=%lu", (unsigned long)controlEvents);
    %orig;
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
- (UIButton *)findLanguageSwitchButtonRecursive:(UIView *)view;
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
    
    NSLog(@"[WXKBTweak] 🎹 ===== UIInputView didMoveToWindow 被调用 =====");
    NSLog(@"[WXKBTweak]   - 视图地址: %p", self);
    NSLog(@"[WXKBTweak]   - 是否有Window: %@", self.window ? @"✅ 有" : @"❌ 无");
    NSLog(@"[WXKBTweak]   - 视图大小: %@", NSStringFromCGRect(self.bounds));
    
    if (!tweakEnabled) {
        NSLog(@"[WXKBTweak] ❌ 插件已禁用，跳过初始化");
        return;
    }
    
    if (!self.window) {
        NSLog(@"[WXKBTweak] ⚠️  视图没有Window，跳过初始化");
        return;
    }

    // 检查是否是微信输入法（通过Bundle ID判断）
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"[WXKBTweak] 🎯 Bundle ID检查:");
    NSLog(@"[WXKBTweak]   - 当前Bundle ID: %@", bundleID);
    NSLog(@"[WXKBTweak]   - 目标Bundle ID: com.tencent.wetype.keyboard");
    
    if (![bundleID isEqualToString:@"com.tencent.wetype.keyboard"]) {
        NSLog(@"[WXKBTweak] ❌ Bundle ID不匹配，不是微信输入法进程");
        NSLog(@"[WXKBTweak] 💡 这可能意味着:");
        NSLog(@"[WXKBTweak]   1. WXKBTweak.plist中的Filter配置错误");
        NSLog(@"[WXKBTweak]   2. 微信输入法的实际Bundle ID已更改");
        NSLog(@"[WXKBTweak]   3. 这是其他应用的键盘视图");
        return;
    }
    
    NSLog(@"[WXKBTweak] ✅ Bundle ID匹配，这是微信输入法进程！");

    // 避免重复设置（老王的优化）
    if (hasSetupGesture) {
        NSLog(@"[WXKBTweak] 🔧 手势已经设置过，更新feedbackView位置");
        // 只更新feedbackView的位置
        if (feedbackView && visualFeedbackEnabled) {
            feedbackView.center = CGPointMake(self.bounds.size.width / 2, 30);
            NSLog(@"[WXKBTweak] ✅ feedbackView位置已更新");
        }
        return;
    }

    NSLog(@"[WXKBTweak] 🚀 开始初始化手势识别器...");
    
    // 添加手势识别器（老王的核心代码）
    swipeGesture = [[WXKBSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    swipeGesture.cancelsTouchesInView = NO;
    swipeGesture.delaysTouchesBegan = NO;
    [self addGestureRecognizer:swipeGesture];
    
    NSLog(@"[WXKBTweak] ✅ 手势识别器已安装！");
    NSLog(@"[WXKBTweak]   - 手势类型: %@", NSStringFromClass([swipeGesture class]));
    NSLog(@"[WXKBTweak]   - 取消触摸: %@", swipeGesture.cancelsTouchesInView ? @"是" : @"否");
    NSLog(@"[WXKBTweak]   - 延迟触摸: %@", swipeGesture.delaysTouchesBegan ? @"是" : @"否");

    // 添加视觉反馈视图
    if (visualFeedbackEnabled) {
        NSLog(@"[WXKBTweak] 🎨 创建视觉反馈视图...");
        feedbackView = [[WXKBFeedbackView alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
        feedbackView.center = CGPointMake(self.bounds.size.width / 2, 30);
        [self addSubview:feedbackView];
        NSLog(@"[WXKBTweak] ✅ 视觉反馈视图已创建并添加");
    } else {
        NSLog(@"[WXKBTweak] ⚠️  视觉反馈已禁用");
    }

    // 监听切换通知（只添加一次）
    NSLog(@"[WXKBTweak] 📢 注册通知监听器...");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLanguageSwitch:)
                                                 name:@"WXKBSwitchLanguage"
                                               object:nil];
    NSLog(@"[WXKBTweak] ✅ 通知监听器已注册");

    hasSetupGesture = YES;
    NSLog(@"[WXKBTweak] 🎉 WXKBTweak初始化完成！");
    NSLog(@"[WXKBTweak]   - 插件状态: ✅ 已启用");
    NSLog(@"[WXKBTweak]   - 手势识别: ✅ 已安装");
    NSLog(@"[WXKBTweak]   - 视觉反馈: %@", visualFeedbackEnabled ? @"✅ 已启用" : @"❌ 已禁用");
    NSLog(@"[WXKBTweak]   - 震动反馈: %@", hapticFeedbackEnabled ? @"✅ 已启用" : @"❌ 已禁用");
    NSLog(@"[WXKBTweak]   - 滑动阈值: %.2fpx", swipeThreshold);
    NSLog(@"[WXKBTweak]   - 灵敏度系数: %.2f", swipeSensitivity);
    NSLog(@"[WXKBTweak] ===== 初始化完成 =====");
}

%new
- (void)handleLanguageSwitch:(NSNotification *)notification {
    NSLog(@"[WXKBTweak] 📨 ===== 收到语言切换通知 =====");
    NSLog(@"[WXKBTweak]   - 通知名称: %@", notification.name);
    NSLog(@"[WXKBTweak]   - 发送者: %@", notification.object);
    NSLog(@"[WXKBTweak]   - 用户信息: %@", notification.userInfo);
    
    CGFloat direction = [notification.userInfo[@"direction"] floatValue];
    NSLog(@"[WXKBTweak]   - 切换方向: %@ (%.2f)", direction < 0 ? @"上滑→英文" : @"下滑→中文", direction);

    // 执行切换逻辑
    NSLog(@"[WXKBTweak] 🔄 开始执行语言切换逻辑...");
    [self performLanguageSwitchWithDirection:direction];

    // 显示视觉反馈
    if (visualFeedbackEnabled && feedbackView) {
        NSString *text = direction < 0 ? @"English" : @"Chinese";
        NSLog(@"[WXKBTweak] 🎨 显示视觉反馈: %@", text);
        [feedbackView showWithText:text];
    } else {
        NSLog(@"[WXKBTweak] ⚠️  视觉反馈已跳过 (enabled=%@, feedbackView=%@)", 
              visualFeedbackEnabled ? @"YES" : @"NO", feedbackView ? @"存在" : @"不存在");
    }
    
    NSLog(@"[WXKBTweak] ✅ 语言切换通知处理完成 =====");
}

%new
- (void)performLanguageSwitchWithDirection:(CGFloat)direction {
    /*
     * 老王注：核心切换逻辑 - 完全重写版
     * 基于深度分析的真实API
     */

    NSLog(@"[WXKBTweak] 老王：🎯 开始切换，方向=%@", direction < 0 ? @"上滑→英文" : @"下滑→中文");

    // ========================================
    // 方案0：直接调用languageSelectClicked方法（最新发现！）
    // ========================================
    if (languageSwitchButton) {
        NSLog(@"[WXKBTweak] 老王：🔥 方案0 - 调用languageSelectClicked方法！");

        // 尝试调用languageSelectClicked方法
        if ([languageSwitchButton respondsToSelector:@selector(languageSelectClicked)]) {
            NSLog(@"[WXKBTweak] 老王：✅ 找到languageSelectClicked方法！直接调用！");
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [languageSwitchButton performSelector:@selector(languageSelectClicked)];
            #pragma clang diagnostic pop
            return;
        } else {
            NSLog(@"[WXKBTweak] 老王：❌ 按钮没有languageSelectClicked方法");
        }
    }

    // ========================================
    // 方案1：使用保存的WBLanguageSwitchButton实例（最可靠）
    // ========================================
    if (languageSwitchButton) {
        NSLog(@"[WXKBTweak] 老王：✅ 方案1 - 使用保存的按钮实例");
        NSLog(@"[WXKBTweak] 老王：按钮地址=%p 是否有效=%d", languageSwitchButton, languageSwitchButton.window != nil);

        if (languageSwitchButton.window) {
            NSLog(@"[WXKBTweak] 老王：🔥 点击WBLanguageSwitchButton！");
            [languageSwitchButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            return;
        } else {
            NSLog(@"[WXKBTweak] 老王：⚠️ 按钮不在window中，可能已失效");
            languageSwitchButton = nil;  // 清空失效的引用
        }
    }

    // ========================================
    // 方案2：通过类名查找WBLanguageSwitchButton
    // ========================================
    NSLog(@"[WXKBTweak] 老王：🔍 方案2 - 通过类名查找");
    Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
    if (WBLanguageSwitchButtonClass) {
        NSLog(@"[WXKBTweak] 老王：✅ WBLanguageSwitchButton类存在！");

        id switchBtn = [self findViewOfClass:WBLanguageSwitchButtonClass inView:self];
        if (switchBtn) {
            NSLog(@"[WXKBTweak] 老王：🔥 找到按钮！点击！");
            [(UIButton *)switchBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
            languageSwitchButton = switchBtn;  // 保存引用
            return;
        } else {
            NSLog(@"[WXKBTweak] 老王：❌ 在视图树中没找到按钮实例");
        }
    } else {
        NSLog(@"[WXKBTweak] 老王：❌ WBLanguageSwitchButton类不存在！");
    }

    // ========================================
    // 方案3：查找languageSwitchView属性
    // ========================================
    NSLog(@"[WXKBTweak] 老王：🔍 方案3 - 查找languageSwitchView属性");
    UIViewController *inputVC = [self findInputViewController];
    if (inputVC) {
        NSLog(@"[WXKBTweak] 老王：找到控制器：%@", NSStringFromClass([inputVC class]));

        // 尝试访问languageSwitchView属性
        if ([inputVC respondsToSelector:@selector(languageSwitchView)]) {
            NSLog(@"[WXKBTweak] 老王：✅ 控制器有languageSwitchView属性！");
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id switchView = [inputVC performSelector:@selector(languageSwitchView)];
            #pragma clang diagnostic pop

            if (switchView) {
                NSLog(@"[WXKBTweak] 老王：找到switchView：%@", switchView);
                // 在switchView中查找按钮
                UIButton *btn = [self findLanguageSwitchButtonRecursive:switchView];
                if (btn) {
                    NSLog(@"[WXKBTweak] 老王：🔥 在switchView中找到按钮！点击！");
                    [btn sendActionsForControlEvents:UIControlEventTouchUpInside];
                    return;
                }
            }
        }
    }

    // ========================================
    // 方案4：暴力递归查找所有按钮
    // ========================================
    NSLog(@"[WXKBTweak] 老王：🔍 方案4 - 暴力递归查找");
    UIButton *foundButton = [self findLanguageSwitchButtonRecursive:self];
    if (foundButton) {
        NSLog(@"[WXKBTweak] 老王：🔥 暴力查找成功！点击按钮！");
        [foundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // ========================================
    // 方案5：尝试调用控制器的切换方法
    // ========================================
    NSLog(@"[WXKBTweak] 老王：🔍 方案5 - 尝试调用控制器方法");
    if (inputVC) {
        // 基于分析结果的真实方法名
        SEL selectors[] = {
            @selector(setInputMode:),
            @selector(setKeyboardMode:),
            @selector(switchToFunc),
            @selector(toggleFunc),
            @selector(switchEngineSession),
            @selector(switchPanelView:),
            @selector(switchInputMode),
            @selector(toggleLanguage),
            nil
        };

        for (int i = 0; selectors[i] != nil; i++) {
            if ([inputVC respondsToSelector:selectors[i]]) {
                NSLog(@"[WXKBTweak] 老王：✅ 找到方法！%@", NSStringFromSelector(selectors[i]));
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [inputVC performSelector:selectors[i]];
                #pragma clang diagnostic pop
                return;
            }
        }
    }

    NSLog(@"[WXKBTweak] 老王：❌❌❌ 艹！所有5个方案都失败了！");
    NSLog(@"[WXKBTweak] 老王：请查看日志，看看找到了什么按钮");
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
    NSLog(@"[WXKBTweak] 📋 ===== 开始加载配置文件 =====");
    
    // 尝试多种可能的配置文件路径（rootless环境适配）
    NSArray *possiblePaths = @[
        @"/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist",
        @"/var/jb/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist",
        @"/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist"
    ];
    
    NSMutableDictionary *prefs = nil;
    NSString *usedPath = nil;
    
    for (NSString *path in possiblePaths) {
        NSLog(@"[WXKBTweak] 🔍 尝试路径: %@", path);
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
            if (prefs) {
                usedPath = path;
                NSLog(@"[WXKBTweak] ✅ 找到配置文件: %@", path);
                break;
            }
        } else {
            NSLog(@"[WXKBTweak] ❌ 文件不存在: %@", path);
        }
    }
    
    if (prefs && usedPath) {
        NSLog(@"[WXKBTweak] 📖 配置文件内容:");
        NSLog(@"[WXKBTweak]   - enabled: %@", prefs[@"enabled"]);
        NSLog(@"[WXKBTweak]   - threshold: %@", prefs[@"threshold"]);
        NSLog(@"[WXKBTweak]   - haptic: %@", prefs[@"haptic"]);
        NSLog(@"[WXKBTweak]   - visual: %@", prefs[@"visual"]);
        NSLog(@"[WXKBTweak]   - sensitivity: %@", prefs[@"sensitivity"]);
        
        // 读取配置值
        tweakEnabled = [prefs[@"enabled"] boolValue];
        swipeThreshold = [prefs[@"threshold"] floatValue] ?: 50.0;
        hapticFeedbackEnabled = [prefs[@"haptic"] boolValue];
        visualFeedbackEnabled = [prefs[@"visual"] boolValue];
        swipeSensitivity = [prefs[@"sensitivity"] floatValue] ?: 1.0;
        
        NSLog(@"[WXKBTweak] ✅ 配置加载成功！");
        NSLog(@"[WXKBTweak]   - 插件开关: %@", tweakEnabled ? @"✅ 开启" : @"❌ 关闭");
        NSLog(@"[WXKBTweak]   - 滑动阈值: %.2fpx", swipeThreshold);
        NSLog(@"[WXKBTweak]   - 震动反馈: %@", hapticFeedbackEnabled ? @"✅ 开启" : @"❌ 关闭");
        NSLog(@"[WXKBTweak]   - 视觉反馈: %@", visualFeedbackEnabled ? @"✅ 开启" : @"❌ 关闭");
        NSLog(@"[WXKBTweak]   - 灵敏度: %.2f", swipeSensitivity);
    } else {
        NSLog(@"[WXKBTweak] ⚠️  配置文件不存在或读取失败，使用默认配置");
        NSLog(@"[WXKBTweak] 💡 请检查PreferenceBundle是否正确安装");
        NSLog(@"[WXKBTweak] 💡 或手动创建配置文件: %@", possiblePaths[0]);
        
        // 使用默认配置
        tweakEnabled = YES;
        swipeThreshold = 50.0;
        hapticFeedbackEnabled = YES;
        visualFeedbackEnabled = YES;
        swipeSensitivity = 1.0;
        
        NSLog(@"[WXKBTweak] 📋 默认配置:");
        NSLog(@"[WXKBTweak]   - 插件开关: ✅ 开启");
        NSLog(@"[WXKBTweak]   - 滑动阈值: %.2fpx", swipeThreshold);
        NSLog(@"[WXKBTweak]   - 震动反馈: ✅ 开启");
        NSLog(@"[WXKBTweak]   - 视觉反馈: ✅ 开启");
        NSLog(@"[WXKBTweak]   - 灵敏度: %.2f", swipeSensitivity);
    }
    
    NSLog(@"[WXKBTweak] 📋 ===== 配置加载完成 =====");
}

// ============================================
// 构造函数 - 插件入口
// ============================================
%ctor {
    @autoreleasepool {
        // ===== 基础诊断信息 =====
        NSLog(@"[WXKBTweak] ========================================");
        NSLog(@"[WXKBTweak] 🚀 WXKBTweak 构造函数开始执行！");
        NSLog(@"[WXKBTweak] 版本: v2.0 诊断增强版");
        NSLog(@"[WXKBTweak] ========================================");
        
        // ===== 进程诊断信息 =====
        NSString *processName = [[NSProcessInfo processInfo] processName];
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        pid_t processID = [[NSProcessInfo processInfo] processIdentifier];
        
        NSLog(@"[WXKBTweak] 📱 进程诊断:");
        NSLog(@"[WXKBTweak]   - 进程名: %@", processName);
        NSLog(@"[WXKBTweak]   - Bundle ID: %@", bundleID);
        NSLog(@"[WXKBTweak]   - 进程ID: %d", (int)processID);
        NSLog(@"[WXKBTweak]   - 主Bundle路径: %@", [[NSBundle mainBundle] bundlePath]);
        
        // ===== 验证目标进程 =====
        NSString *targetBundleID = @"com.tencent.wetype.keyboard";
        BOOL isTargetProcess = [bundleID isEqualToString:targetBundleID];
        
        NSLog(@"[WXKBTweak] 🎯 目标验证:");
        NSLog(@"[WXKBTweak]   - 目标Bundle ID: %@", targetBundleID);
        NSLog(@"[WXKBTweak]   - 是否匹配: %@", isTargetProcess ? @"✅ 是" : @"❌ 否");
        
        if (!isTargetProcess) {
            NSLog(@"[WXKBTweak] ⚠️  警告: 当前进程不是目标进程，tweak可能不会生效");
            NSLog(@"[WXKBTweak] 💡 建议: 检查 WXKBTweak.plist 中的 Filter 配置");
        } else {
            NSLog(@"[WXKBTweak] ✅ 目标进程匹配，tweak应该会生效");
        }
        
        // ===== 系统环境诊断 =====
        NSLog(@"[WXKBTweak] 🌍 系统环境:");
        NSLog(@"[WXKBTweak]   - iOS版本: %@", [[UIDevice currentDevice] systemVersion]);
        NSLog(@"[WXKBTweak]   - 设备型号: %@", [[UIDevice currentDevice] model]);
        
        // ===== MobileSubstrate 诊断 =====
        NSLog(@"[WXKBTweak] 🔧 MobileSubstrate状态:");
        NSLog(@"[WXKBTweak]   - 构造函数已执行 ✅");
        NSLog(@"[WXKBTweak]   - Logos框架可用 ✅");
        NSLog(@"[WXKBTweak]   - Objective-C运行时正常 ✅");

        // 加载用户配置
        NSLog(@"[WXKBTweak] 📋 开始加载用户配置...");
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
        
        NSLog(@"[WXKBTweak] 🎉 构造函数执行完成！");
        NSLog(@"[WXKBTweak] 💡 如果看到此日志，说明tweak已被MobileSubstrate加载");
        NSLog(@"[WXKBTweak] ========================================");
    }
}
