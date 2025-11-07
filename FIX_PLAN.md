# 🔧 WXKBTweak 彻底修复计划

> 老王的完整修复方案 - 基于深度逆向分析

## 📊 问题分析

### 问题1：切换不生效 ❌
**现象**：
- 有震动反馈 ✅
- 有视觉提示 ✅
- 但键盘不切换 ❌

**根本原因**：
- 之前的代码只是**猜测**可能的方法名
- 没有找到真正的切换按钮或API
- 日志显示所有4个方案都失败了

### 问题2：设置页面闪退 ❌
**现象**：
- 点击设置立即闪退

**可能原因**：
- PSListController头文件路径错误
- Root.plist文件路径问题
- 缺少必要的框架依赖

## 🔍 深度分析发现

老王我通过分析wxkb_plugin找到了：

### 确认存在的类：
```objective-c
WBLanguageSwitchButton      // 语言切换按钮
WBLanguageSwitchView        // 语言切换视图
WBVoiceinputLanguageSwitchView  // 语音输入语言切换视图
```

### 确认存在的方法：
```objective-c
setInputMode                // 设置输入模式
setKeyboardMode             // 设置键盘模式
switchToFunc                // 切换到功能
toggleFunc                  // 切换功能
switchEngineSession         // 切换引擎会话
switchPanelView             // 切换面板视图
```

### 关键属性：
```objective-c
languageSwitchView          // 语言切换视图属性
_languageSwitchView         // 私有语言切换视图
setLanguageSwitchView:      // 设置语言切换视图
```

## 🎯 修复策略

### 策略1：直接操作WBLanguageSwitchButton

**原理**：找到真正的WBLanguageSwitchButton实例并点击

**实现**：
```objective-c
// 1. Hook WBLanguageSwitchButton的init方法，保存实例
%hook WBLanguageSwitchButton
static WBLanguageSwitchButton *sharedButton = nil;

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        sharedButton = self;
        NSLog(@"[WXKBTweak] 找到WBLanguageSwitchButton: %p", self);
    }
    return self;
}

+ (WBLanguageSwitchButton *)sharedButton {
    return sharedButton;
}
%end

// 2. 在切换时直接调用
[WBLanguageSwitchButton sharedButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
```

### 策略2：通过languageSwitchView属性访问

**原理**：很多类可能有languageSwitchView属性

**实现**：
```objective-c
// 查找有languageSwitchView属性的对象
UIViewController *vc = [self findInputViewController];
if ([vc respondsToSelector:@selector(languageSwitchView)]) {
    id switchView = [vc performSelector:@selector(languageSwitchView)];
    // 从switchView中找到按钮
}
```

### 策略3：监听UITextInputCurrentInputModeDidChangeNotification

**原理**：系统会发送输入模式改变的通知

**实现**：
```objective-c
// 不是主动切换，而是触发系统的切换机制
[[NSNotificationCenter defaultCenter] postNotificationName:@"UITextInputCurrentInputModeDidChangeNotification"
                                                    object:nil];
```

### 策略4：调用setInputMode方法

**原理**：直接设置输入模式

**实现**：
```objective-c
UIViewController *vc = [self findInputViewController];
if ([vc respondsToSelector:@selector(setInputMode:)]) {
    // 需要知道正确的参数
    [vc performSelector:@selector(setInputMode:) withObject:@"en"];
}
```

## 🛠️ 设置页面修复

### 问题分析：
1. PSListController.h路径可能不对
2. Root.plist加载失败
3. 缺少Preferences框架

### 修复方案：

#### 方案1：修复头文件
```objective-c
// WXKBTweakRootListController.h
#import <Preferences/PSListController.h>  // 确保路径正确

@interface WXKBTweakRootListController : PSListController
@end
```

#### 方案2：添加错误处理
```objective-c
- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Root" ofType:@"plist"];
        NSLog(@"[WXKBTweak] Plist路径: %@", plistPath);

        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        } else {
            NSLog(@"[WXKBTweak] Root.plist不存在！");
            _specifiers = @[];
        }
    }
    return _specifiers;
}
```

#### 方案3：检查Makefile
```makefile
# 确保链接了Preferences框架
WXKBTweakPrefs_PRIVATE_FRAMEWORKS = Preferences
```

## 📋 实施步骤

### 第1步：重写Tweak.x核心逻辑
- [ ] 添加WBLanguageSwitchButton的hook
- [ ] 保存按钮实例
- [ ] 重写performLanguageSwitchWithDirection方法
- [ ] 添加更多调试日志

### 第2步：修复设置页面
- [ ] 检查PSListController.h路径
- [ ] 添加详细的错误日志
- [ ] 验证Root.plist路径
- [ ] 检查Makefile配置

### 第3步：测试验证
- [ ] 编译新版本
- [ ] 安装到设备
- [ ] 测试滑动切换
- [ ] 测试设置页面
- [ ] 收集日志分析

## 🎯 预期效果

修复后应该：
1. ✅ 滑动键盘能真正切换中英文
2. ✅ 设置页面不再闪退
3. ✅ 日志清晰显示找到了哪个按钮
4. ✅ 切换成功的提示

## 📝 老王的建议

1. **先修复切换功能** - 这是核心功能
2. **再修复设置页面** - 这是辅助功能
3. **每次只改一个地方** - 方便定位问题
4. **多加日志** - 日志是调试的关键

---

**老王：这次是基于真实的逆向分析，不是瞎猜了！应该能成功！**
