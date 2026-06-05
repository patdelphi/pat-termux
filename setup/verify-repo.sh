#!/bin/bash
# 验证换源结果

echo "=== 源配置 ==="
cat $PREFIX/etc/apt/sources.list
echo ""
echo "=== x11 目录 ==="
ls $PREFIX/etc/apt/sources.list.d/ 2>/dev/null || echo "无 x11 目录"
echo ""
echo "=== 测试更新 ==="
pkg update
