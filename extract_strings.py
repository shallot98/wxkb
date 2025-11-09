#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
老王的字符串提取工具 - 专门用来扒微信输入法的字符串
"""

import re
import sys

def extract_strings(filepath, min_length=4):
    """提取二进制文件中的可读字符串"""
    strings_list = []

    with open(filepath, 'rb') as f:
        data = f.read()

    # ASCII字符串
    ascii_pattern = b'[\x20-\x7E]{' + str(min_length).encode() + b',}'
    ascii_strings = re.findall(ascii_pattern, data)
    strings_list.extend([s.decode('ascii', errors='ignore') for s in ascii_strings])

    # Unicode字符串（UTF-16LE）
    unicode_pattern = b'(?:[\x20-\x7E]\x00){' + str(min_length).encode() + b',}'
    unicode_strings = re.findall(unicode_pattern, data)
    strings_list.extend([s.decode('utf-16le', errors='ignore') for s in unicode_strings])

    return strings_list

def filter_keywords(strings_list, keywords):
    """根据关键字过滤字符串"""
    results = []
    for s in strings_list:
        for keyword in keywords:
            if keyword.lower() in s.lower():
                results.append(s)
                break
    return results

if __name__ == '__main__':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    print("=" * 80)
    print("Laowang String Extractor - Analyzing wxkb_plugin")
    print("=" * 80)

    filepath = r"C:\Users\Administrator\wxkb\wxkb_plugin"

    print("\n[1] Extracting all strings...")
    all_strings = extract_strings(filepath, min_length=4)
    print(f"[OK] Extracted {len(all_strings)} strings")

    # 保存所有字符串
    with open(r"C:\Users\Administrator\wxkb\all_strings.txt", 'w', encoding='utf-8') as f:
        for s in all_strings:
            f.write(s + '\n')
    print("[OK] All strings saved to all_strings.txt")

    print("\n[2] Searching for switch-related keywords...")
    keywords = [
        'switch', 'toggle', 'language', 'lang', 'english', 'chinese',
        '中文', '英文', '切换', 'keyboard', 'input', 'method',
        'WBLanguage', 'WBKeyFunc', 'WBInput', 'changeLanguage',
        'selectLanguage', 'setLanguage', 'switchTo', 'toggleTo'
    ]

    filtered = filter_keywords(all_strings, keywords)
    print(f"[OK] Found {len(filtered)} related strings")

    # 保存过滤后的字符串
    with open(r"C:\Users\Administrator\wxkb\filtered_strings.txt", 'w', encoding='utf-8') as f:
        for s in filtered:
            f.write(s + '\n')

    print("\n" + "=" * 80)
    print("Top 100 related strings:")
    print("=" * 80)
    for i, s in enumerate(filtered[:100], 1):
        print(f"{i:3d}. {s}")

    print("\n" + "=" * 80)
    print(f"Found {len(filtered)} related strings, saved to filtered_strings.txt")
    print("=" * 80)
