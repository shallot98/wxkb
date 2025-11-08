# WXKBTweak v3.0 修复日志 - 完整的生命周期管理

## 修复概述

本修复版本 (v3.0) 彻底改善了 WXKBTweak 在 Dopamine rootless 环境下的初始化和生命周期问题。核心问题是原始版本使用了全局静态变量来跟踪状态，导致 UIInputView 被重新创建时功能失效。

## 核心问题分析

### 原始版本的问题

1. **静态变量问题** (关键!)
   - `hasSetupGesture` 是全局静态变量，只初始化一次
   - 如果 UIInputView 被销毁并重新创建，hook 不会重新安装
   - 导致功能在键盘刷新后立即失效

2. **生命周期管理缺陷**
   - 没有处理 UIInputView 被销毁的情况
   - 没有实现恢复机制
   - 观察者可能泄漏

3. **权限和环保境问题**
   - rootless 环保下缺少特殊处理
   - 没有足够的错误处理

### 具体场景

1. **初始安装** → tweak 加载 → hook 安装 → 手势工作 ✅
2. **键盘刷新** → UIInputView 重新创建 → hook 不重新安装 → 手势失效 ❌
3. **应用切换** → UIInputView 销毁 → 再次创建 → 仍然失效 ❌

## v3.0 修复方案

### 1. 使用关联对象替代全局静态变量

**原理**：使用 `objc_setAssociatedObject` 和 `objc_getAssociatedObject` 为每个 UIInputView 实例存储独立的状态。

```objc
// 关键键值定义
static const void *kWXKBSwipeGestureKey = &kWXKBSwipeGestureKey;
static const void *kWXKBFeedbackViewKey = &kWXKBFeedbackViewKey;
static const void *kWXKBInitializedKey = &kWXKBInitializedKey;
static const void *kWXKBObserverAttachedKey = &kWXKBObserverAttachedKey;
```

**优势**：
- 每个 UIInputView 实例有独立的状态
- 当实例销毁时，关联对象自动释放
- 支持多个 UIInputView 同时存在

### 2. 多重初始化机制

添加了两个关键生命周期方法：

```objc
- (void)didMoveToWindow {
    // 当UIInputView被添加到window时，设置手势
    [self wxkb_setupGestureRecognizer];
}

- (void)didMoveToSuperview {
    // 当UIInputView被添加到superview时，恢复手势（如果丢失）
    WXKBSwipeGestureRecognizer *gesture = objc_getAssociatedObject(self, kWXKBSwipeGestureKey);
    if (!gesture && self.superview) {
        [self wxkb_setupGestureRecognizer];
    }
}
```

这确保了：
- UIInputView 首次显示时安装手势
- 如果手势被意外卸载，在再次显示时恢复

### 3. 线程安全的全局按钮引用

保留全局 `globalLanguageSwitchButton` 但加了锁保护：

```objc
static NSLock *buttonLock = nil;

// 在设置时上锁
[buttonLock lock];
globalLanguageSwitchButton = self;
[buttonLock unlock];
```

**原因**：多个 UIInputView 可能同时访问按钮引用，需要线程安全。

### 4. 改进的初始化方法

新的 `wxkb_setupGestureRecognizer` 方法使用同步块和多重检查：

```objc
%new
- (void)wxkb_setupGestureRecognizer {
    @synchronized(self) {
        // 1. 检查是否已初始化
        NSNumber *initialized = objc_getAssociatedObject(self, kWXKBInitializedKey);
        if (initialized && [initialized boolValue]) {
            NSLog(@"[WXKBTweak] 该UIInputView已初始化过");
            return;
        }

        // 2. 创建手势识别器
        WXKBSwipeGestureRecognizer *swipeGesture = ...;
        [self addGestureRecognizer:swipeGesture];
        objc_setAssociatedObject(self, kWXKBSwipeGestureKey, swipeGesture, OBJC_ASSOCIATION_RETAIN);

        // 3. 创建反馈视图
        if (visualFeedbackEnabled) { ... }

        // 4. 添加通知观察器
        [[NSNotificationCenter defaultCenter] addObserver:self ...];
        objc_setAssociatedObject(self, kWXKBObserverAttachedKey, @YES, OBJC_ASSOCIATION_RETAIN);

        // 5. 标记为已初始化
        objc_setAssociatedObject(self, kWXKBInitializedKey, @YES, OBJC_ASSOCIATION_RETAIN);
    }
}
```

这确保了：
- 初始化是原子操作（使用 @synchronized）
- 防止重复初始化
- 所有资源都被正确关联

### 5. 改进的清理机制

```objc
- (void)dealloc {
    NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
    if (observerAttached && [observerAttached boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"[WXKBTweak] 通知观察器已移除");
    }
    %orig;
}
```

确保观察器被正确移除，防止泄漏。

### 6. 增强的诊断日志

添加了详细的日志记录在每个关键步骤：

- `didMoveToWindow`: UIInputView 显示时
- `wxkb_setupGestureRecognizer`: 手势安装时
- 手势识别: 每次检测到滑动时
- 语言切换: 每个切换方案的尝试

## 新的命名约定

所有新的方法都使用 `wxkb_` 前缀：

- `wxkb_setupGestureRecognizer` - 设置手势
- `wxkb_handleLanguageSwitch:` - 处理切换通知
- `wxkb_performLanguageSwitchWithDirection:` - 执行切换
- `wxkb_findViewOfClass:inView:` - 查找视图
- `wxkb_findInputViewController` - 查找控制器
- `wxkb_findLanguageSwitchButtonRecursive:` - 递归查找按钮

这避免了与原始方法的冲突。

## 预期的改善

### 功能持久化

✅ **上下滑动功能现在可以持续工作**
- UIInputView 被重新创建时自动重新安装手势
- 键盘刷新后功能仍然有效

✅ **指示器持续显示**
- 视觉反馈视图使用关联对象存储
- 随着 UIInputView 的生命周期持续显示

✅ **语言切换功能稳定**
- 全局按钮引用有线程安全保护
- 多个查找策略确保能找到按钮

### 错误恢复

✅ **自动恢复机制**
- 通过 `didMoveToSuperview` 检测并恢复丢失的手势
- 不需要重启应用或重新加载键盘

✅ **完整的诊断信息**
- 每个步骤都有日志记录
- 可以轻松追踪问题发生的位置

## 测试建议

### 基本功能测试

1. 打开任意应用的输入框
2. 确保是微信输入法
3. 上下滑动测试切换
4. 观察指示器显示

### 稳定性测试

1. 连续打开关闭键盘10次
2. 切换应用后再打开键盘
3. 长时间使用观察是否仍然工作

### 日志验证

查看日志确认：
- `[WXKBTweak] WXKBTweak v3.0 已加载` - 插件加载
- `[WXKBTweak] ✅ 手势识别器已添加` - 手势安装
- `[WXKBTweak] ✅ 手势检测成功！` - 手势工作
- `[WXKBTweak] ✅ 方案1：使用全局按钮实例` - 切换成功

## 向后兼容性

这个版本保持了完整的向后兼容性：
- plist 配置格式不变
- Preferences 设置不变
- 所有原始功能保留

## 版本信息

- **版本**：3.0
- **发布日期**：2024
- **修复重点**：初始化和生命周期管理
- **支持**：iOS 13.0+ (arm64/arm64e)
- **支持越狱**：Dopamine rootless

## 相关文件修改

- `Tweak.x` - 完全重写，使用关联对象和改进的生命周期管理
- 其他文件保持不变（plist、preferences、Makefile等）

## 后续改进计划

未来可能的改进：
1. 添加性能监控
2. 实现更灵活的手势识别
3. 支持自定义切换策略
4. 添加实时配置调试界面
