#!/bin/bash
# Termux 换源脚本 - 替换为清华镜像源

# 主源
sed -i 's|https://tmx.xvx.my.id/apt/termux-main|https://mirrors.tuna.tsinghua.edu.cn/termux|g' $PREFIX/etc/apt/sources.list

# x11 源（如果存在）
if [ -f "$PREFIX/etc/apt/sources.list.d/x11.list" ]; then
    sed -i 's|https://tmx.xvx.my.id/apt/termux-x11|https://mirrors.tuna.tsinghua.edu.cn/termux/termux-x11|g' $PREFIX/etc/apt/sources.list.d/x11.list
fi

echo "=== 主源 ==="
cat $PREFIX/etc/apt/sources.list

echo ""
echo "=== x11 源 ==="
cat $PREFIX/etc/apt/sources.list.d/x11.list 2>/dev/null || echo "无 x11 源"

echo ""
echo "换源完成，请执行: pkg update"
