# 修复总结 - WXKBTweak v3.1

## 修复的问题

### 问题 1: 点击被误判为滑动
**原因分析**：
- 原来的手势检测逻辑过于简单，只检测垂直移动距离是否超过阈值
- 没有考虑时间因素，快速点击时的轻微抖动会被误判为滑动
- 没有设置最小移动距离门槛

**解决方案**：
1. **添加最小移动距离检测**（15像素）：防止轻微的手指抖动被识别
2. **添加垂直/水平比例检测**：垂直距离必须大于水平距离的2倍，确保是真正的垂直滑动
3. **添加时间和距离综合判断**：在`touchesEnded`中检测，如果时间<0.2秒且距离<20像素，判定为点击
4. **添加总移动距离门槛**：必须移动超过20像素才标记为滑动手势
5. **限制水平偏移**：水平距离不能超过50像素，防止斜着滑动被识别

**代码改进**：
```objective-c
// 新增属性
@property (nonatomic, assign) BOOL isSwipeDetected;
@property (nonatomic, assign) NSTimeInterval startTime;

// 在touchesBegan记录开始时间
self.startTime = [[NSDate date] timeIntervalSince1970];

// 在touchesMoved中多重检测
CGFloat totalDistance = sqrt(pow(verticalDistance, 2) + pow(horizontalDistance, 2));
if (totalDistance < 15.0) return;  // 最小移动门槛
if (absVerticalDistance < horizontalDistance * 2.0) return;  // 垂直角度检测
if (horizontalDistance > 50.0) return;  // 水平距离限制

// 在touchesEnded中验证
if (duration < 0.2 && totalDistance < 20.0) {
    self.isSwipeDetected = NO;  // 判定为点击
}
```

---

### 问题 2: 上下滑动键盘切换中英文功能失效
**原因分析**：
- 原来的实现只在`UIInputView`级别hook，太底层了
- 查找语言切换按钮的时机和位置不准确
- 没有充分利用微信输入法自己的API

**解决方案（基于逆向分析报告）**：

#### 1. 添加更高层级的Hook点
根据逆向报告，添加了对微信输入法核心类的hook：

**WBKeyboardView**（最重要的hook点）：
- 这是微信键盘的主视图
- 在此处添加手势识别器，更精确地捕获滑动
- 实现了直接查找和触发语言切换按钮的逻辑

**WBMainInputView**：
- 微信主输入视图
- 在此处提前查找并保存`WBLanguageSwitchButton`实例

**WBKeyView**：
- 微信按键视图
- 添加了对WeChat原生滑动方法的监控（`swipeUpBegan`, `swipeDownEnded`等）
- 用于诊断和调试

#### 2. 使用API级别的触发方法
根据逆向报告，`WBLanguageSwitchButton`类有`languageSelectClicked`方法：

```objective-c
// 优先级1: 直接调用languageSelectClicked
if ([button respondsToSelector:@selector(languageSelectClicked)]) {
    [button performSelector:@selector(languageSelectClicked)];
}
```

#### 3. 模拟真实的按钮点击
如果API方法不存在，使用更完整的触摸事件模拟：

```objective-c
- (void)wxkb_simulateTouchOnButton:(UIButton *)button {
    // 发送完整的触摸事件序列
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
    
    // 设置高亮状态
    [button setHighlighted:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [button setHighlighted:NO];
    });
}
```

#### 4. 多层次查找语言切换按钮
实现了三个查找时机：
1. **WBLanguageSwitchButton初始化时**：在`initWithFrame`和`didMoveToWindow`中保存
2. **WBMainInputView显示时**：主动查找并保存按钮
3. **触发切换时动态查找**：在WBKeyboardView中实时查找

#### 5. 添加通知机制
在`WBKeyboardView`中添加了通知观察器：
```objective-c
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(wxkb_handleKeyboardSwipe:)
                                             name:@"WXKBSwitchLanguage"
                                           object:nil];
```

---

## 技术改进

### 1. 更准确的手势识别
- 使用欧几里得距离计算总移动距离
- 考虑时间因素（防止快速点击误判）
- 使用角度检测（垂直距离必须远大于水平距离）

### 2. 更可靠的按钮查找
- 多时机查找：初始化时、显示时、触发时
- 多层级查找：WBLanguageSwitchButton、WBMainInputView、WBKeyboardView
- 线程安全：使用NSLock保护全局按钮引用

### 3. 更强大的触发机制
- 优先使用API方法（`languageSelectClicked`）
- 备用完整的触摸事件模拟
- 包含视觉反馈（高亮状态）

### 4. 更好的调试支持
- 添加了对WeChat原生滑动方法的监控
- 详细的NSLog输出
- 清晰的执行流程追踪

---

## 架构改进

### Hook层级（从高到低）
```
WBLanguageSwitchButton (按钮本身)
    ↓
WBMainInputView (主输入视图) - 查找和保存按钮
    ↓
WBKeyboardView (键盘视图) - 添加手势+触发切换
    ↓
WBKeyView (按键视图) - 监控原生滑动
    ↓
UIInputView (基础视图) - 备用hook点
```

### 执行流程
```
用户滑动
    ↓
WXKBSwipeGestureRecognizer 检测滑动
    ↓
发送通知: WXKBSwitchLanguage
    ↓
WBKeyboardView 接收通知
    ↓
wxkb_triggerLanguageSwitch
    ↓
查找 globalLanguageSwitchButton
    ↓
调用 languageSelectClicked 或模拟点击
    ↓
切换中英文输入法
```

---

## 测试建议

### 测试场景1: 点击测试
1. 快速点击键盘上的按键
2. 验证不会误触发语言切换
3. 查看日志中是否有"检测到点击事件（非滑动）"

### 测试场景2: 滑动测试
1. 在键盘上缓慢垂直上滑（≥50像素）
2. 应该触发语言切换
3. 应该有震动反馈

### 测试场景3: 斜向滑动
1. 斜着滑动（水平移动较大）
2. 不应该触发语言切换

### 测试场景4: 短距离滑动
1. 滑动距离<50像素
2. 不应该触发语言切换

### 日志关键词
- ✅ "找到按钮"
- ✅ "调用languageSelectClicked"
- ✅ "手势检测成功"
- ⚠️ "检测到点击事件"
- 🔥 "WBKeyView.swipeUpBegan" (如果WeChat有原生滑动)

---

## 与逆向报告的对应关系

### 报告中的关键发现 → 实现
1. **WBLanguageSwitchButton.languageSelectClicked** → 优先调用此方法
2. **WBKeyboardView** → 添加了完整的hook和手势
3. **WBMainInputView** → 在显示时查找按钮
4. **WBKeyView的滑动方法** → 添加了监控hooks
5. **多层拦截策略** → 实现了三层查找机制

---

## 版本信息

- **版本**: v3.1
- **主要改动**: 修复滑动误判 + API级别触发
- **兼容性**: iOS 13.0+, rootless越狱
- **测试状态**: 待在真机测试

---

## 后续优化建议

1. 如果`languageSelectClicked`方法不工作，可以尝试：
   - 使用`objc_msgSend`直接调用
   - 查找其他可能的API方法
   - 使用KVO监控按钮状态变化

2. 可以添加配置选项：
   - 点击/滑动判定的时间阈值
   - 垂直/水平距离比例
   - 最小移动距离

3. 性能优化：
   - 缓存视图查找结果
   - 减少不必要的递归查找
   - 优化日志输出

---

**作者**: 老王  
**日期**: 2025  
**基于**: REVERSE_ENGINEERING_REPORT.md 的深度逆向分析
