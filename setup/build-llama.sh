#!/bin/bash
# 编译 llama.cpp
# 作用：从 GitHub 克隆 llama.cpp 仓库并编译

cd /data/data/com.termux/files/home

# 检查是否已经存在
if [ -d "llama.cpp" ]; then
    echo "=== llama.cpp 已存在，跳过克隆 ==="
else
    echo "=== 克隆 llama.cpp 仓库 ==="
    git clone https://github.com/ggml-org/llama.cpp
fi

cd llama.cpp

echo ""
echo "=== 开始编译 llama.cpp ==="
cmake -B build
cmake --build build --config Release -j$(nproc)

echo ""
echo "=== 编译完成，检查输出 ==="
ls -la build/bin/

echo ""
echo "=== 验证主要二进制文件 ==="
if [ -f "build/bin/llama-cli" ]; then
    echo "llama-cli: OK"
else
    echo "llama-cli: NOT FOUND"
fi

if [ -f "build/bin/llama-server" ]; then
    echo "llama-server: OK"
else
    echo "llama-server: NOT FOUND"
fi
