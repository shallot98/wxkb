TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WXKBTweakPrefs

WXKBTweakPrefs_FILES = WXKBTweakRootListController.m
WXKBTweakPrefs_FRAMEWORKS = UIKit CoreGraphics
WXKBTweakPrefs_PRIVATE_FRAMEWORKS = Preferences
WXKBTweakPrefs_INSTALL_PATH = /Library/PreferenceBundles
WXKBTweakPrefs_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)
WXKBTweakPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
