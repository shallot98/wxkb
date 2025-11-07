#!/bin/bash
# 老王的调试脚本 - 实时查看插件日志

if [ -z "$1" ]; then
    echo "用法: ./debug.sh <设备IP>"
    echo "示例: ./debug.sh 192.168.1.100"
    exit 1
fi

DEVICE_IP=$1

echo "=========================================="
echo "老王的WXKBTweak调试工具"
echo "连接设备: $DEVICE_IP"
echo "=========================================="
echo ""
echo "🔍 实时监控插件日志..."
echo "提示：在设备上打开微信输入法并尝试滑动"
echo ""

# 实时查看系统日志，过滤WXKBTweak相关信息
ssh root@$DEVICE_IP "tail -f /var/log/syslog | grep --line-buffered WXKBTweak"
