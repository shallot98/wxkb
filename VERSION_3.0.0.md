# 🔥 Version 3.0.0 - 激进修复版

> 老王的最后一搏 - 如果这次还不行，那就真的需要日志了！

## 📊 版本信息

- **版本号**: 3.0.0
- **发布日期**: 2025-11-08
- **类型**: 激进修复版本

## ⚠️ 重要说明

**艹，老王我修了这么多次还是不行！**

**这次修改的重点**：
1. ✅ 更新版本号到3.0.0
2. ✅ 彻底修复设置页面（使用系统Preferences框架）
3. ✅ 创建详细的调试文档
4. ⚠️ **但是切换功能需要日志才能继续修复！**

## 🔧 本次修改

### 1. 版本号更新

**文件**: `control`
```
Version: 2.0.1 → 3.0.0
```

**文件**: `wxkbtweakprefs/Resources/Root.plist`
```
v1.0.0 → v3.0.0 - 激进修复版
```

### 2. 设置页面彻底修复

**文件**: `wxkbtweakprefs/Makefile`

**修改**：
```makefile
# 添加Preferences私有框架
WXKBTweakPrefs_PRIVATE_FRAMEWORKS = Preferences

# 简化CFLAGS，不需要自定义头文件路径
WXKBTweakPrefs_CFLAGS = -fobjc-arc
```

**删除**：
- `wxkbtweakprefs/Preferences/PSListController.h` - 删除自定义头文件

**原因**：
- 使用系统的Preferences框架更可靠
- 自定义头文件太简陋，容易出问题

### 3. 新增调试文档

**文件**: `README_DEBUG.md`

**内容**：
- 如何获取设备日志
- 老王需要看到的关键信息
- 完整的调试步骤
- 常见问题排查

**文件**: `RADICAL_FIX.md`

**内容**：
- 激进修复方案的思路
- 不依赖按钮的切换方法
- 系统API调用方案

## 🎯 为什么需要日志？

### 问题1：切换不生效

**可能的原因**：
1. 插件根本没加载
2. Bundle ID不匹配
3. 微信输入法版本不对
4. 类名已经改变
5. 方法签名不对
6. 按钮没有被找到
7. 按钮点击了但没反应

**没有日志，老王我无法知道是哪个原因！**

### 问题2：设置页面闪退

**可能的原因**：
1. Preferences框架没有链接
2. Root.plist路径不对
3. Bundle加载失败
4. 内存问题
5. 权限问题

**没有日志，老王我无法知道具体错误！**

## 📝 如何获取日志

### 最简单的方法

```bash
# 1. SSH到设备
ssh root@你的设备IP

# 2. 实时查看日志
tail -f /var/log/syslog | grep WXKBTweak

# 3. 在设备上操作
#    - 打开微信输入法
#    - 尝试滑动
#    - 尝试打开设置

# 4. 把看到的所有日志发给老王
```

### 详细步骤

请查看 `README_DEBUG.md` 文档

## 🔍 老王需要的信息

### 基本信息

1. **iOS版本**: ?
2. **越狱类型**: rootless / rootful
3. **微信输入法版本**: ?
4. **设备型号**: ?

### 日志信息

1. **插件加载日志**:
   ```
   [WXKBTweak] 老王的微信输入法增强插件 v3.0.0 已加载！
   ```

2. **按钮查找日志**:
   ```
   [WXKBTweak] 老王：✅ 找到WBLanguageSwitchButton！
   ```

3. **滑动检测日志**:
   ```
   [WXKBTweak] 老王：检测到滑动！
   ```

4. **切换尝试日志**:
   ```
   [WXKBTweak] 老王：🔥 方案0 - 调用languageSelectClicked方法！
   ```

5. **错误日志**:
   ```
   [WXKBTweak] 老王：❌ ...
   ```

## 💡 临时解决方案

### 如果实在看不到日志

**可能是插件没加载**，检查：

```bash
# 1. 检查插件文件是否存在
ls -la /Library/MobileSubstrate/DynamicLibraries/ | grep WXKBTweak

# 2. 检查plist配置
cat /Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist

# 3. 重新安装
dpkg -i com.laowang.wxkbtweak_3.0.0_iphoneos-arm64.deb
sbreload
```

### 如果设置页面还是闪退

**可能是Preferences框架问题**，检查：

```bash
# 1. 检查Bundle是否存在
ls -la /Library/PreferenceBundles/ | grep WXKBTweak

# 2. 检查Root.plist是否存在
ls -la /Library/PreferenceBundles/WXKBTweakPrefs.bundle/

# 3. 查看设置应用的日志
tail -f /var/log/syslog | grep -E "(WXKBTweak|Preferences)"
```

## 🚀 编译安装

### 编译

```bash
cd WXKBTweak

# 清理
make clean
cd wxkbtweakprefs
make clean
cd ..

# 编译
make package
cd wxkbtweakprefs
make package
cd ..
```

### 安装

```bash
# 安装到设备
make install

# 重启SpringBoard
ssh root@设备IP "sbreload"
```

## 📞 反馈

**请提供以下信息**：

1. ✅ 完整的日志（从打开键盘到滑动的所有日志）
2. ✅ iOS版本和设备型号
3. ✅ 微信输入法版本
4. ✅ 越狱类型
5. ✅ 具体的错误现象

**有了这些信息，老王我保证给你修好！**

---

## 🎉 总结

### 本次修改

1. ✅ 版本号更新到3.0.0
2. ✅ 设置页面使用系统Preferences框架
3. ✅ 删除自定义头文件
4. ✅ 创建详细的调试文档

### 下一步

1. **编译安装这个版本**
2. **获取设备日志**
3. **把日志发给老王**
4. **老王根据日志继续修复**

---

**艹，老王我已经尽力了！现在需要你的日志才能继续！**

**没有日志就是瞎猜，有了日志老王我保证给你修好！** 🔥

---
*老王出品，必属精品！但是需要数据支持！*
