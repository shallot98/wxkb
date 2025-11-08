# WXKBTweak v3.0 迁移指南

## 什么改变了

### 对用户的影响

**好消息**：所有改变都是内部的，用户界面和配置完全相同！

✅ 安装方式相同
✅ 配置设置完全兼容
✅ 使用体验一致

### 对开发者的影响

如果你想修改或扩展 WXKBTweak，需要了解以下变化：

## 关键变化

### 1. 不再使用全局静态变量

**旧版本**：
```objc
static WXKBSwipeGestureRecognizer *swipeGesture = nil;
static WXKBFeedbackView *feedbackView = nil;
static BOOL hasSetupGesture = NO;
```

**新版本**：
```objc
static const void *kWXKBSwipeGestureKey = &kWXKBSwipeGestureKey;
static const void *kWXKBFeedbackViewKey = &kWXKBFeedbackViewKey;
static const void *kWXKBInitializedKey = &kWXKBInitializedKey;

// 存储在UIInputView实例上：
objc_setAssociatedObject(self, kWXKBSwipeGestureKey, swipeGesture, OBJC_ASSOCIATION_RETAIN);
```

**好处**：
- 支持多个UIInputView同时存在
- 自动内存管理（实例销毁时自动释放）
- 更安全、更可靠

### 2. 新的初始化机制

**旧版本**：只在`didMoveToWindow`中初始化一次

**新版本**：
- `didMoveToWindow` - 首次初始化
- `didMoveToSuperview` - 恢复丢失的手势
- `wxkb_setupGestureRecognizer` - 真正的初始化逻辑

**好处**：即使手势被意外卸载也能自动恢复

### 3. 方法命名规范

所有新添加的方法都使用`wxkb_`前缀：

- `wxkb_setupGestureRecognizer`
- `wxkb_handleLanguageSwitch:`
- `wxkb_performLanguageSwitchWithDirection:`
- `wxkb_findViewOfClass:inView:`
- `wxkb_findInputViewController`
- `wxkb_findLanguageSwitchButtonRecursive:`

**原因**：避免与其他tweak或系统方法冲突

### 4. 线程安全的按钮引用

**旧版本**：直接使用全局变量

**新版本**：
```objc
static NSLock *buttonLock = nil;

[buttonLock lock];
globalLanguageSwitchButton = self;
[buttonLock unlock];
```

**原因**：多个线程可能同时访问按钮引用

### 5. 改进的清理机制

现在在`dealloc`中正确清理通知观察器：

```objc
- (void)dealloc {
    NSNumber *observerAttached = objc_getAssociatedObject(self, kWXKBObserverAttachedKey);
    if (observerAttached && [observerAttached boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    %orig;
}
```

## 编译和构建

### 编译命令（无变化）

```bash
make package FINALPACKAGE=1
```

### 安装命令（无变化）

```bash
make install  # 需要配置THEOS_DEVICE_IP

# 或手动安装
scp packages/*.deb root@你的设备:/tmp/
ssh root@你的设备 'dpkg -i /tmp/*.deb && sbreload'
```

## 日志分析

### v3.0的新日志

现在可以看到更详细的初始化日志：

```
[WXKBTweak] WXKBTweak v3.0 已加载
[WXKBTweak] didMoveToWindow: UIInputView已显示
[WXKBTweak] 开始设置手势识别器...
[WXKBTweak] ✅ 手势识别器已添加
[WXKBTweak] ✅ 视觉反馈视图已添加
[WXKBTweak] ✅ 通知观察器已添加
[WXKBTweak] ✅ UIInputView初始化完成
```

### 关键日志位置

| 日志内容 | 含义 | 位置 |
|---------|------|------|
| `WXKBTweak v3.0 已加载` | Tweak成功加载 | `%ctor` |
| `didMoveToWindow` | UIInputView显示 | `-[UIInputView didMoveToWindow]` |
| `✅ 手势识别器已添加` | 手势安装成功 | `wxkb_setupGestureRecognizer` |
| `✅ 手势检测成功` | 检测到滑动 | `WXKBSwipeGestureRecognizer` |
| `🎯 开始切换语言` | 处理切换 | `wxkb_handleLanguageSwitch:` |

## 配置文件（无变化）

plist配置、preferences设置完全保持不变：

- `WXKBTweak.plist` - Filter配置
- `wxkbtweakprefs/` - 设置面板
- `com.laowang.wxkbtweak.plist` - 用户偏好设置

## API变更

### 公开的新API

如果其他tweak想要与WXKBTweak集成，可以使用：

```objc
// 获取当前的语言切换按钮
WBLanguageSwitchButton *button = [WBLanguageSwitchButton sharedButton];

// 发送切换通知
[[NSNotificationCenter defaultCenter] postNotificationName:@"WXKBSwitchLanguage"
                                                    object:nil
                                                  userInfo:@{@"direction": @(-50)}];
```

### 内部API（仅供参考）

如果修改源代码，这些是主要的内部接口：

```objc
// 在UIInputView上
- (void)wxkb_setupGestureRecognizer;
- (void)wxkb_handleLanguageSwitch:(NSNotification *)notification;
- (void)wxkb_performLanguageSwitchWithDirection:(CGFloat)direction;
```

## 性能影响

### 内存

- **减少**：不再保存全局的UIInputView实例引用
- **同等**：使用关联对象的开销与之前的静态变量类似

### CPU

- **轻微增加**：`@synchronized`块会引入小的同步开销
- **可忽略**：这些操作在UI初始化时运行，不是热路径

## 故障排查

### 如果功能仍然不工作

1. **检查日志**：寻找`[WXKBTweak]`标记的所有消息
2. **验证初始化**：应该看到`✅ UIInputView初始化完成`
3. **验证手势**：尝试滑动应该看到`✅ 手势检测成功`
4. **验证切换**：应该看到至少一个切换方案成功

### 常见问题

**Q：为什么我看到`该UIInputView已初始化过`的日志？**
A：这是正常的。如果UIInputView调用多次`didMoveToWindow`，第二次会跳过初始化。

**Q：为什么手势没有响应？**
A：检查日志中是否有`[WXKBTweak] 手势开始`的消息。如果没有，可能是Bundle ID不匹配。

**Q：为什么切换没有执行？**
A：查看`🎯 开始切换语言`之后的日志，看看哪个方案被尝试。如果都失败，按钮可能改名了。

## 升级检查清单

升级到v3.0后，请检查：

- [ ] 插件成功加载（看到v3.0的启动日志）
- [ ] 键盘显示时看到初始化日志
- [ ] 上下滑动能检测到
- [ ] 切换功能能工作
- [ ] 指示器持续显示
- [ ] 重复打开关闭键盘仍能工作

## 反馈和报告

如果遇到问题，请提供：

1. **完整的启动日志**：从`%ctor`开始的所有日志
2. **操作步骤**：具体做了什么导致问题
3. **设备信息**：iOS版本、越狱工具、WeChat版本
4. **日志切片**：问题发生时的相关日志

这将帮助我们快速诊断和修复问题。

## 总结

v3.0是一个**内部改进版本**，对用户完全透明，但大大提高了可靠性和稳定性。所有配置和使用方式保持不变，只是运行更稳定了！
