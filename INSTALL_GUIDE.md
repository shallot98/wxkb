# 📦 WXKBTweak 安装指南

> 老王的详细安装教程 - 跟着做就不会出错！

## 🎯 前置要求检查

在开始之前，确保你有：

### 必需条件
- ✅ **已越狱的iPhone** (rootless越狱，如Dopamine、palera1n)
- ✅ **iOS 13.0或更高版本**
- ✅ **已安装微信输入法**
- ✅ **SSH访问权限** (用于安装和调试)

### 编译环境（如果需要自己编译）
- ✅ **Mac或Linux系统** (Windows需要WSL)
- ✅ **已安装Theos** ([安装教程](https://theos.dev/docs/installation))
- ✅ **已配置iOS SDK**
- ✅ **已设置设备IP** (THEOS_DEVICE_IP)

## 📥 安装方法

### 方法A：直接安装deb包（推荐）

如果你已经有编译好的deb包：

```bash
# 1. 通过SSH连接到设备
ssh root@你的设备IP
# 默认密码通常是：alpine

# 2. 上传deb包到设备
# 在你的电脑上执行：
scp com.laowang.wxkbtweak_*.deb root@设备IP:/tmp/

# 3. 在设备上安装
ssh root@设备IP
dpkg -i /tmp/com.laowang.wxkbtweak_*.deb

# 4. 重启SpringBoard
sbreload

# 5. 完成！
```

### 方法B：从源码编译安装

#### 步骤1：设置Theos环境

```bash
# 检查Theos是否已安装
echo $THEOS

# 如果没有输出，需要安装Theos
# macOS/Linux:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 设置环境变量（添加到~/.bashrc或~/.zshrc）
export THEOS=/opt/theos
export PATH=$THEOS/bin:$PATH
```

#### 步骤2：配置设备连接

```bash
# 设置设备IP（替换为你的实际IP）
export THEOS_DEVICE_IP=192.168.1.100
export THEOS_DEVICE_PORT=22

# 测试SSH连接
ssh root@$THEOS_DEVICE_IP "echo 连接成功！"
```

#### 步骤3：编译项目

```bash
# 进入项目目录
cd WXKBTweak

# 给脚本执行权限
chmod +x build.sh test_logic.sh debug.sh

# 运行代码验证（可选但推荐）
./test_logic.sh

# 一键编译
./build.sh

# 或者手动编译
make clean
make package FINALPACKAGE=1
```

#### 步骤4：安装到设备

```bash
# 方法1：自动安装（推荐）
make install

# 方法2：手动安装
scp packages/*.deb root@$THEOS_DEVICE_IP:/tmp/
ssh root@$THEOS_DEVICE_IP "dpkg -i /tmp/*.deb && sbreload"
```

## ⚙️ 配置插件

### 1. 打开设置

安装完成后：
1. 打开iPhone的"设置"应用
2. 向下滚动找到"WXKBTweak"
3. 点击进入设置页面

### 2. 调整参数

根据你的使用习惯调整以下参数：

| 设置项 | 说明 | 推荐值 | 调整建议 |
|--------|------|--------|----------|
| **启用插件** | 总开关 | ✅ 开启 | 关闭后插件不工作 |
| **滑动阈值** | 需要滑动的距离 | 40-60 | 经常误触→提高到70<br>不灵敏→降低到30 |
| **灵敏度** | 触发的灵敏程度 | 1.0-1.5 | 太灵敏→降低到0.8<br>不够灵敏→提高到1.5 |
| **震动反馈** | 切换时震动 | ✅ 开启 | 根据个人喜好 |
| **视觉提示** | 显示切换提示 | ✅ 开启 | 建议开启，方便确认 |

### 3. 重启SpringBoard

调整完设置后，点击"重启SpringBoard"按钮使设置生效。

## 🎮 使用方法

### 基本操作

1. **打开任意应用**，调出微信输入法
2. **向上滑动键盘** → 切换到英文 🔤
3. **向下滑动键盘** → 切换到中文 🀄️

### 使用技巧

#### 最佳滑动位置
- ✅ **空格键区域** - 最方便
- ✅ **键盘中央** - 最稳定
- ⚠️ 避免在按键上滑动 - 可能误触

#### 最佳滑动方式
- ✅ **轻轻一划** - 不需要滑很长
- ✅ **垂直滑动** - 保持垂直方向
- ⚠️ 避免斜着滑 - 可能不触发

#### 单手操作
- 用拇指在空格键区域滑动最方便
- 建议降低滑动阈值到30-40

## 🐛 故障排除

### 问题1：插件不工作

**症状**：滑动键盘没有任何反应

**解决方案**：
```bash
# 1. 检查插件是否已安装
ssh root@设备IP "dpkg -l | grep wxkbtweak"

# 2. 检查插件是否加载
ssh root@设备IP "ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/ | grep WXKBTweak"

# 3. 查看系统日志
./debug.sh 设备IP

# 4. 重新安装
make install
```

### 问题2：切换没反应

**症状**：有震动但没有切换

**解决方案**：
1. 降低"滑动阈值"到30
2. 提高"灵敏度"到1.5
3. 确保在微信输入法中使用
4. 查看日志确认是否找到切换按钮

### 问题3：经常误触

**症状**：打字时经常意外切换

**解决方案**：
1. 提高"滑动阈值"到70
2. 降低"灵敏度"到0.8
3. 打字时避免手指在键盘上滑动

### 问题4：编译失败

**症状**：make package报错

**解决方案**：
```bash
# 1. 清理并重新编译
make clean
rm -rf packages/
make package FINALPACKAGE=1

# 2. 检查Theos环境
echo $THEOS
ls $THEOS

# 3. 检查SDK
ls $THEOS/sdks/

# 4. 更新Theos
$THEOS/bin/update-theos
```

### 问题5：安装后无法启动

**症状**：安装后SpringBoard崩溃

**解决方案**：
```bash
# 1. 进入安全模式
# 按住音量键重启设备

# 2. 卸载插件
ssh root@设备IP
dpkg -r com.laowang.wxkbtweak

# 3. 查看崩溃日志
ssh root@设备IP "cat /var/mobile/Library/Logs/CrashReporter/SpringBoard-*.ips"

# 4. 联系老王报告问题
```

## 📊 验证安装

### 检查清单

安装完成后，验证以下内容：

- [ ] 设置中能看到"WXKBTweak"选项
- [ ] 打开微信输入法能看到键盘
- [ ] 上下滑动键盘有震动反馈
- [ ] 屏幕顶部显示"English"或"Chinese"
- [ ] 输入法成功切换

### 查看日志

```bash
# 实时查看插件日志
./debug.sh 设备IP

# 或者手动查看
ssh root@设备IP "tail -f /var/log/syslog | grep WXKBTweak"
```

**期望看到的日志**：
```
[WXKBTweak] 老王的微信输入法增强插件 v2.0 已加载！
[WXKBTweak] 老王：配置加载成功！enabled=1, threshold=50.00
[WXKBTweak] 老王：手势识别器已安装！
[WXKBTweak] 老王：初始化完成！
[WXKBTweak] 老王：检测到滑动！距离=-65.23，方向=上滑
[WXKBTweak] 老王：找到切换按钮！
```

## 🔄 更新插件

### 从旧版本更新

```bash
# 1. 卸载旧版本
ssh root@设备IP "dpkg -r com.laowang.wxkbtweak"

# 2. 安装新版本
make install

# 3. 重启SpringBoard
ssh root@设备IP "sbreload"
```

### 保留设置更新

插件更新时会自动保留你的设置，无需重新配置。

## 🗑️ 卸载插件

如果你想卸载插件：

```bash
# 1. 通过SSH连接设备
ssh root@设备IP

# 2. 卸载插件
dpkg -r com.laowang.wxkbtweak

# 3. 清理配置文件（可选）
rm -f /var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist

# 4. 重启SpringBoard
sbreload
```

## 📞 获取帮助

### 遇到问题？

1. **查看文档**
   - README.md - 完整文档
   - QUICKSTART.md - 快速入门
   - 本文件 - 安装指南

2. **查看日志**
   ```bash
   ./debug.sh 设备IP
   ```

3. **提交Issue**
   - 描述问题
   - 附上日志
   - 说明设备型号和iOS版本

4. **联系老王**
   - 虽然我暴躁，但会认真回复

### 常见问题FAQ

**Q: 支持哪些越狱？**
A: 仅支持rootless越狱（Dopamine、palera1n等），不支持rootful越狱。

**Q: 支持哪些iOS版本？**
A: iOS 13.0及以上版本。

**Q: 支持其他输入法吗？**
A: 目前仅支持微信输入法，其他输入法不工作。

**Q: 会影响其他应用吗？**
A: 不会，插件只在微信输入法中加载。

**Q: 安全吗？**
A: 完全安全，代码开源可审查，不收集任何数据。

## 🎓 进阶使用

### 自定义配置

配置文件位置：
```
/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist
```

可以手动编辑配置：
```bash
ssh root@设备IP
plutil -convert xml1 /var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist
vi /var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist
```

### 开发调试

如果你想修改代码：

1. 修改`Tweak.x`
2. 运行`./test_logic.sh`验证
3. 编译：`make package`
4. 安装：`make install`
5. 查看日志：`./debug.sh 设备IP`

---

## ✅ 安装完成检查表

安装完成后，确认以下所有项目：

- [ ] 插件已成功安装（dpkg -l可以看到）
- [ ] 设置中有WXKBTweak选项
- [ ] 所有设置项都能正常调整
- [ ] 微信输入法能正常使用
- [ ] 上下滑动有震动反馈
- [ ] 视觉提示正常显示
- [ ] 输入法能成功切换
- [ ] 日志输出正常

**全部完成？恭喜你，安装成功！** 🎉

---

**老王的话：**

艹，这个安装指南老王我写得够详细了吧！

从前置要求到故障排除，从基本使用到进阶配置，老王我都给你写清楚了！

如果按照这个指南还装不上，那tm就是你的问题了！😤

不过老王我虽然嘴上骂骂咧咧，但有问题还是可以问的！

**祝你使用愉快！** 🚀

---
*老王出品 · 详细周到 · 包教包会*
