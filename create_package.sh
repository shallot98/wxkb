#!/bin/bash
# 老王的手动打包脚本
# 艹，在Windows上模拟创建deb包结构！

set -e

echo "=========================================="
echo "老王的WXKBTweak手动打包工具"
echo "=========================================="
echo ""

# 包信息
PACKAGE_NAME="com.laowang.wxkbtweak"
VERSION="2.0.1"
ARCH="iphoneos-arm64"

# 创建打包目录
PACKAGE_DIR="package_output"
DEB_DIR="$PACKAGE_DIR/deb_structure"

echo "[1/6] 清理旧文件..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$DEB_DIR"

echo "[2/6] 创建目录结构..."
# rootless越狱的路径是 /var/jb/...
mkdir -p "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$DEB_DIR/Library/PreferenceBundles"
mkdir -p "$DEB_DIR/Library/PreferenceLoader/Preferences"
mkdir -p "$DEB_DIR/DEBIAN"

echo "[3/6] 复制文件..."

# 复制control文件
cp control "$DEB_DIR/DEBIAN/"

# 复制plist过滤器
cp WXKBTweak.plist "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries/"

# 复制设置面板
mkdir -p "$DEB_DIR/Library/PreferenceBundles/WXKBTweakPrefs.bundle"
cp wxkbtweakprefs/entry.plist "$DEB_DIR/Library/PreferenceLoader/Preferences/WXKBTweakPrefs.plist"
cp wxkbtweakprefs/Resources/Root.plist "$DEB_DIR/Library/PreferenceBundles/WXKBTweakPrefs.bundle/"

# 创建占位符文件（因为dylib需要编译）
echo "# 这个文件需要用Theos编译Tweak.x生成" > "$DEB_DIR/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib.placeholder"

echo "[4/6] 创建安装说明..."
cat > "$PACKAGE_DIR/README_INSTALL.txt" << 'EOF'
========================================
WXKBTweak v2.0.1 - 安装说明
========================================

⚠️ 重要提示：
这个包结构是在Windows上创建的模拟版本，缺少编译后的dylib文件！

要完成打包，你需要：

方法1：在Mac/Linux上用Theos编译
---------------------------------
1. 安装Theos
2. cd WXKBTweak
3. make package
4. 生成的deb在packages/目录

方法2：手动完成打包
---------------------------------
1. 用Theos编译Tweak.x生成WXKBTweak.dylib
2. 替换deb_structure/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib.placeholder
3. 在Linux/Mac上执行：
   dpkg-deb -b deb_structure com.laowang.wxkbtweak_2.0.1_iphoneos-arm64.deb

方法3：直接在设备上安装（不打包）
---------------------------------
1. 上传编译好的dylib到设备：
   /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib

2. 上传plist到设备：
   /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist

3. 上传设置面板到设备：
   /var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle/

4. 重启SpringBoard：
   sbreload

老王提醒：
- dylib文件必须用Theos编译Tweak.x生成
- Windows上无法直接编译iOS插件
- 建议使用Mac/Linux或GitHub Actions

========================================
EOF

echo "[5/6] 创建文件清单..."
cat > "$PACKAGE_DIR/FILES_LIST.txt" << EOF
========================================
WXKBTweak v2.0.1 - 文件清单
========================================

需要安装到设备的文件：

1. 主插件（需要编译）
   /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib
   /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist

2. 设置面板
   /var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle/Root.plist
   /var/jb/Library/PreferenceLoader/Preferences/WXKBTweakPrefs.plist

3. 配置文件（自动生成）
   /var/mobile/Library/Preferences/com.laowang.wxkbtweak.plist

========================================
EOF

echo "[6/6] 生成安装脚本..."
cat > "$PACKAGE_DIR/manual_install.sh" << 'EOFSCRIPT'
#!/bin/bash
# 手动安装脚本 - 在越狱设备上执行

echo "WXKBTweak 手动安装脚本"
echo "======================================"

# 检查是否是root
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root权限运行！"
    echo "   sudo bash manual_install.sh"
    exit 1
fi

# 检查dylib文件
if [ ! -f "WXKBTweak.dylib" ]; then
    echo "❌ 找不到WXKBTweak.dylib文件！"
    echo "   请先用Theos编译Tweak.x"
    exit 1
fi

echo "开始安装..."

# 创建目录
mkdir -p /var/jb/Library/MobileSubstrate/DynamicLibraries
mkdir -p /var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle
mkdir -p /var/jb/Library/PreferenceLoader/Preferences

# 复制文件
echo "复制主插件..."
cp WXKBTweak.dylib /var/jb/Library/MobileSubstrate/DynamicLibraries/
cp WXKBTweak.plist /var/jb/Library/MobileSubstrate/DynamicLibraries/

echo "复制设置面板..."
cp Root.plist /var/jb/Library/PreferenceBundles/WXKBTweakPrefs.bundle/
cp WXKBTweakPrefs.plist /var/jb/Library/PreferenceLoader/Preferences/

# 设置权限
chmod 755 /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.dylib
chmod 644 /var/jb/Library/MobileSubstrate/DynamicLibraries/WXKBTweak.plist

echo "✅ 安装完成！"
echo ""
echo "请重启SpringBoard："
echo "   sbreload"
EOFSCRIPT

chmod +x "$PACKAGE_DIR/manual_install.sh"

# 创建目录树
echo ""
echo "[完成] 生成目录树..."
tree "$DEB_DIR" > "$PACKAGE_DIR/DIRECTORY_TREE.txt" 2>/dev/null || find "$DEB_DIR" -print > "$PACKAGE_DIR/DIRECTORY_TREE.txt"

echo ""
echo "=========================================="
echo "✅ 打包结构创建完成！"
echo "=========================================="
echo ""
echo "生成的文件："
echo "  📁 $PACKAGE_DIR/"
echo "     ├── deb_structure/          # deb包目录结构"
echo "     ├── README_INSTALL.txt      # 安装说明"
echo "     ├── FILES_LIST.txt          # 文件清单"
echo "     ├── manual_install.sh       # 手动安装脚本"
echo "     └── DIRECTORY_TREE.txt      # 目录树"
echo ""
echo "⚠️ 重要提示："
echo "1. 这个包缺少编译后的dylib文件"
echo "2. 需要用Theos编译Tweak.x生成WXKBTweak.dylib"
echo "3. 查看README_INSTALL.txt了解完整步骤"
echo ""
echo "老王建议："
echo "- 使用Mac/Linux + Theos编译"
echo "- 或使用GitHub Actions自动编译"
echo "- 或找有Mac的朋友帮忙"
echo ""
echo "艹，Windows上真tm不方便！"
