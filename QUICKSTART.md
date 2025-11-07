# 🚀 快速入门指南

> 老王我知道你们懒得看长篇大论的README，所以写了这个快速指南！

## 📋 前置条件检查

在开始之前，确保你有：

- ✅ 一台已越狱的iPhone（rootless越狱，iOS 13+）
- ✅ 已安装微信输入法
- ✅ 一台Mac/Linux电脑（用于编译）
- ✅ 已安装Theos开发环境

## ⚡ 5分钟快速编译

### 步骤1：设置Theos环境

```bash
# 如果还没安装Theos，执行：
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 设置环境变量（添加到~/.bashrc或~/.zshrc）
export THEOS=/opt/theos
export PATH=$THEOS/bin:$PATH
```

### 步骤2：编译插件

```bash
# 进入项目目录
cd WXKBTweak

# 给脚本执行权限
chmod +x build.sh debug.sh

# 一键编译（老王的傻瓜式脚本）
./build.sh
```

### 步骤3：安装到设备

```bash
# 方法A：自动安装（推荐）
export THEOS_DEVICE_IP=你的设备IP
export THEOS_DEVICE_PORT=22
make install

# 方法B：手动安装
scp packages/*.deb root@设备IP:/tmp/
ssh root@设备IP
dpkg -i /tmp/com.laowang.wxkbtweak_*.deb
sbreload
```

## 🎮 使用方法

1. **打开任意App**，调出微信输入法
2. **向上滑动键盘** → 切换到英文 🔤
3. **向下滑动键盘** → 切换到中文 🀄️

就这么简单！艹，老王我设计得真tm人性化！

## ⚙️ 调整设置

打开 **设置 → WXKBTweak**，可以调整：

| 设置项 | 说明 | 推荐值 |
|--------|------|--------|
| 启用插件 | 总开关 | ✅ 开启 |
| 滑动阈值 | 需要滑动的距离 | 40-60 |
| 灵敏度 | 触发的灵敏程度 | 1.0-1.5 |
| 震动反馈 | 切换时震动 | ✅ 开启 |
| 视觉提示 | 显示切换提示 | ✅ 开启 |

## 🐛 遇到问题？

### 问题：插件不工作
```bash
# 查看日志
./debug.sh 你的设备IP

# 或者手动查看
ssh root@设备IP "tail -f /var/log/syslog | grep WXKBTweak"
```

### 问题：切换没反应
1. 降低"滑动阈值"到30
2. 提高"灵敏度"到1.5
3. 确保在微信输入法中使用

### 问题：经常误触
1. 提高"滑动阈值"到70
2. 降低"灵敏度"到0.8

## 📱 测试清单

安装后，测试这些场景：

- [ ] 在微信聊天中切换
- [ ] 在Safari搜索框中切换
- [ ] 在备忘录中切换
- [ ] 快速连续滑动
- [ ] 单手操作

## 🔧 高级：自定义切换逻辑

如果默认的切换逻辑不工作，需要逆向分析微信输入法：

```bash
# 1. 导出微信输入法的类信息
ssh root@设备IP
class-dump /var/containers/Bundle/Application/*/微信输入法.app/wxkb_plugin > /tmp/wxkb.h
exit

# 2. 下载到本地
scp root@设备IP:/tmp/wxkb.h ./

# 3. 查找切换相关的方法
grep -i "switch\|toggle\|language\|input" wxkb.h

# 4. 修改Tweak.x中的performLanguageSwitchWithDirection方法
```

## 💡 使用技巧

1. **最佳滑动位置**：空格键区域
2. **最佳滑动方式**：轻轻一划即可
3. **避免误触**：打字时手指不要在键盘上滑动
4. **快速切换**：可以连续滑动快速切换

## 📞 需要帮助？

- 📖 详细文档：查看 [README.md](README.md)
- 🐛 报告问题：提交Issue
- 💬 联系老王：虽然我暴躁，但会认真回复

---

**老王提醒：第一次使用建议开启所有反馈选项，熟悉后可以根据喜好调整！**

艹，就这么简单！赶紧试试吧！🚀
