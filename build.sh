#!/bin/bash
# 老王的一键编译脚本 - 艹，这脚本写得真tm方便！

set -e

echo "=========================================="
echo "老王的WXKBTweak编译脚本"
echo "=========================================="

# 检查Theos环境
if [ -z "$THEOS" ]; then
    echo "❌ 艹！THEOS环境变量未设置！"
    echo "请执行: export THEOS=/opt/theos"
    exit 1
fi

echo "✅ THEOS路径: $THEOS"

# 清理旧文件
echo ""
echo "🧹 清理旧的编译文件..."
make clean 2>/dev/null || true
rm -rf packages/ 2>/dev/null || true

# 编译主插件
echo ""
echo "🔨 编译主插件..."
make package FINALPACKAGE=1

# 编译设置面板
echo ""
echo "🔨 编译设置面板..."
cd wxkbtweakprefs
make clean 2>/dev/null || true
make all
cd ..

# 复制设置面板到主包布局
echo ""
echo "📦 复制设置面板到主包..."
mkdir -p layout/Library/PreferenceBundles
mkdir -p layout/Library/PreferenceLoader/Preferences
cp -r wxkbtweakprefs/.theos/obj/debug/WXKBTweakPrefs.bundle layout/Library/PreferenceBundles/
cp wxkbtweakprefs/entry.plist layout/Library/PreferenceLoader/Preferences/WXKBTweakPrefs.plist

# 显示生成的deb包
echo ""
echo "=========================================="
echo "✅ 编译完成！老王我真tm牛逼！"
echo "=========================================="
echo ""
echo "📦 生成的deb包："
ls -lh packages/*.deb 2>/dev/null || echo "❌ 艹，没找到deb包！"

echo ""
echo "📝 安装方法："
echo "1. 手动安装: scp packages/*.deb root@设备IP:/tmp/ && ssh root@设备IP 'dpkg -i /tmp/*.deb && sbreload'"
echo "2. 自动安装: make install (需要配置THEOS_DEVICE_IP)"
echo ""
echo "老王提醒：安装后记得重启SpringBoard！"
