#!/bin/bash
# Script to verify no duplicate Logos hooks exist

echo "=========================================="
echo "Checking for Duplicate Logos Hooks"
echo "=========================================="
echo ""

echo "All %hook declarations in Tweak.x:"
grep -n "^%hook" Tweak.x
echo ""

echo "Checking for duplicates..."
DUPLICATES=$(grep "^%hook" Tweak.x | sort | uniq -d)

if [ -z "$DUPLICATES" ]; then
    echo "✅ No duplicate hooks found!"
    exit 0
else
    echo "❌ Duplicate hooks detected:"
    echo "$DUPLICATES"
    exit 1
fi
