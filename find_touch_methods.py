#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
老王的终极触摸方法查找器
专门找出处理触摸事件的类和方法
"""

import re
import sys

def analyze_touch_methods(report_file):
    """分析触摸相关的方法"""

    print("=" * 80)
    print("老王的触摸方法分析报告")
    print("=" * 80)

    with open(report_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # 关键类列表
    key_classes = [
        'WBKeyView',
        'WBKeyViewTouchEventMonitorProtocol',
        'WBKeyTouchDebugger',
        'WBMainInputView',
        'WBKeyboardView',
        'WBLanguageSwitchButton',
        'WBInputViewController',
        'WBPanelLayout'
    ]

    # 触摸相关的方法模式
    touch_patterns = [
        r'touches[A-Z]\w+',
        r'gesture[A-Z]\w+',
        r'swipe[A-Z]\w+',
        r'pan[A-Z]\w+',
        r'handleTouch\w+',
        r'onTouch\w+',
        r'touchEvent\w+',
    ]

    # 语言切换相关的方法模式
    lang_patterns = [
        r'language[A-Z]\w+',
        r'switchLanguage\w*',
        r'changeLanguage\w*',
        r'toggleLanguage\w*',
        r'inputMode\w+',
        r'switchInputMode\w*',
    ]

    print("\n" + "=" * 80)
    print("关键类的触摸相关方法")
    print("=" * 80)

    for cls in key_classes:
        print(f"\n### {cls} ###")

        # 查找这个类的所有方法
        class_pattern = rf'^{re.escape(cls)}$'
        class_matches = list(re.finditer(class_pattern, content, re.MULTILINE))

        if not class_matches:
            print(f"  [X] 未找到类定义")
            continue

        print(f"  [OK] 找到类定义")

        # 查找触摸相关方法
        touch_methods = set()
        for pattern in touch_patterns:
            matches = re.findall(pattern, content, re.IGNORECASE)
            touch_methods.update(matches)

        if touch_methods:
            print(f"\n  触摸相关方法 ({len(touch_methods)}个):")
            for method in sorted(touch_methods):
                print(f"    - {method}")

        # 查找语言切换相关方法
        lang_methods = set()
        for pattern in lang_patterns:
            matches = re.findall(pattern, content, re.IGNORECASE)
            lang_methods.update(matches)

        if lang_methods:
            print(f"\n  语言切换相关方法 ({len(lang_methods)}个):")
            for method in sorted(lang_methods):
                print(f"    - {method}")

    print("\n" + "=" * 80)
    print("所有触摸事件处理方法")
    print("=" * 80)

    all_touch_methods = set()
    for pattern in touch_patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        all_touch_methods.update(matches)

    print(f"\n找到 {len(all_touch_methods)} 个触摸相关方法:")
    for method in sorted(all_touch_methods):
        print(f"  - {method}")

    print("\n" + "=" * 80)
    print("所有语言切换方法")
    print("=" * 80)

    all_lang_methods = set()
    for pattern in lang_patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        all_lang_methods.update(matches)

    print(f"\n找到 {len(all_lang_methods)} 个语言切换相关方法:")
    for method in sorted(all_lang_methods):
        print(f"  - {method}")

    print("\n" + "=" * 80)
    print("老王的建议")
    print("=" * 80)
    print("""
1. 优先Hook WBKeyViewTouchEventMonitorProtocol - 这个是触摸事件监控协议
2. Hook WBKeyView 的 touches* 方法
3. Hook WBLanguageSwitchButton 并保存实例，直接调用切换方法
4. 如果上面都不行，Hook UIView 的 touches* 方法，但只处理键盘相关的视图

艹，这次一定能找到正确的Hook点！
    """)

if __name__ == '__main__':
    report_file = r'C:\Users\Administrator\wxkb\DEEP_ANALYSIS_REPORT.txt'
    analyze_touch_methods(report_file)
