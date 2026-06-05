#!/bin/bash
# 安装 llama.cpp 编译依赖
# 作用：安装 git、cmake、clang、make、wget、curl 等编译所需工具

echo "=== 安装编译依赖 ==="
pkg install -y git cmake clang make wget curl

echo ""
echo "=== 验证安装 ==="
echo "git version: $(git --version)"
echo "cmake version: $(cmake --version | head -1)"
echo "clang version: $(clang --version | head -1)"
echo "make version: $(make --version | head -1)"

echo ""
echo "=== 依赖安装完成 ==="
