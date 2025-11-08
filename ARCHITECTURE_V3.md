# WXKBTweak v3.0 - 架构设计文档

## 概述

WXKBTweak v3.0 采用了基于对象关联和多重初始化的架构，彻底解决了原始版本在 rootless 环境下的生命周期问题。

## 核心架构

### 1. 对象关联系统 (Associated Objects)

#### 设计思想

不使用全局变量跟踪 UIInputView 状态，而是将状态绑定到每个 UIInputView 实例上。

#### 关键值定义

```objc
static const void *kWXKBSwipeGestureKey = &kWXKBSwipeGestureKey;
static const void *kWXKBFeedbackViewKey = &kWXKBFeedbackViewKey;
static const void *kWXKBInitializedKey = &kWXKBInitializedKey;
static const void *kWXKBObserverAttachedKey = &kWXKBObserverAttachedKey;
```

**原理**：每个指针地址都是唯一的，用作字典的键。

#### 存储操作

```objc
// 存储手势识别器
objc_setAssociatedObject(self, kWXKBSwipeGestureKey, swipeGesture, OBJC_ASSOCIATION_RETAIN);

// 检索手势识别器
WXKBSwipeGestureRecognizer *gesture = objc_getAssociatedObject(self, kWXKBSwipeGestureKey);
```

**OBJC_ASSOCIATION_RETAIN** 的含义：
- 关联对象被强引用（retain）
- 对象不会被意外释放
- 当 UIInputView 被销毁时，关联对象自动释放

### 2. 多重初始化机制

#### 初始化流程图

```
UIInputView created
    ↓
didMoveToWindow called
    ↓
[wxkb_setupGestureRecognizer]
    ↓
    @synchronized(self) {
        Check if already initialized
        ├─ YES → return (skip)
        └─ NO → initialize
            ├─ Create & add gesture recognizer
            ├─ Create & add feedback view
            ├─ Add notification observer
            └─ Mark as initialized
    }
```

#### 恢复机制

```
didMoveToSuperview called
    ↓
Check if gesture exists
├─ NO → [wxkb_setupGestureRecognizer]
└─ YES → return (skip)
```

**为什么需要两个初始化点**：

1. **didMoveToWindow** - UIInputView 首次显示
2. **didMoveToSuperview** - UIInputView 移动但可能丢失手势

### 3. 手势识别管道

#### 手势流程

```
User swipes on keyboard
    ↓
WXKBSwipeGestureRecognizer.touchesBegan
    ├─ Record start point
    └─ Set hasTriggered = NO
    ↓
WXKBSwipeGestureRecognizer.touchesMoved
    ├─ Calculate vertical distance
    ├─ Check if vertical (not horizontal)
    ├─ Check if exceeds threshold
    └─ If YES → POST NOTIFICATION
    ↓
UINotificationCenter receives "WXKBSwitchLanguage"
    ↓
UIInputView.wxkb_handleLanguageSwitch:
    ├─ Extract direction from notification
    ├─ Show visual feedback
    └─ Call wxkb_performLanguageSwitchWithDirection:
    ↓
wxkb_performLanguageSwitchWithDirection:
    ├─ Try 4 methods to find and tap the button
    └─ Execute language switch
```

### 4. 按钮查找策略

4 层递进式的查找机制：

#### 方案 1：全局缓存
```objc
[buttonLock lock];
WBLanguageSwitchButton *button = globalLanguageSwitchButton;
[buttonLock unlock];

if (button && button.window) {
    // Use cached button
}
```
**优势**：最快，O(1) 时间复杂度

#### 方案 2：通过类名查找
```objc
Class WBLanguageSwitchButtonClass = NSClassFromString(@"WBLanguageSwitchButton");
UIButton *foundButton = [self wxkb_findViewOfClass:WBLanguageSwitchButtonClass inView:self];
```
**优势**：可靠，依赖类名而非实例引用

#### 方案 3：递归关键字匹配
```objc
NSArray *keywords = @[@"中", @"EN", @"英", @"CH", @"语言"];
// Check each button's title and accessibility label
```
**优势**：容错性强，即使类名改变也能找到

#### 方案 4：控制器方法调用
```objc
SEL selectors[] = {
    @selector(languageSelectClicked),
    @selector(toggleLanguage),
    // ... more selectors
};
// Try each selector on UIViewController
```
**优势**：最后的备选方案，直接调用切换方法

### 5. 线程安全设计

#### 按钮引用保护

```objc
static NSLock *buttonLock = nil;

// 在 %ctor 中初始化
buttonLock = [[NSLock alloc] init];

// 在访问时加锁
[buttonLock lock];
WBLanguageSwitchButton *button = globalLanguageSwitchButton;
[buttonLock unlock];
```

**为什么需要**：
- 主线程处理手势
- 可能有其他线程访问按钮
- 防止竞态条件

#### 初始化原子性

```objc
@synchronized(self) {
    // All initialization happens atomically
    // 防止多个线程同时初始化
}
```

### 6. 通知观察器管理

#### 添加观察器

```objc
// 在 wxkb_setupGestureRecognizer 中
NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
if (!observerAttached || ![observerAttached boolValue]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wxkb_handleLanguageSwitch:)
                                                 name:@"WXKBSwitchLanguage"
                                               object:nil];
    objc_setAssociatedObject(self, kWXKBObserverAttachedKey, @YES, OBJC_ASSOCIATION_RETAIN);
}
```

#### 移除观察器

```objc
// 在 dealloc 中
- (void)dealloc {
    NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
    if (observerAttached && [observerAttached boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    %orig;
}
```

**重要**：使用 %orig 确保父类的 dealloc 也被调用

## 数据流

### 完整的手势到切换流程

```
┌─ Touch down on keyboard
│
├─ touchesBegan:
│  └─ Record startPoint
│
├─ touchesMoved: (multiple times)
│  ├─ Calculate verticalDistance
│  ├─ Calculate horizontalDistance
│  ├─ Verify it's vertical (horizontalDistance < 30)
│  ├─ Check if exceeds threshold (|verticalDistance| > adjustedThreshold)
│  └─ If YES:
│     ├─ Post "WXKBSwitchLanguage" notification
│     ├─ Play haptic feedback (if enabled)
│     └─ Set hasTriggered = YES
│
├─ touchesEnded or touchesCancelled
│  └─ reset() called (hasTriggered = NO)
│
└─ NSNotificationCenter routes to wxkb_handleLanguageSwitch:
   ├─ Extract direction from userInfo
   ├─ Call wxkb_performLanguageSwitchWithDirection:
   │  ├─ Try Scheme 1: Use cached button (if valid)
   │  ├─ Try Scheme 2: Find by class name
   │  ├─ Try Scheme 3: Recursive keyword search
   │  └─ Try Scheme 4: Call UIViewController methods
   └─ Show visual feedback
```

## 内存管理

### 对象生命周期

```
UIInputView created
    ↓
Associated objects created (via objc_setAssociatedObject)
    ↓ References:
    ├─ gesture (RETAIN)
    ├─ feedbackView (RETAIN)
    ├─ initialized flag (RETAIN)
    └─ observerAttached flag (RETAIN)
    ↓
User interacts → gestures fire → notifications posted
    ↓
UIInputView deallocated
    ↓
In dealloc:
    ├─ Remove observer
    └─ Call %orig
    ↓
Associated objects automatically released
    (because of OBJC_ASSOCIATION_RETAIN policy and view dealloc)
```

### 内存泄漏防护

**潜在泄漏点 1**：通知观察器
- **防护**：在 dealloc 中明确移除

**潜在泄漏点 2**：关联对象
- **防护**：使用 OBJC_ASSOCIATION_RETAIN 自动管理

**潜在泄漏点 3**：全局按钮引用
- **防护**：定期检查 button.window，无效时清空

## 性能分析

### 时间复杂度

| 操作 | 复杂度 | 备注 |
|------|--------|------|
| 手势初始化 | O(1) | 只在 didMoveToWindow 时 |
| 关联对象查找 | O(1) | 直接字典查找 |
| 按钮查找（方案1） | O(1) | 使用缓存 |
| 按钮查找（方案3） | O(n) | 递归遍历视图树 |
| 触摸处理 | O(1) | 简单计算 |

### 空间复杂度

每个 UIInputView 实例约占用：
- 手势识别器：~500 bytes
- 反馈视图：~200 bytes
- 关联对象引用：~100 bytes
- **总计**：~800 bytes per instance

在 Dopamine rootless 环境下通常只有 1 个 UIInputView 活跃，所以内存压力极低。

## 错误处理

### 初始化失败

如果 wxkb_setupGestureRecognizer 异常：
1. 日志会记录错误
2. didMoveToSuperview 会重试
3. 下次显示时再次尝试

### 按钮查找失败

如果 4 个方案都失败：
1. 记录警告日志
2. 返回（不再尝试）
3. 用户需要升级 tweak

### 通知分发失败

如果观察器接收不到通知：
1. 手势仍然检测（touchesMoved 被调用）
2. 通知发送成功（但无接收方）
3. 日志会显示问题

## 扩展性

### 添加新的初始化步骤

在 wxkb_setupGestureRecognizer 的最后添加：

```objc
// 添加新的功能
MyCustomView *customView = [[MyCustomView alloc] initWithFrame:frame];
[self addSubview:customView];
objc_setAssociatedObject(self, kMyCustomViewKey, customView, OBJC_ASSOCIATION_RETAIN);
```

### 添加新的按钮查找策略

在 wxkb_performLanguageSwitchWithDirection 中添加新的方案：

```objc
// 方案 5：新的查找策略
UIButton *newButton = [self myNewFindStrategy];
if (newButton) {
    [newButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    return;
}
```

## 与 Dopamine Rootless 的兼容性

### 关键差异处理

1. **沙箱路径**：使用 `/var/mobile/Library/Preferences/` 而非 `/Library/`
2. **权限**：所有操作都在 SpringBoard 进程内，无权限问题
3. **运行时动态性**：充分利用 Objective-C runtime

### 测试点

- ✅ 键盘显示/隐藏周期
- ✅ 应用切换时的状态保持
- ✅ 长时间使用不泄漏内存
- ✅ 并发访问的线程安全

## 版本迁移

### 从 v2.x 升级

配置文件完全兼容，无需修改。用户体验完全相同。

### 代码重用

如果需要在其他项目中使用类似的设计：

1. 复制关联对象的键定义
2. 复制 wxkb_setupGestureRecognizer 的框架
3. 根据需要调整初始化逻辑

## 总结

v3.0 采用了成熟的 Objective-C runtime 特性，结合多重初始化和完善的错误恢复机制，实现了一个可靠、高效、可扩展的架构。这个设计模式可以应用于其他需要生命周期管理的 Theos tweaks。
