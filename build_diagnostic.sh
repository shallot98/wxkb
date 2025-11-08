#!/bin/bash

# WXKBTweak 诊断版本构建脚本
# 包含详细的诊断日志输出

echo "🔨 构建 WXKBTweak 诊断版本"
echo "=================================="

# 检查 Theos 环境
if [ ! -d "/opt/theos" ]; then
    echo "❌ Theos 未安装在 /opt/theos"
    echo "请先安装 Theos: https://github.com/theos/theos"
    exit 1
fi

# 设置环境变量
export THEOS=/opt/theos
export PATH=$THEOS/bin:$PATH

echo "✅ Theos 环境检查完成"

# 清理之前的构建
echo "🧹 清理之前的构建..."
rm -rf *.deb
rm -rf obj/
rm -rf .theos/

# 构建诊断版本
echo "🔨 开始构建诊断版本..."
make clean
make package

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    
    # 显示生成的包
    echo "📦 生成的安装包:"
    if [ -f "packages/"*.deb ]; then
        ls -la packages/*.deb
        PACKAGE_FILE=$(ls packages/*.deb | head -1)
    else
        ls -la *.deb 2>/dev/null || echo "❌ 未找到 .deb 文件"
        PACKAGE_FILE=$(ls *.deb 2>/dev/null | head -1)
    fi
    echo ""
    echo "📋 包信息:"
    dpkg-deb -I "$PACKAGE_FILE"
    
    echo ""
    echo "📂 包内容:"
    dpkg-deb -c "$PACKAGE_FILE"
    
    echo ""
    echo "🚀 安装说明:"
    echo "1. 将 $PACKAGE_FILE 传输到设备"
    echo "2. 使用 'dpkg -i $PACKAGE_FILE' 安装"
    echo "3. 运行 './diagnose_wxktweak.sh' 进行诊断"
    echo "4. 激活微信输入法并查看日志"
    
else
    echo "❌ 构建失败！"
    echo "请检查错误信息并修复问题"
    exit 1
fi