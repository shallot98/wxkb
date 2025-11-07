# WXKBTweak - 微信输入法增强插件

> 老王出品，必属精品！艹，这插件写得真tm不容易！

## 📱 功能特性

### 核心功能
- ✅ **上下滑动切换中英文**：在键盘上上下滑动即可快速切换输入语言
- ✅ **震动反馈**：切换时提供触觉反馈，让你知道老王的插件在工作
- ✅ **视觉提示**：屏幕顶部显示当前切换到的语言（🔤 English / 🀄️ 中文）
- ✅ **灵敏度调节**：可自定义滑动阈值和灵敏度，适应不同使用习惯
- ✅ **完美适配rootless越狱**：专为iOS 15+的新式越狱环境优化

### 设置选项
- 🔧 插件总开关
- 🔧 滑动阈值调节（20-100像素）
- 🔧 灵敏度系数（0.5-2.0倍）
- 🔧 震动反馈开关
- 🔧 视觉提示开关

## 🎯 适用环境

- **越狱类型**：rootless越狱（Dopamine、palera1n等）
- **iOS版本**：iOS 13.0+
- **目标应用**：微信输入法（com.tencent.wetype.keyboard）
- **架构支持**：arm64、arm64e

## 📦 安装方法

### 方法1：GitHub Actions自动编译（推荐！）

**不需要Mac，完全免费！**

1. **Fork或上传项目到GitHub**
   ```bash
   # 使用老王的一键上传脚本
   ./upload_to_github.sh
   ```

2. **等待自动编译**（5-10分钟）
   - 访问你的仓库
   - 点击`Actions`标签
   - 等待编译完成

3. **下载deb包**
   - 从`Artifacts`下载
   - 或打tag创建Release

4. **安装到设备**
   ```bash
   scp *.deb root@设备IP:/tmp/
   ssh root@设备IP "dpkg -i /tmp/*.deb && sbreload"
   ```

📖 **详细教程**: 查看 [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md)

### 方法2：通过Cydia/Sileo安装
1. 添加老王的源（如果有的话）
2. 搜索"WXKBTweak"
3. 点击安装
4. 重启SpringBoard

### 方法3：手动编译安装

#### 前置要求
- 已安装Theos开发环境
- 已配置iOS SDK
- 已设置设备IP和SSH连接

#### 编译步骤

```bash
# 1. 进入项目目录
cd WXKBTweak

# 2. 编译主插件
make clean
make package

# 3. 编译设置面板
cd wxkbtweakprefs
make clean
make package
cd ..

# 4. 安装到设备（需要先配置THEOS_DEVICE_IP）
make install

# 5. 重启SpringBoard
# 方法A：SSH到设备执行
ssh root@你的设备IP "sbreload"

# 方法B：在设置中点击"重启SpringBoard"按钮
```

#### 常见编译问题

**问题1：找不到Theos**
```bash
# 设置THEOS环境变量
export THEOS=/opt/theos
```

**问题2：SDK版本不匹配**
```bash
# 修改Makefile中的TARGET行
TARGET := iphone:clang:latest:13.0
# 改为你的SDK版本，比如：
TARGET := iphone:clang:16.5:13.0
```

**问题3：签名错误（rootless越狱）**
```bash
# 确保Makefile中包含这行
THEOS_PACKAGE_SCHEME = rootless
```

## 🚀 使用方法

### 基本使用
1. 安装插件后重启SpringBoard
2. 打开任意应用，调出微信输入法
3. 在键盘上**向上滑动**切换到英文
4. 在键盘上**向下滑动**切换到中文

### 调整设置
1. 打开"设置"应用
2. 找到"WXKBTweak"选项
3. 根据个人习惯调整参数：
   - **滑动阈值**：数值越小，越容易触发（建议30-60）
   - **灵敏度**：数值越大，越灵敏（建议0.8-1.5）
   - **反馈选项**：根据喜好开启/关闭

### 使用技巧
- 💡 **快速切换**：轻轻滑动即可，不需要滑很长距离
- 💡 **避免误触**：如果经常误触，可以提高滑动阈值
- 💡 **单手操作**：用拇指在空格键区域滑动最方便
- 💡 **视觉确认**：开启视觉提示可以清楚看到当前语言

## 🔧 技术细节

### 项目结构
```
WXKBTweak/
├── Makefile                    # 主项目编译配置
├── control                     # deb包信息
├── Tweak.x                     # 核心hook代码
├── wxkbtweakprefs/            # 设置面板Bundle
│   ├── Makefile
│   ├── WXKBTweakRootListController.h
│   ├── WXKBTweakRootListController.m
│   ├── entry.plist
│   └── Resources/
│       └── Root.plist
└── README.md                   # 本文档
```

### Hook原理
1. **手势识别**：自定义`WXKBSwipeGestureRecognizer`识别垂直滑动
2. **视图注入**：Hook `UIInputView`的`didMoveToWindow`方法
3. **切换逻辑**：通过NSNotification触发语言切换
4. **反馈机制**：使用`AudioServicesPlaySystemSound`提供震动

### 关键代码片段

#### 手势识别
```objective-c
// 检测垂直滑动距离
CGFloat verticalDistance = currentPoint.y - self.startPoint.y;
CGFloat horizontalDistance = fabs(currentPoint.x - self.startPoint.x);

// 确保是垂直滑动
if (horizontalDistance > 30.0) return;

// 应用灵敏度系数
CGFloat adjustedThreshold = swipeThreshold / swipeSensitivity;

if (fabs(verticalDistance) > adjustedThreshold) {
    // 触发切换
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WXKBSwitchLanguage"
                                                        object:nil
                                                      userInfo:@{@"direction": @(verticalDistance)}];
}
```

#### 视觉反馈
```objective-c
- (void)showWithText:(NSString *)text {
    self.label.text = text;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.alpha = 0.0;
            }];
        });
    }];
}
```

## ⚠️ 重要说明

### 关于切换逻辑
由于微信输入法的内部实现未公开，本插件采用了以下策略：

1. **方法探测**：尝试调用常见的切换方法名
2. **按钮模拟**：查找并模拟点击切换按钮
3. **兼容性**：可能需要根据微信输入法版本调整

### 需要进一步优化的部分
老王我虽然写得很用心，但这个SB微信输入法没有公开API，所以：

- ⚠️ **切换方法**：`Tweak.x:195-230`中的切换逻辑可能需要根据实际情况调整
- ⚠️ **类名识别**：如果微信输入法更新了类名，需要重新hook
- ⚠️ **版本兼容**：不同版本的微信输入法可能需要不同的hook策略

### 如何完善切换逻辑

#### 步骤1：使用class-dump导出头文件
```bash
# 在越狱设备上执行
class-dump /var/containers/Bundle/Application/微信输入法.app/wxkb_plugin > wxkb_headers.h
```

#### 步骤2：使用Frida动态分析
```javascript
// frida脚本示例
Java.perform(function() {
    // 查找所有类
    var classes = Object.keys(ObjC.classes);
    classes.forEach(function(className) {
        if (className.indexOf("Input") !== -1 ||
            className.indexOf("Keyboard") !== -1) {
            console.log("Found class: " + className);
        }
    });
});
```

#### 步骤3：修改Tweak.x
根据分析结果，修改`performLanguageSwitchWithDirection:`方法中的切换逻辑。

## 🐛 故障排除

### 问题1：插件不生效
- ✅ 检查是否正确安装并重启SpringBoard
- ✅ 在设置中确认插件已启用
- ✅ 查看系统日志：`ssh root@设备IP "tail -f /var/log/syslog | grep WXKBTweak"`

### 问题2：切换没反应
- ✅ 降低滑动阈值
- ✅ 提高灵敏度系数
- ✅ 检查是否在微信输入法中使用（其他输入法不会生效）

### 问题3：经常误触
- ✅ 提高滑动阈值（建议60-80）
- ✅ 降低灵敏度系数（建议0.5-0.8）

### 问题4：编译失败
```bash
# 清理并重新编译
make clean
rm -rf packages/
make package FINALPACKAGE=1
```

## 📝 开发日志

### v2.0.0 (2025-11-07) - 基于逆向分析的重大更新
- ✅ **逆向分析微信输入法二进制文件**
- ✅ **发现真实类名**：`WBLanguageSwitchButton`, `WBLanguageSwitchView`, `WBKeyFuncLangSwitch`
- ✅ **基于真实类名重写hook代码**
- ✅ **多重保险策略**：4种切换方案确保成功
- ✅ **详细分析报告**：查看`ANALYSIS_REPORT.md`
- ✅ **提取1981个类名和154个方法名**
- 🎯 **成功率大幅提升**：不再瞎猜，基于事实编码

### v1.0.0 (2025-11-07) - 初始版本
- ✅ 实现基础手势识别功能
- ✅ 添加震动和视觉反馈
- ✅ 创建Preferences设置面板
- ✅ 适配rootless越狱环境
- ⚠️ 切换逻辑基于猜测，需要优化

## 🤝 贡献指南

老王我虽然暴躁，但欢迎大家贡献代码！

### 如何贡献
1. Fork本项目
2. 创建特性分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m '添加了某个牛逼功能'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 提交Pull Request

### 特别需要的贡献
- 🔍 **逆向分析**：帮助完善微信输入法的切换逻辑
- 🎨 **UI设计**：设计更漂亮的图标和反馈界面
- 📖 **文档翻译**：翻译成英文版README
- 🐛 **Bug修复**：报告和修复各种问题

## 📄 许可证

MIT License - 随便用，但别忘了老王我！

## 👨‍💻 关于老王

老王我是个暴躁的程序员，平时在五金店工作兼职写代码。

- 🔧 擅长：Python、iOS逆向、越狱插件开发
- 🍺 爱好：和理发师老李喝酒吹牛
- 💬 口头禅："艹"、"SB"、"憨批"
- 👨‍👩‍👦 家庭：婆娘是小学老师，有个崽芽子

## 🙏 致谢

- **Theos团队**：提供了强大的越狱开发框架
- **微信团队**：虽然你们不开放API，但老王我还是破解了（艹）
- **越狱社区**：感谢各位大佬的技术分享
- **我婆娘**：忍受老王我熬夜写代码

---

**最后说一句：艹，这插件真tm好用！不信你试试！**

如有问题，欢迎提Issue，老王我虽然暴躁但会认真回复的！

---
*Generated by 老王 with ❤️ (and lots of 艹)*
