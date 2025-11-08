# WXKBTweak 诊断版本使用指南

## 🎯 诊断目标

此诊断版本专门用于解决 WXKBTweak 在 Dopamine rootless 越狱环境下无法输出日志的问题。

## 📋 问题诊断清单

### ✅ 已实现的诊断功能

1. **构造函数诊断** - 确认 tweak 是否被 MobileSubstrate 加载
2. **进程信息诊断** - 显示当前进程名、Bundle ID、进程 ID
3. **Bundle ID 验证** - 检查是否匹配目标进程
4. **配置文件诊断** - 检查偏好设置文件是否存在和可读
5. **Hook 诊断** - 确认 UIInputView hook 是否被调用
6. **手势诊断** - 记录手势开始、移动、触发的详细信息
7. **系统环境诊断** - 显示 iOS 版本、设备型号等信息

## 🚀 使用方法

### 1. 构建诊断版本

```bash
# 在项目根目录执行
./build_diagnostic.sh
```

这将构建包含详细诊断日志的 .deb 包。

### 2. 安装到设备

```bash
# 将生成的 .deb 包传输到设备后执行
dpkg -i WXKBTweak_*.deb
```

### 3. 运行诊断工具

```bash
# 在设备上执行
./diagnose_wxkbtweak.sh
```

### 4. 查看实时日志

```bash
# 方法1: 使用专用日志查看工具
./view_logs.sh

# 方法2: 直接使用 log 命令
log stream --predicate 'category contains "WXKBTweak"' --info --debug

# 方法3: 使用 syslog (旧版本)
tail -f /var/log/syslog | grep -i "wxkbtweak"
```

## 📝 日志解读

### 构造函数日志
```
[WXKBTweak] 🚀 WXKBTweak 构造函数开始执行！
[WXKBTweak] 📱 进程诊断:
[WXKBTweak]   - 进程名: wetype
[WXKBTweak]   - Bundle ID: com.tencent.wetype.keyboard
[WXKBTweak]   - 进程ID: 1234
```

**如果看不到这些日志**：
- tweak 未被 MobileSubstrate 加载
- WXKBTweak.plist 配置错误
- 文件安装路径不正确

### Bundle ID 验证日志
```
[WXKBTweak] 🎯 目标验证:
[WXKBTweak]   - 目标Bundle ID: com.tencent.wetype.keyboard
[WXKBTweak]   - 是否匹配: ✅ 是
```

**如果显示"❌ 否"**：
- 微信输入法的实际 Bundle ID 已更改
- 需要更新 WXKBTweak.plist 中的 Filter 配置

### UIInputView Hook 日志
```
[WXKBTweak] 🎹 ===== UIInputView didMoveToWindow 被调用 =====
[WXKBTweak] ✅ Bundle ID匹配，这是微信输入法进程！
[WXKBTweak] 🎉 WXKBTweak初始化完成！
```

**如果看不到这些日志**：
- UIInputView hook 未被调用
- 可能是类名已更改或 hook 失败

### 手势识别日志
```
[WXKBTweak] 👆 手势开始 - 起点: (100.00, 50.00)
[WXKBTweak] 🎯 ===== 手势触发！ =====
[WXKBTweak]   - 方向: 上滑→英文
[WXKBTweak] 📢 发送语言切换通知...
```

**如果看不到这些日志**：
- 手势识别器未正确安装
- 滑动距离未达到阈值
- 手势被其他组件拦截

## 🔧 故障排除

### 问题1: 完全没有日志输出

**可能原因**：
- tweak 未被 MobileSubstrate 加载
- 文件安装路径错误
- plist 配置错误

**解决方案**：
1. 检查文件是否安装在正确位置：
   ```bash
   ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.*
   ```

2. 检查 plist 配置：
   ```bash
   cat /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist
   ```

3. 重启设备后重新测试

### 问题2: 只有构造函数日志，没有 Hook 日志

**可能原因**：
- Bundle ID 不匹配
- UIInputView 类名已更改

**解决方案**：
1. 查看实际的 Bundle ID：
   ```bash
   ps aux | grep wetype
   ```

2. 更新 WXKBTweak.plist 中的 Filter 配置

### 问题3: 有 Hook 日志但没有手势日志

**可能原因**：
- 手势识别器未安装成功
- 滑动阈值设置过高

**解决方案**：
1. 降低滑动阈值（在设置中调整）
2. 尝试更大幅度的滑动
3. 检查是否有其他手势冲突

## 📋 配置文件位置

### rootless 环境
- dylib: `/var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib`
- plist: `/var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist`
- prefs: `/var/jb/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist`

### 传统越狱环境
- dylib: `/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib`
- plist: `/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist`
- prefs: `/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist`

## 🎯 验收标准

- ✅ 构建成功，.deb 包可安装
- ✅ 安装后能在系统日志中看到初始化日志
- ✅ 激活微信输入法时能看到 Bundle ID 验证日志
- ✅ UIInputView hook 被调用时有详细日志
- ✅ 手势操作时有完整的触发日志
- ✅ 日志能清晰显示各环节的执行状态

## 📞 技术支持

如果问题仍然存在，请提供以下信息：

1. 完整的诊断日志输出
2. 设备型号和 iOS 版本
3. 越狱工具和版本
4. 微信和微信输入法版本
5. 安装过程中的任何错误信息

将这些信息提交到 GitHub Issues，以便进一步分析和解决。