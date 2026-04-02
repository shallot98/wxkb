#!/bin/bash
# Verify all hooks are properly closed

echo "=========================================="
echo "Verifying Hook Structure"
echo "=========================================="

HOOK_COUNT=$(grep -c "^%hook" Tweak.x)
END_COUNT=$(grep -c "^%end" Tweak.x)

echo "Number of %hook declarations: $HOOK_COUNT"
echo "Number of %end declarations: $END_COUNT"
echo ""

if [ "$HOOK_COUNT" -eq "$END_COUNT" ]; then
    echo "✅ All hooks are properly closed!"
    echo ""
    echo "Hook summary:"
    grep -n "^%hook" Tweak.x | while read line; do
        LINE_NUM=$(echo $line | cut -d: -f1)
        HOOK_NAME=$(echo $line | cut -d' ' -f2)
        echo "  - $HOOK_NAME (line $LINE_NUM)"
    done
    exit 0
else
    echo "❌ Mismatch: $HOOK_COUNT hooks but $END_COUNT ends"
    exit 1
fi
