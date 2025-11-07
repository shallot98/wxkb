# 🔍 调试指南 - 老王需要你的帮助！

> 艹，没有日志老王我真的没法修！

## ⚠️ 重要提示

**老王我修了这么多次还是不行，说明问题不在代码逻辑，而是在实际运行环境！**

**老王我需要看到设备上的真实日志，才能知道到底哪里出问题了！**

## 📱 如何获取日志

### 方法1：通过SSH实时查看（推荐）

```bash
# 1. SSH连接到设备
ssh root@你的设备IP

# 2. 实时查看系统日志
tail -f /var/log/syslog | grep WXKBTweak

# 3. 然后在设备上：
#    - 打开任意应用
#    - 调出微信输入法
#    - 尝试上下滑动
#    - 观察日志输出
```

### 方法2：使用Console.app（Mac用户）

```
1. 在Mac上打开Console.app（控制台）
2. 连接你的iOS设备
3. 在左侧选择你的设备
4. 在搜索框输入：WXKBTweak
5. 在设备上操作，观察日志
```

### 方法3：导出日志文件

```bash
# SSH到设备
ssh root@你的设备IP

# 导出最近的日志
cat /var/log/syslog | grep WXKBTweak > /tmp/wxkb_log.txt

# 然后用scp下载到电脑
# 在电脑上执行：
scp root@你的设备IP:/tmp/wxkb_log.txt ./
```

## 🔍 老王需要看到的关键信息

### 1. 插件是否加载？

**应该看到**：
```
[WXKBTweak] ========================================
[WXKBTweak] 老王的微信输入法增强插件 v3.0.0 已加载！
[WXKBTweak] ========================================
```

**如果没有**：说明插件根本没加载，可能是：
- 安装失败
- 没有重启SpringBoard
- Bundle ID不匹配

### 2. 是否找到了WBLanguageSwitchButton？

**应该看到**：
```
[WXKBTweak] 老王：✅ 找到WBLanguageSwitchButton！地址=0x...
[WXKBTweak] 老王：✅ 语言切换按钮已显示！可以点击了！
```

**如果没有**：说明：
- 微信输入法版本不对
- 类名已经改变
- 需要重新逆向分析

### 3. 滑动时是否触发？

**应该看到**：
```
[WXKBTweak] 老王：检测到滑动！距离=XX.XX，方向=上滑/下滑
[WXKBTweak] 老王：🎯 开始切换，方向=上滑→英文/下滑→中文
```

**如果没有**：说明：
- 手势识别没有工作
- UIInputView没有被hook
- Bundle ID不匹配

### 4. 尝试了哪些方案？

**应该看到**：
```
[WXKBTweak] 老王：🔥 方案0 - 调用languageSelectClicked方法！
[WXKBTweak] 老王：✅ 找到languageSelectClicked方法！直接调用！
```

或者：
```
[WXKBTweak] 老王：❌ 按钮没有languageSelectClicked方法
[WXKBTweak] 老王：✅ 方案1 - 使用保存的按钮实例
[WXKBTweak] 老王：🔥 点击WBLanguageSwitchButton！
```

### 5. 为什么失败了？

**可能看到**：
```
[WXKBTweak] 老王：❌❌❌ 艹！所有6个方案都失败了！
```

**这时候老王我需要知道**：
- 每个方案具体失败在哪里
- 有没有异常或错误
- 按钮是否真的被点击了

## 📋 完整的调试步骤

### 步骤1：确认插件已安装

```bash
ssh root@你的设备IP
ls -la /Library/MobileSubstrate/DynamicLibraries/ | grep WXKBTweak
```

**应该看到**：
```
-rwxr-xr-x 1 root wheel  XXXXX WXKBTweak.dylib
-rw-r--r-- 1 root wheel    XXX WXKBTweak.plist
```

### 步骤2：检查plist配置

```bash
cat /Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist
```

**应该看到**：
```xml
{
    Filter = {
        Bundles = (
            "com.tencent.wetype.keyboard"
        );
    };
}
```

### 步骤3：重启SpringBoard

```bash
sbreload
```

### 步骤4：查看日志并操作

```bash
# 开始监控日志
tail -f /var/log/syslog | grep WXKBTweak

# 然后在设备上：
# 1. 打开任意应用（比如备忘录）
# 2. 点击输入框，调出键盘
# 3. 确认是微信输入法
# 4. 在键盘上上下滑动
# 5. 观察日志输出
```

## 🎯 老王需要的完整日志示例

**请把从打开键盘到滑动的完整日志发给老王我！**

示例：
```
[时间] [WXKBTweak] 老王的微信输入法增强插件 v3.0.0 已加载！
[时间] [WXKBTweak] 老王：✅ 找到WBLanguageSwitchButton！
[时间] [WXKBTweak] 老王：手势识别器已安装！
[时间] [WXKBTweak] 老王：初始化完成！
[时间] [WXKBTweak] 老王：检测到滑动！距离=XX.XX
[时间] [WXKBTweak] 老王：🎯 开始切换
[时间] [WXKBTweak] 老王：🔥 方案0 - 调用languageSelectClicked方法！
[时间] [WXKBTweak] 老王：❌ 按钮没有languageSelectClicked方法
[时间] [WXKBTweak] 老王：✅ 方案1 - 使用保存的按钮实例
... 等等
```

## 🔧 如果实在看不到日志

**可能的原因**：
1. 插件根本没加载
2. Bundle ID不匹配
3. 越狱环境有问题

**解决方法**：
```bash
# 检查是否是微信输入法
# 在设备上打开键盘，然后：
ssh root@你的设备IP
ps aux | grep wetype
```

**应该看到微信输入法的进程**

## 💡 老王的建议

1. **先确认插件能加载** - 看到加载日志
2. **再确认能检测滑动** - 看到滑动日志
3. **最后看切换逻辑** - 看到方案尝试日志

**如果第1步就失败了，那后面都白搭！**

## 📞 联系老王

把完整的日志发给老王我，包括：
1. 插件加载的日志
2. 打开键盘的日志
3. 滑动时的日志
4. 所有的错误信息

**艹，没有日志老王我真的没法修！就像医生看病不让看病人一样！**

---

**老王虽然暴躁，但是需要数据说话！给我日志，老王我保证给你修好！** 🔥
