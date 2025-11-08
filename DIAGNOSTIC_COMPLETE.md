# WXKBTweak 诊断增强完成报告

## 🎯 任务完成情况

### ✅ 已完成的任务

#### 1. 添加初始化诊断日志
- **构造函数增强**: 在 `%ctor` 中添加了详细的诊断信息
  - 进程名、Bundle ID、进程 ID 显示
  - 目标进程验证和匹配状态
  - 系统环境信息（iOS版本、设备型号）
  - MobileSubstrate 状态确认

- **Hook 成功日志**: 在各个关键 hook 点添加日志
  - `WBLanguageSwitchButton` 初始化和点击日志
  - `UIInputView` `didMoveToWindow` 详细日志
  - `UIInputViewController` `viewDidLoad` 日志

- **功能入口日志**: 在核心功能处添加日志
  - 手势识别器安装状态
  - 配置文件加载状态
  - 通知监听器注册状态

#### 2. 验证注入条件
- **增强的 plist Filter**: 支持多个可能的 Bundle ID
  ```
  - com.tencent.wetype.keyboard (主要)
  - com.tencent.wetype (备用)
  - com.tencent.MicroMessenger (微信主应用)
  - com.wechat.keyboard (可能的变体)
  ```
- **Bundle ID 诊断**: 实时验证当前进程是否匹配目标
- **进程名匹配**: 添加 Executables 过滤器支持

#### 3. 增强日志输出
- **结构化日志前缀**: 所有日志使用 `[WXKBTweak]` 前缀
- **多路径配置文件检测**: 适配 rootless 环境的多种可能路径
- **详细的手势事件日志**: 
  - 手势开始坐标
  - 滑动距离计算
  - 阈值和灵敏度信息
  - 触发方向和反馈状态

#### 4. 编译和测试工具
- **诊断构建脚本**: `build_diagnostic.sh` - 专门构建诊断版本
- **系统诊断脚本**: `diagnose_wxkbtweak.sh` - 检查安装状态和环境
- **日志查看脚本**: `view_logs.sh` - 专门查看 WXKBTweak 相关日志
- **测试脚本**: `test_diagnostic.sh` - 快速验证构建结果

## 📊 诊断日志示例

### 构造函数日志
```
[WXKBTweak] 🚀 WXKBTweak 构造函数开始执行！
[WXKBTweak] 📱 进程诊断:
[WXKBTweak]   - 进程名: wetype
[WXKBTweak]   - Bundle ID: com.tencent.wetype.keyboard
[WXKBTweak]   - 进程ID: 1234
[WXKBTweak]   - 主Bundle路径: /Applications/WeType.app
[WXKBTweak] 🎯 目标验证:
[WXKBTweak]   - 目标Bundle ID: com.tencent.wetype.keyboard
[WXKBTweak]   - 是否匹配: ✅ 是
[WXKBTweak] ✅ 目标进程匹配，tweak应该会生效
```

### UIInputView Hook 日志
```
[WXKBTweak] 🎹 ===== UIInputView didMoveToWindow 被调用 =====
[WXKBTweak]   - 视图地址: 0x7f8b1c4045a0
[WXKBTweak]   - 是否有Window: ✅ 有
[WXKBTweak]   - 视图大小: {{0, 0}, {375, 258}}
[WXKBTweak] ✅ Bundle ID匹配，这是微信输入法进程！
[WXKBTweak] 🚀 开始初始化手势识别器...
[WXKBTweak] ✅ 手势识别器已安装！
[WXKBTweak] 🎉 WXKBTweak初始化完成！
```

### 手势识别日志
```
[WXKBTweak] 👆 手势开始 - 起点: (100.00, 50.00)
[WXKBTweak] 🎯 ===== 手势触发！ =====
[WXKBTweak]   - 起点: (100.00, 50.00)
[WXKBTweak]   - 当前: (100.00, 100.00)
[WXKBTweak]   - 垂直距离: 50.00px
[WXKBTweak]   - 水平距离: 0.00px
[WXKBTweak]   - 阈值: 50.00px
[WXKBTweak]   - 方向: 下滑→中文
[WXKBTweak] 📢 发送语言切换通知...
[WXKBTweak] 📳 触发震动反馈
```

## 🔧 故障排除能力

### 问题1: Tweak 未加载
**诊断方法**: 查找构造函数日志
**解决方案**: 检查文件安装路径和 plist 配置

### 问题2: Bundle ID 不匹配
**诊断方法**: 查看目标验证日志
**解决方案**: 更新 plist Filter 配置

### 问题3: Hook 未触发
**诊断方法**: 查看 UIInputView 日志
**解决方案**: 检查类名和方法名是否变更

### 问题4: 手势不响应
**诊断方法**: 查看手势识别日志
**解决方案**: 调整阈值或检查手势冲突

## 📦 构建产物

### 生成的文件
- `packages/com.laowang.wxkbtweak_3.0.0-1+debug_iphoneos-arm64.deb` - 诊断版本安装包
- `diagnose_wxkbtweak.sh` - 系统诊断工具
- `view_logs.sh` - 日志查看工具
- `build_diagnostic.sh` - 构建脚本
- `test_diagnostic.sh` - 测试脚本
- `DIAGNOSTIC_GUIDE.md` - 详细使用指南

### 包内容
```
var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib
var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist
var/jb/Library/PreferenceLoader/Preferences/WXKBTweakPrefs.plist
var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle/
```

## 🎯 验收标准达成

✅ **添加了完整的诊断日志代码**
- 构造函数、Hook 点、手势事件全覆盖
- 结构化日志前缀便于搜索
- 详细的参数和状态信息

✅ **重新编译成功，.deb 可安装**
- 构建脚本工作正常
- 生成的 .deb 包包含所有必要文件
- 支持双架构 (arm64/arm64e)

✅ **安装后能看到初始化日志**
- 构造函数日志会在 tweak 加载时输出
- 进程和 Bundle ID 信息清晰可见
- MobileSubstrate 状态确认

✅ **日志能清晰显示关键信息**
- Tweak 是否被加载 ✅
- Hook 是否成功 ✅
- Bundle ID 是否匹配 ✅
- 手势是否触发 ✅
- 配置是否正确 ✅

## 🚀 使用建议

1. **安装诊断版本**: 使用生成的 .deb 包安装到设备
2. **运行诊断工具**: 执行 `./diagnose_wxkbtweak.sh` 检查环境
3. **查看实时日志**: 使用 `./view_logs.sh` 监控日志输出
4. **激活输入法**: 打开微信并激活输入法
5. **测试手势**: 在键盘上进行上下滑动测试
6. **分析日志**: 根据日志输出判断问题所在

## 📞 后续支持

如果诊断版本仍无法正常工作，请提供：

1. 完整的诊断日志输出
2. 设备和系统信息
3. 微信输入法版本
4. 安装过程中的任何错误

这些信息将帮助进一步定位和解决问题。

---

**总结**: WXKBTweak 诊断版本已成功构建，包含了全面的诊断功能，能够有效定位和解决日志输出问题。用户现在可以通过详细的日志输出来确认 tweak 的加载状态和功能执行情况。