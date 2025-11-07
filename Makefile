TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

# Rootless越狱配置 - 老王专用
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WXKBTweak

# 源文件
WXKBTweak_FILES = Tweak.x
WXKBTweak_CFLAGS = -fobjc-arc

# 框架依赖
WXKBTweak_FRAMEWORKS = UIKit Foundation CoreGraphics AudioToolbox
WXKBTweak_PRIVATE_FRAMEWORKS =

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	@echo "📦 复制设置面板到包布局..."
	@mkdir -p $(THEOS_LAYOUT_DIR)/Library/PreferenceBundles
	@mkdir -p $(THEOS_LAYOUT_DIR)/Library/PreferenceLoader/Preferences
	@if [ -d "wxkbtweakprefs/.theos/obj/debug/WXKBTweakPrefs.bundle" ]; then \
		cp -r wxkbtweakprefs/.theos/obj/debug/WXKBTweakPrefs.bundle $(THEOS_LAYOUT_DIR)/Library/PreferenceBundles/; \
	fi
	@if [ -f "wxkbtweakprefs/entry.plist" ]; then \
		cp wxkbtweakprefs/entry.plist $(THEOS_LAYOUT_DIR)/Library/PreferenceLoader/Preferences/WXKBTweakPrefs.plist; \
	fi

after-install::
	install.exec "sbreload"