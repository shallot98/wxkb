#!/bin/bash

# WXKBTweak 快速测试脚本

echo "🧪 WXKBTweak 快速测试"
echo "=================================="

# 检查构建产物
echo "📦 检查构建产物:"
if [ -f "packages/"*.deb ]; then
    DEB_FILE=$(ls packages/*.deb | head -1)
    echo "✅ 找到 .deb 包: $DEB_FILE"
    
    echo ""
    echo "📋 包信息:"
    dpkg-deb -I "$DEB_FILE"
    
    echo ""
    echo "📂 包内容 (关键文件):"
    dpkg-deb -c "$DEB_FILE" | grep -E "(WXKBTweak\.(dylib|plist)|Preferences)"
    
    echo ""
    echo "🎯 诊断版本特性:"
    echo "✅ 增强的构造函数日志"
    echo "✅ 详细的进程和Bundle ID诊断"
    echo "✅ 配置文件路径检测"
    echo "✅ UIInputView Hook诊断"
    echo "✅ 手势识别详细日志"
    echo "✅ 多Bundle ID支持"
    
    echo ""
    echo "🚀 下一步操作:"
    echo "1. 将 $DEB_FILE 传输到设备"
    echo "2. 在设备上执行: dpkg -i $DEB_FILE"
    echo "3. 运行诊断: ./diagnose_wxkbtweak.sh"
    echo "4. 查看日志: ./view_logs.sh"
    
else
    echo "❌ 未找到构建的 .deb 包"
    echo "请先运行: ./build_diagnostic.sh"
fi

echo ""
echo "📝 脚本文件:"
echo "✅ diagnose_wxkbtweak.sh - 系统诊断工具"
echo "✅ view_logs.sh - 日志查看工具"
echo "✅ build_diagnostic.sh - 诊断版本构建工具"
echo "✅ DIAGNOSTIC_GUIDE.md - 详细使用指南"