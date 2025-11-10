# Theos/Logos Duplicate Hook Definitions Fix Guide

## Problem Summary

The build error you're experiencing occurs when the same Objective-C class is hooked multiple times using `%hook` in the same Logos source file (.xm or .x files). When Logos preprocessor processes the file, it generates C functions for each hook, and duplicate hooks cause redefinition errors during compilation.

## Error Pattern

```
error: redefinition of '_logos_orig$_ungrouped$ClassName$methodName'
error: redefinition of '_logos_method$_ungrouped$ClassName$methodName'
```

## Your Specific Errors (DYYY Project)

Based on your build log, you have THREE classes being hooked multiple times in `DYYY.xm`:

1. **AWEPlayInteractionRelatedVideoView** - `layoutSubviews` method hooked at:
   - Line 2644 (first definition)
   - Line 7170 (duplicate - **REMOVE THIS**)

2. **AWEFeedRelatedSearchTipView** - `layoutSubviews` method hooked at:
   - Line 2653 (first definition)
   - Line 7096 (duplicate - **REMOVE THIS**)

3. **UIView** - `setFrame:` method hooked at:
   - Line 5583 (first definition)
   - Line 7194 (duplicate - **REMOVE THIS**)

## How to Fix

### Step 1: Locate Duplicate Hooks

Search your `DYYY.xm` file for these patterns:

```bash
grep -n "^%hook AWEPlayInteractionRelatedVideoView" DYYY.xm
grep -n "^%hook AWEFeedRelatedSearchTipView" DYYY.xm
grep -n "^%hook UIView" DYYY.xm
```

### Step 2: Identify Which Hook to Remove

You need to examine both hook blocks to determine which one to keep. Generally:

- Keep the hook that has more complete implementation
- Keep the hook that is in the correct logical section of your code
- Remove hooks that appear to be copy-paste errors

### Step 3: Consolidate or Remove Duplicate Hooks

#### Option A: Completely Remove Duplicate Hook Block

If the duplicate hook is redundant, simply delete the entire block:

```objc
// DELETE THIS if it's a duplicate:
%hook ClassName

- (void)someMethod {
    %orig;
    // your code
}

%end
```

#### Option B: Consolidate Multiple Hooks into One

If both hooks contain different methods you want to hook, merge them into a single `%hook` block:

```objc
// BEFORE (BAD - duplicate hooks):
%hook UIView
- (void)setFrame:(CGRect)frame {
    %orig(frame);
    // code A
}
%end

// ... other code ...

%hook UIView
- (void)layoutSubviews {
    %orig;
    // code B
}
%end

// AFTER (GOOD - single consolidated hook):
%hook UIView

- (void)setFrame:(CGRect)frame {
    %orig(frame);
    // code A
}

- (void)layoutSubviews {
    %orig;
    // code B
}

%end
```

### Step 4: Verify No More Duplicates

After fixing, verify there are no more duplicate hooks:

```bash
grep "^%hook" DYYY.xm | sort | uniq -d
```

This should return **nothing**. If it returns any results, you still have duplicates.

### Step 5: Rebuild

```bash
make clean
make package FINALPACKAGE=1
```

## Prevention Tips

1. **Use meaningful section comments** to organize your hooks:
   ```objc
   // ============================================
   // Hook UIView - Layout Management
   // ============================================
   %hook UIView
   // all UIView hooks here
   %end
   ```

2. **Search before adding new hooks** - always check if a class is already hooked:
   ```bash
   grep "%hook ClassName" yourfile.xm
   ```

3. **Use Logos groups** for better organization if you have many hooks:
   ```objc
   %group GroupName
   %hook ClassName
   // hooks
   %end
   %end // end of group
   ```

4. **Keep one class per %hook block** - never split a class's hooks across multiple `%hook` blocks unless absolutely necessary

## WXKBTweak Status

**✅ This repository (WXKBTweak) has NO duplicate hooks and compiles successfully.**

The following classes are hooked exactly once:
- WBLanguageSwitchButton
- WBLanguageSwitchView
- WBKeyFuncLangSwitch
- WBKeyboardView
- WBMainInputView
- WBKeyView
- UIInputView
- UIInputViewController

## Additional Resources

- [Theos Documentation](https://theos.dev/)
- [Logos Syntax](https://theos.dev/docs/logos-syntax)
- [Common Logos Errors](https://github.com/theos/theos/wiki/Logos#common-errors)

---

**Note**: The error log you provided appears to be from a different project (DYYY). If you need help fixing that specific project, you'll need to share the DYYY.xm file content, specifically around the lines mentioned in the errors.
