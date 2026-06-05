#!/bin/bash
# 修复 Termux 镜像源配置并更新系统
# 作用：切换到官方主镜像源，然后执行系统更新

# 备份原始配置
if [ -f "$PREFIX/etc/apt/sources.list" ]; then
    cp "$PREFIX/etc/apt/sources.list" "$PREFIX/etc/apt/sources.list.bak"
fi

# 使用官方主镜像源
echo "deb https://termux.net/packages stable main" > "$PREFIX/etc/apt/sources.list"

echo "=== 当前镜像源配置 ==="
cat "$PREFIX/etc/apt/sources.list"

echo ""
echo "=== 开始更新系统 ==="
pkg update -y

echo ""
echo "=== 更新完成 ==="
