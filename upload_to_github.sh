#!/bin/bash
# 老王的一键上传GitHub脚本
# 艹，这脚本写得真tm方便！

set -e

echo "=========================================="
echo "老王的WXKBTweak一键上传GitHub工具"
echo "=========================================="
echo ""

# 检查是否已经初始化git
if [ ! -d ".git" ]; then
    echo "[1/5] 初始化Git仓库..."
    git init
    git branch -M main
else
    echo "[1/5] Git仓库已存在，跳过初始化"
fi

# 询问GitHub用户名
echo ""
echo "[2/5] 配置GitHub仓库..."
read -p "请输入你的GitHub用户名: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ 用户名不能为空！"
    exit 1
fi

REPO_URL="https://github.com/$GITHUB_USERNAME/WXKBTweak.git"

# 检查是否已添加remote
if git remote | grep -q "origin"; then
    echo "   Remote已存在，更新URL..."
    git remote set-url origin $REPO_URL
else
    echo "   添加Remote..."
    git remote add origin $REPO_URL
fi

echo "   仓库地址: $REPO_URL"

# 添加所有文件
echo ""
echo "[3/5] 添加文件到Git..."
git add .

# 显示将要提交的文件
echo ""
echo "将要提交的文件："
git status --short

# 询问提交信息
echo ""
echo "[4/5] 创建提交..."
read -p "请输入提交信息（直接回车使用默认）: " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="feat: WXKBTweak v2.0.1 - 微信输入法增强插件

- 基于逆向分析的真实类名
- 支持上下滑动切换中英文
- 包含完整的GitHub Actions自动编译配置
- 详细的文档和使用说明

老王出品，必属精品！"
fi

git commit -m "$COMMIT_MSG"

# 推送到GitHub
echo ""
echo "[5/5] 推送到GitHub..."
echo "   正在推送到: $REPO_URL"
echo ""

git push -u origin main

echo ""
echo "=========================================="
echo "✅ 上传成功！"
echo "=========================================="
echo ""
echo "接下来的步骤："
echo ""
echo "1. 访问你的仓库："
echo "   $REPO_URL"
echo ""
echo "2. 点击 'Actions' 标签查看自动编译"
echo ""
echo "3. 等待5-10分钟编译完成"
echo ""
echo "4. 下载编译好的deb包："
echo "   - 从Artifacts下载"
echo "   - 或者打tag创建Release"
echo ""
echo "5. 安装到设备："
echo "   scp *.deb root@设备IP:/tmp/"
echo "   ssh root@设备IP 'dpkg -i /tmp/*.deb && sbreload'"
echo ""
echo "=========================================="
echo ""
echo "老王提醒："
echo "- 首次推送可能需要输入GitHub用户名和密码"
echo "- 建议使用Personal Access Token代替密码"
echo "- 如果推送失败，检查仓库是否已创建"
echo ""
echo "创建仓库："
echo "1. 访问 https://github.com/new"
echo "2. Repository name: WXKBTweak"
echo "3. 选择Public"
echo "4. 不要勾选任何初始化选项"
echo "5. 点击Create repository"
echo ""
echo "艹，GitHub Actions真tm好用！"
