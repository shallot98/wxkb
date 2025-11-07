# 🚀 GitHub Actions 自动编译指南

> 老王教你用GitHub Actions自动编译iOS插件 - 不需要Mac！

## 🎯 为什么用GitHub Actions？

- ✅ **完全免费** - GitHub提供免费的CI/CD服务
- ✅ **不需要Mac** - 在云端自动编译
- ✅ **自动构建** - 每次push代码自动编译
- ✅ **自动发布** - 打tag自动创建Release
- ✅ **随时下载** - 编译好的deb包随时下载

## 📋 前置要求

1. **GitHub账号** - 免费注册
2. **Git基础知识** - 会基本的git命令
3. **项目代码** - 就是这个WXKBTweak项目

## 🚀 快速开始

### 步骤1：创建GitHub仓库

#### 方法A：通过网页创建

1. 登录GitHub
2. 点击右上角 `+` → `New repository`
3. 填写信息：
   - Repository name: `WXKBTweak`
   - Description: `微信输入法增强插件`
   - Public/Private: 选择Public（免费）
4. 点击 `Create repository`

#### 方法B：通过命令行创建

```bash
# 安装GitHub CLI（如果还没安装）
# Windows: winget install GitHub.cli
# Mac: brew install gh

# 登录GitHub
gh auth login

# 创建仓库
gh repo create WXKBTweak --public --description "微信输入法增强插件"
```

### 步骤2：上传代码到GitHub

```bash
# 进入项目目录
cd C:/Users/Administrator/wxkb/WXKBTweak

# 初始化Git仓库（如果还没初始化）
git init

# 添加所有文件
git add .

# 创建第一次提交
git commit -m "feat: 初始提交 - WXKBTweak v2.0.1

- 基于逆向分析的微信输入法增强插件
- 支持上下滑动切换中英文
- 包含完整的GitHub Actions配置

老王出品，必属精品！"

# 添加远程仓库（替换为你的用户名）
git remote add origin https://github.com/你的用户名/WXKBTweak.git

# 推送代码
git branch -M main
git push -u origin main
```

### 步骤3：等待自动编译

1. 推送代码后，GitHub Actions会自动开始编译
2. 访问你的仓库页面
3. 点击 `Actions` 标签
4. 看到正在运行的工作流

**编译过程大约需要5-10分钟**

### 步骤4：下载编译好的deb包

#### 方法A：从Artifacts下载

1. 进入 `Actions` 页面
2. 点击最新的成功构建
3. 滚动到底部，找到 `Artifacts`
4. 点击 `WXKBTweak-xxxxx` 下载
5. 解压zip文件，得到deb包

#### 方法B：从Release下载（推荐）

如果你打了tag，会自动创建Release：

```bash
# 创建tag
git tag -a v2.0.1 -m "Release v2.0.1"
git push origin v2.0.1
```

然后：
1. 访问仓库的 `Releases` 页面
2. 找到最新的Release
3. 直接下载deb包

## 📦 安装编译好的插件

### 在电脑上操作

```bash
# 1. 下载deb包到本地
# 2. 上传到设备
scp com.laowang.wxkbtweak_*.deb root@设备IP:/tmp/

# 3. SSH连接设备
ssh root@设备IP

# 4. 安装
dpkg -i /tmp/com.laowang.wxkbtweak_*.deb

# 5. 重启SpringBoard
sbreload
```

### 在设备上操作（如果有NewTerm）

```bash
# 1. 在设备上用Safari下载deb包
# 2. 用Filza移动到/tmp/
# 3. 打开NewTerm执行：
su root
dpkg -i /tmp/com.laowang.wxkbtweak_*.deb
sbreload
```

## 🔧 自定义配置

### 修改编译触发条件

编辑 `.github/workflows/build.yml`：

```yaml
on:
  push:
    branches: [ main, master, dev ]  # 添加dev分支
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # 手动触发
```

### 修改编译参数

在 `build.yml` 中找到编译步骤：

```yaml
- name: 🔨 编译主插件
  run: |
    make clean
    make package FINALPACKAGE=1 DEBUG=0  # 添加DEBUG=0
```

### 添加编译通知

可以添加Slack、Discord、Email通知：

```yaml
- name: 📧 发送通知
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: '编译完成！'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## 🐛 故障排除

### 问题1：编译失败

**查看日志**：
1. 进入 `Actions` 页面
2. 点击失败的构建
3. 查看详细日志

**常见原因**：
- Makefile配置错误
- 代码语法错误
- 依赖缺失

**解决方案**：
```bash
# 本地先验证代码
./test_logic.sh

# 修复后重新提交
git add .
git commit -m "fix: 修复编译错误"
git push
```

### 问题2：找不到Artifacts

**原因**：
- 编译失败
- 还在编译中
- Artifacts已过期（默认30天）

**解决方案**：
- 等待编译完成
- 检查编译日志
- 重新触发编译

### 问题3：无法下载deb包

**原因**：
- 网络问题
- 仓库是Private（需要登录）

**解决方案**：
```bash
# 使用GitHub CLI下载
gh run download

# 或者使用Release
gh release download v2.0.1
```

## 📊 查看编译状态

### 添加Badge到README

在 `README.md` 顶部添加：

```markdown
![Build Status](https://github.com/你的用户名/WXKBTweak/workflows/Build%20WXKBTweak/badge.svg)
```

效果：显示编译状态徽章 ✅ 或 ❌

### 查看编译历史

```bash
# 使用GitHub CLI
gh run list

# 查看特定运行的详情
gh run view 运行ID
```

## 🎓 进阶技巧

### 1. 多版本编译

编译不同iOS版本的插件：

```yaml
strategy:
  matrix:
    ios_version: ['13.0', '14.0', '15.0']
steps:
  - name: 编译 iOS ${{ matrix.ios_version }}
    run: |
      make package TARGET=iphone:clang:latest:${{ matrix.ios_version }}
```

### 2. 缓存加速

缓存Theos和SDK：

```yaml
- name: 缓存Theos
  uses: actions/cache@v3
  with:
    path: /opt/theos
    key: theos-${{ runner.os }}
```

### 3. 自动测试

添加测试步骤：

```yaml
- name: 运行测试
  run: |
    ./test_logic.sh
```

### 4. 定时构建

每天自动构建：

```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # 每天UTC 0点
```

## 📝 最佳实践

### 1. 提交信息规范

使用Conventional Commits：

```bash
git commit -m "feat: 添加新功能"
git commit -m "fix: 修复bug"
git commit -m "docs: 更新文档"
git commit -m "chore: 更新依赖"
```

### 2. 版本管理

使用语义化版本：

```bash
# 主版本：重大更新
git tag v3.0.0

# 次版本：新功能
git tag v2.1.0

# 修订版本：bug修复
git tag v2.0.2
```

### 3. 分支策略

```
main    - 稳定版本
dev     - 开发版本
feature - 新功能分支
hotfix  - 紧急修复
```

## 🎉 完整工作流程

```bash
# 1. 修改代码
vim Tweak.x

# 2. 本地测试
./test_logic.sh

# 3. 提交代码
git add .
git commit -m "feat: 添加新功能"
git push

# 4. 等待自动编译（5-10分钟）

# 5. 下载deb包
gh run download

# 6. 安装到设备
scp *.deb root@设备IP:/tmp/
ssh root@设备IP "dpkg -i /tmp/*.deb && sbreload"

# 7. 测试功能

# 8. 如果满意，打tag发布
git tag v2.0.2
git push origin v2.0.2

# 9. 自动创建Release
```

## 📞 获取帮助

### GitHub Actions文档
- [官方文档](https://docs.github.com/en/actions)
- [工作流语法](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

### 常见问题
- [Actions FAQ](https://github.com/actions/toolkit/blob/main/docs/action-debugging.md)

### 联系老王
- 虽然我暴躁，但会认真回复

---

## ✅ 检查清单

设置完成后，确认：

- [ ] GitHub仓库已创建
- [ ] 代码已推送
- [ ] Actions已启用
- [ ] 首次编译成功
- [ ] 能下载deb包
- [ ] deb包能正常安装
- [ ] 插件功能正常

**全部完成？恭喜你，自动编译配置成功！** 🎉

---

**老王的话：**

艹，GitHub Actions真tm好用！

不需要Mac，不需要自己配置环境，push代码就自动编译！

老王我给你配置得明明白白的，照着做就行了！

有问题随时问，老王我虽然暴躁但会认真回复！

**祝你编译顺利！** 🚀

---
*老王出品 · 自动编译 · 省时省力*
