#!/bin/bash

# WXKBTweak 日志查看脚本
# 专门用于查看 WXKBTweak 相关的日志输出

echo "📝 WXKBTweak 日志查看工具"
echo "=================================="

# 检查是否在 rootless 环境
if [ -d "/var/jb" ]; then
    echo "✅ 检测到 rootless 越狱环境"
    JAILBREAK_PATH="/var/jb"
else
    echo "⚠️  未检测到 rootless 环境，使用传统路径"
    JAILBREAK_PATH=""
fi

echo ""
echo "🔍 搜索 WXKBTweak 相关日志..."
echo "=================================="

# 方法1: 使用 log 命令 (iOS 10+)
if command -v log &> /dev/null; then
    echo "📱 使用 log 命令查看历史日志..."
    
    # 查看过去1小时的日志
    echo "🕐 过去1小时的 WXKBTweak 日志:"
    log show --last 1h --predicate 'category contains "WXKBTweak"' --info --debug
    
    echo ""
    echo "🔍 搜索所有包含 WXKBTweak 的日志:"
    log show --last 2h --predicate 'processImagePath contains "WXKBTweak" OR (category contains "WXKBTweak") OR (eventMessage contains "WXKBTweak")' --info --debug
    
    echo ""
    echo "🔍 微信输入法相关日志:"
    log show --last 2h --predicate 'process == "wetype" OR processImagePath contains "wetype"' --info --debug

else
    # 方法2: 使用 syslog (旧版本)
    echo "📱 使用 syslog 查看日志..."
    
    if [ -f "/var/log/syslog" ]; then
        echo "🕐 最近的 WXKBTweak 日志:"
        tail -n 1000 /var/log/syslog | grep -i "wxkbtweak" || echo "未找到 WXKBTweak 相关日志"
        
        echo ""
        echo "🔍 微信输入法相关日志:"
        tail -n 1000 /var/log/syslog | grep -i "wetype\|wechat.*keyboard" || echo "未找到微信输入法相关日志"
        
    else
        echo "❌ 找不到系统日志文件"
    fi
fi

echo ""
echo "🔄 实时监控模式"
echo "=================================="
echo "选择要监控的日志类型:"
echo "1. WXKBTweak 专用日志"
echo "2. 微信输入法进程日志"
echo "3. 所有键盘相关日志"
echo "4. 退出"

read -p "请选择 (1-4): " choice

case $choice in
    1)
        echo "🔍 监控 WXKBTweak 日志 (Ctrl+C 退出)..."
        if command -v log &> /dev/null; then
            log stream --predicate 'category contains "WXKBTweak"' --info --debug
        else
            tail -f /var/log/syslog | grep -i "wxkbtweak"
        fi
        ;;
    2)
        echo "🔍 监控微信输入法进程日志 (Ctrl+C 退出)..."
        if command -v log &> /dev/null; then
            log stream --predicate 'process == "wetype"' --info --debug
        else
            tail -f /var/log/syslog | grep -i "wetype"
        fi
        ;;
    3)
        echo "🔍 监控所有键盘相关日志 (Ctrl+C 退出)..."
        if command -v log &> /dev/null; then
            log stream --predicate 'processImagePath contains "keyboard"' --info --debug
        else
            tail -f /var/log/syslog | grep -i "keyboard"
        fi
        ;;
    4)
        echo "👋 退出日志查看工具"
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac