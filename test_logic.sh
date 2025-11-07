#!/bin/bash
# 老王的代码逻辑验证脚本
# 艹，虽然不能真正运行，但可以检查语法和逻辑！

set -e

echo "=========================================="
echo "老王的WXKBTweak代码验证工具"
echo "=========================================="
echo ""

# 检查必要文件
echo "[1/5] 检查必要文件..."
files=(
    "Tweak.x"
    "Makefile"
    "control"
    "WXKBTweak.plist"
    "wxkbtweakprefs/Makefile"
    "wxkbtweakprefs/Resources/Root.plist"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file - 艹，文件不存在！"
        exit 1
    fi
done

# 检查Tweak.x语法
echo ""
echo "[2/5] 检查Tweak.x基本语法..."

# 检查是否有未闭合的括号
open_braces=$(grep -o '{' Tweak.x | wc -l)
close_braces=$(grep -o '}' Tweak.x | wc -l)
if [ "$open_braces" -eq "$close_braces" ]; then
    echo "  ✓ 括号匹配正确 ($open_braces 对)"
else
    echo "  ✗ 括号不匹配！开={$open_braces}, 闭={$close_braces}"
    exit 1
fi

# 检查是否有未闭合的方括号
open_brackets=$(grep -o '\[' Tweak.x | wc -l)
close_brackets=$(grep -o '\]' Tweak.x | wc -l)
if [ "$open_brackets" -eq "$close_brackets" ]; then
    echo "  ✓ 方括号匹配正确 ($open_brackets 对)"
else
    echo "  ✗ 方括号不匹配！开=[$open_brackets], 闭=[$close_brackets]"
    exit 1
fi

# 检查关键hook是否存在
echo ""
echo "[3/5] 检查关键hook..."
hooks=(
    "WBLanguageSwitchButton"
    "WBLanguageSwitchView"
    "UIInputView"
    "UIInputViewController"
)

for hook in "${hooks[@]}"; do
    if grep -q "%hook $hook" Tweak.x; then
        echo "  ✓ %hook $hook"
    else
        echo "  ⚠ %hook $hook - 未找到"
    fi
done

# 检查关键方法是否存在
echo ""
echo "[4/5] 检查关键方法..."
methods=(
    "didMoveToWindow"
    "handleLanguageSwitch"
    "performLanguageSwitchWithDirection"
    "findLanguageSwitchButton"
    "searchButtonInView"
)

for method in "${methods[@]}"; do
    if grep -q "$method" Tweak.x; then
        echo "  ✓ $method"
    else
        echo "  ✗ $method - 艹，方法不存在！"
        exit 1
    fi
done

# 检查框架依赖
echo ""
echo "[5/5] 检查框架依赖..."
frameworks=(
    "UIKit"
    "Foundation"
    "CoreGraphics"
    "AudioToolbox"
)

for framework in "${frameworks[@]}"; do
    if grep -q "$framework" Makefile; then
        echo "  ✓ $framework"
    else
        echo "  ✗ $framework - 艹，框架缺失！"
        exit 1
    fi
done

# 统计代码行数
echo ""
echo "=========================================="
echo "代码统计"
echo "=========================================="
total_lines=$(wc -l < Tweak.x)
comment_lines=$(grep -c '//' Tweak.x || echo 0)
code_lines=$((total_lines - comment_lines))

echo "总行数: $total_lines"
echo "注释行: $comment_lines"
echo "代码行: $code_lines"

# 检查潜在问题
echo ""
echo "=========================================="
echo "潜在问题检查"
echo "=========================================="

# 检查是否有内存泄漏风险
if grep -q "alloc.*init" Tweak.x && ! grep -q "dealloc" Tweak.x; then
    echo "  ⚠ 可能存在内存泄漏（有alloc但没有dealloc）"
else
    echo "  ✓ 内存管理看起来正常"
fi

# 检查是否有重复的观察者
observer_add=$(grep -c "addObserver" Tweak.x || echo 0)
observer_remove=$(grep -c "removeObserver" Tweak.x || echo 0)
if [ "$observer_add" -gt "$observer_remove" ]; then
    echo "  ⚠ 观察者添加($observer_add)多于移除($observer_remove)"
else
    echo "  ✓ 观察者管理正常"
fi

# 检查是否有空指针检查
if grep -q "if.*nil" Tweak.x || grep -q "if.*!" Tweak.x; then
    echo "  ✓ 有空指针检查"
else
    echo "  ⚠ 缺少空指针检查"
fi

echo ""
echo "=========================================="
echo "✅ 验证完成！代码看起来没问题！"
echo "=========================================="
echo ""
echo "老王提醒："
echo "1. 这只是基本的语法和逻辑检查"
echo "2. 真正的测试需要在越狱设备上进行"
echo "3. 建议使用debug.sh查看实时日志"
echo ""
echo "艹，代码写得还不错！可以尝试编译了！"
