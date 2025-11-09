#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
老王的深度二进制分析工具 - 专门用来扒微信输入法的Objective-C类和方法
"""

import re
import sys
import io
from collections import defaultdict

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def extract_objc_classes(data):
    """提取Objective-C类名"""
    classes = set()

    # 匹配类名模式: WB开头的类名
    wb_pattern = rb'WB[A-Z][a-zA-Z0-9_]{2,50}'
    for match in re.finditer(wb_pattern, data):
        try:
            class_name = match.group().decode('ascii', errors='ignore')
            if len(class_name) > 3 and len(class_name) < 60:
                classes.add(class_name)
        except:
            pass

    # 匹配其他常见的类名模式
    class_patterns = [
        rb'[A-Z][a-z]+[A-Z][a-zA-Z0-9_]{3,40}',  # 驼峰命名
        rb'UI[A-Z][a-zA-Z0-9_]{2,40}',  # UI开头
        rb'NS[A-Z][a-zA-Z0-9_]{2,40}',  # NS开头
    ]

    for pattern in class_patterns:
        for match in re.finditer(pattern, data):
            try:
                class_name = match.group().decode('ascii', errors='ignore')
                if len(class_name) > 4 and len(class_name) < 60:
                    # 过滤掉明显不是类名的
                    if not any(x in class_name.lower() for x in ['http', 'www', 'html', 'https']):
                        classes.add(class_name)
            except:
                pass

    return sorted(classes)

def extract_objc_methods(data):
    """提取Objective-C方法名"""
    methods = set()

    # 匹配方法名模式
    method_patterns = [
        rb'[a-z][a-zA-Z0-9_]{2,50}:',  # 带参数的方法
        rb'[a-z][a-zA-Z0-9_]{3,50}(?=\x00)',  # 无参数的方法
    ]

    for pattern in method_patterns:
        for match in re.finditer(pattern, data):
            try:
                method_name = match.group().decode('ascii', errors='ignore').rstrip(':')
                if len(method_name) > 3 and len(method_name) < 60:
                    # 过滤掉明显不是方法名的
                    if not any(x in method_name.lower() for x in ['http', 'www', 'html', 'https', 'string', 'error']):
                        methods.add(method_name)
            except:
                pass

    return sorted(methods)

def find_language_switch_methods(methods):
    """查找语言切换相关的方法"""
    keywords = [
        'switch', 'toggle', 'change', 'select', 'set',
        'language', 'lang', 'english', 'chinese', 'keyboard',
        'input', 'method', 'mode'
    ]

    results = defaultdict(list)

    for method in methods:
        method_lower = method.lower()
        score = 0
        matched_keywords = []

        for keyword in keywords:
            if keyword in method_lower:
                score += 10
                matched_keywords.append(keyword)

        # 特殊加分
        if 'switch' in method_lower and 'language' in method_lower:
            score += 50
        if 'toggle' in method_lower and ('lang' in method_lower or 'keyboard' in method_lower):
            score += 40
        if 'change' in method_lower and 'language' in method_lower:
            score += 40
        if 'select' in method_lower and 'language' in method_lower:
            score += 30

        if score > 0:
            results[score].append((method, matched_keywords))

    return results

def find_language_switch_classes(classes):
    """查找语言切换相关的类"""
    keywords = [
        'Language', 'Lang', 'Switch', 'Toggle', 'Keyboard',
        'Input', 'Method', 'Button', 'View', 'Controller'
    ]

    results = []

    for cls in classes:
        score = 0
        matched_keywords = []

        for keyword in keywords:
            if keyword in cls:
                score += 10
                matched_keywords.append(keyword)

        # 特殊加分
        if 'Language' in cls and 'Switch' in cls:
            score += 50
        if 'Lang' in cls and ('Switch' in cls or 'Toggle' in cls):
            score += 40

        if score > 0:
            results.append((score, cls, matched_keywords))

    return sorted(results, key=lambda x: x[0], reverse=True)

def main():
    print("=" * 80)
    print("Laowang Deep Binary Analysis Tool")
    print("=" * 80)

    filepath = r"C:\Users\Administrator\wxkb\wxkb_plugin"

    print("\n[1] Loading binary file...")
    with open(filepath, 'rb') as f:
        data = f.read()
    print(f"[OK] Loaded {len(data)} bytes")

    print("\n[2] Extracting Objective-C classes...")
    classes = extract_objc_classes(data)
    print(f"[OK] Found {len(classes)} classes")

    print("\n[3] Extracting Objective-C methods...")
    methods = extract_objc_methods(data)
    print(f"[OK] Found {len(methods)} methods")

    print("\n[4] Finding language switch related classes...")
    switch_classes = find_language_switch_classes(classes)
    print(f"[OK] Found {len(switch_classes)} related classes")

    print("\n[5] Finding language switch related methods...")
    switch_methods = find_language_switch_methods(methods)
    total_switch_methods = sum(len(v) for v in switch_methods.values())
    print(f"[OK] Found {total_switch_methods} related methods")

    # 生成报告
    print("\n" + "=" * 80)
    print("ANALYSIS REPORT")
    print("=" * 80)

    print("\n" + "=" * 80)
    print("TOP 50 LANGUAGE SWITCH RELATED CLASSES (by score)")
    print("=" * 80)
    for i, (score, cls, keywords) in enumerate(switch_classes[:50], 1):
        print(f"{i:3d}. [{score:3d}] {cls}")
        print(f"      Keywords: {', '.join(keywords)}")

    print("\n" + "=" * 80)
    print("TOP 100 LANGUAGE SWITCH RELATED METHODS (by score)")
    print("=" * 80)
    count = 0
    for score in sorted(switch_methods.keys(), reverse=True):
        for method, keywords in switch_methods[score]:
            count += 1
            if count <= 100:
                print(f"{count:3d}. [{score:3d}] {method}")
                print(f"      Keywords: {', '.join(keywords)}")

    # 保存完整报告
    report_path = r"C:\Users\Administrator\wxkb\DEEP_ANALYSIS_REPORT.txt"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("LAOWANG DEEP BINARY ANALYSIS REPORT\n")
        f.write("=" * 80 + "\n\n")

        f.write("=" * 80 + "\n")
        f.write(f"ALL CLASSES ({len(classes)})\n")
        f.write("=" * 80 + "\n")
        for cls in classes:
            f.write(f"{cls}\n")

        f.write("\n" + "=" * 80 + "\n")
        f.write(f"ALL METHODS ({len(methods)})\n")
        f.write("=" * 80 + "\n")
        for method in methods:
            f.write(f"{method}\n")

        f.write("\n" + "=" * 80 + "\n")
        f.write(f"LANGUAGE SWITCH RELATED CLASSES ({len(switch_classes)})\n")
        f.write("=" * 80 + "\n")
        for score, cls, keywords in switch_classes:
            f.write(f"[{score:3d}] {cls} - Keywords: {', '.join(keywords)}\n")

        f.write("\n" + "=" * 80 + "\n")
        f.write(f"LANGUAGE SWITCH RELATED METHODS ({total_switch_methods})\n")
        f.write("=" * 80 + "\n")
        for score in sorted(switch_methods.keys(), reverse=True):
            for method, keywords in switch_methods[score]:
                f.write(f"[{score:3d}] {method} - Keywords: {', '.join(keywords)}\n")

    print("\n" + "=" * 80)
    print(f"[OK] Full report saved to: {report_path}")
    print("=" * 80)

    print("\n" + "=" * 80)
    print("LAOWANG'S RECOMMENDATIONS")
    print("=" * 80)
    print("\nBased on the analysis, the most likely language switch APIs are:")
    print("\nTOP CLASSES:")
    for i, (score, cls, keywords) in enumerate(switch_classes[:5], 1):
        print(f"  {i}. {cls} (score: {score})")

    print("\nTOP METHODS:")
    count = 0
    for score in sorted(switch_methods.keys(), reverse=True):
        if count >= 10:
            break
        for method, keywords in switch_methods[score]:
            count += 1
            if count <= 10:
                print(f"  {count}. {method} (score: {score})")

    print("\nSuggested hook strategy:")
    print("1. Hook the top classes' init methods to save instances")
    print("2. Try calling the top methods directly")
    print("3. Use runtime introspection to find the actual button instance")
    print("4. Simulate button tap events")

    print("\n" + "=" * 80)
    print("Analysis complete! Check DEEP_ANALYSIS_REPORT.txt for full details.")
    print("=" * 80)

if __name__ == '__main__':
    main()
