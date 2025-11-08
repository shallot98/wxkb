#!/bin/bash

# WXKBTweak 诊断脚本
# 用于检查 tweak 是否正确加载并输出诊断信息

echo "🔍 WXKBTweak 诊断工具 v1.0"
echo "=================================="

# 检查是否在 rootless 环境
if [ -d "/var/jb" ]; then
    echo "✅ 检测到 rootless 越狱环境"
    JAILBREAK_PATH="/var/jb"
else
    echo "⚠️  未检测到 rootless 环境，使用传统路径"
    JAILBREAK_PATH=""
fi

# 检查 tweak 文件是否存在
DYLIB_PATH="${JAILBREAK_PATH}/var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib"
PLIST_PATH="${JAILBREAK_PATH}/var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist"

echo ""
echo "📁 文件检查:"
if [ -f "$DYLIB_PATH" ]; then
    echo "✅ WXKBTweak.dylib 存在: $DYLIB_PATH"
    ls -la "$DYLIB_PATH"
else
    echo "❌ WXKBTweak.dylib 不存在: $DYLIB_PATH"
fi

if [ -f "$PLIST_PATH" ]; then
    echo "✅ WXKBTweak.plist 存在: $PLIST_PATH"
    echo "📋 配置内容:"
    cat "$PLIST_PATH"
else
    echo "❌ WXKBTweak.plist 不存在: $PLIST_PATH"
fi

# 检查 PreferenceBundle
PREFS_PATH="${JAILBREAK_PATH}/var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle"
if [ -d "$PREFS_PATH" ]; then
    echo "✅ PreferenceBundle 存在: $PREFS_PATH"
else
    echo "❌ PreferenceBundle 不存在: $PREFS_PATH"
fi

# 检查配置文件
PREFS_CONFIG_PATH="${JAILBREAK_PATH}/var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist"
if [ -f "$PREFS_CONFIG_PATH" ]; then
    echo "✅ 配置文件存在: $PREFS_CONFIG_PATH"
    echo "📋 配置内容:"
    cat "$PREFS_CONFIG_PATH"
else
    echo "❌ 配置文件不存在: $PREFS_CONFIG_PATH"
fi

echo ""
echo "🔍 进程检查:"
# 检查微信输入法进程
ps aux | grep -i "wetype\|wechat" | grep -v grep

echo ""
echo "📝 实时日志监控 (Ctrl+C 退出):"
echo "=================================="
echo "请激活微信输入法并尝试滑动切换语言..."

# 监控系统日志
if command -v log &> /dev/null; then
    # iOS 10+ 使用 log 命令
    log stream --predicate 'process == "wetype" OR process == "WeChat" OR process contains "keyboard"' --info --debug
else
    # 旧版本使用 syslog
    tail -f /var/log/syslog | grep -i "wxkbtweak\|wetype\|wechat"
fi