---
name: termux-llama-deployment
description: 在 Termux/Android 设备上部署 llama.cpp 的完整流程，包括网络受限时的 SCP 上传方案
source: auto-skill
extracted_at: '2026-06-05T09:48:04.373Z'
---

# Termux 部署 llama.cpp

## 问题

在 Termux/Android 设备上编译运行 llama.cpp 用于本地 LLM 推理时，常见问题：

1. **网络受限**：Termux 设备（尤其手机）经常无法直接访问 GitHub，SSL 连接超时
2. **依赖复杂**：需要 cmake、clang、make 等编译工具链
3. **SSH 环境变量问题**：Windows SSH 连接时 `$PREFIX` 会被本地 Shell 先展开

## 完整流程

### 阶段 1：修复镜像源（首次配置）

Termux 清华镜像源经常出现 404 错误，需要刷新：

```bash
# 1. 创建修复脚本（本地 Windows）
# 2. 上传到 Termux
scp -P 8022 fix-repo.sh termux:~/fix-repo.sh

# 3. 执行修复
ssh termux "/data/data/com.termux/files/usr/bin/bash /data/data/com.termux/files/home/fix-repo.sh"
```

修复脚本内容：
```bash
#!/bin/bash
# 使用官方主镜像源
echo "deb https://termux.net/packages stable main" > "$PREFIX/etc/apt/sources.list"
pkg update -y
```

系统会自动测试并选择可用镜像（如阿里云镜像）。

### 阶段 2：升级系统并安装依赖

```bash
# 升级系统
ssh termux "pkg upgrade -y"

# 安装编译依赖
ssh termux "pkg install -y git cmake clang make wget curl"
```

验证依赖：
```bash
git version: git version 2.54.0
cmake version: cmake version 4.3.3
clang version: clang version 21.1.8
make version: GNU Make 4.4.1
```

### 阶段 3：获取 llama.cpp 源码（网络受限时）

**方案 A：Termux 直接克隆（网络正常时）**
```bash
ssh termux "git clone https://github.com/ggml-org/llama.cpp ~/llama.cpp"
```

**方案 B：Windows 下载后上传（网络受限时 - 推荐）**
```bash
# 1. Windows 上下载
cd C:\temp
git clone https://github.com/ggml-org/llama.cpp

# 2. 打包上传（避免传输大量小文件）
tar -czf llama.cpp.tar.gz llama.cpp
scp -P 8022 llama.cpp.tar.gz termux:~/

# 3. Termux 解压
ssh termux "cd ~ && tar -xzf llama.cpp.tar.gz"
```

**方案 C：使用 GitHub CLI**
```bash
# 如果 Termux 安装了 gh
ssh termux "gh repo clone ggml-org/llama.cpp ~/llama.cpp"
```

### 阶段 4：编译

```bash
# 创建编译脚本
cat > build-llama.sh << 'EOF'
#!/bin/bash
cd ~/llama.cpp

echo "=== 开始编译 ==="
cmake -B build
cmake --build build --config Release -j$(nproc)

echo "=== 验证输出 ==="
ls -la build/bin/
[ -f build/bin/llama-cli ] && echo "llama-cli: OK"
[ -f build/bin/llama-server ] && echo "llama-server: OK"
EOF

# 上传并执行
scp -P 8022 build-llama.sh termux:~/
ssh termux "/data/data/com.termux/files/usr/bin/bash /data/data/com.termux/files/home/build-llama.sh"
```

编译耗时：通常 5-15 分钟，取决于设备性能。

### 阶段 5：下载 GGUF 模型

**推荐模型规格**：
| 手机内存 | 推荐模型 |
|----------|----------|
| 6GB RAM | 1B/1.5B/2B，Q4 或 Q5 |
| 8GB RAM | 3B，Q4_K_M |
| 12GB RAM | 3B/7B Q4，勉强可用 |
| 16GB+ RAM | 7B Q4 较稳 |

**推荐小模型**：
- Qwen2.5-1.5B-Instruct-GGUF
- Qwen2.5-3B-Instruct-GGUF
- Llama-3.2-1B-Instruct-GGUF
- Phi-3.5-mini-instruct-GGUF

**下载方式**：
```bash
# 方案 1：Termux 直接下载（需要网络）
ssh termux "mkdir -p ~/models && cd ~/models && wget -O model.gguf 'HUGGINGFACE_URL'"

# 方案 2：Windows 下载后上传（推荐）
scp -P 8022 model.gguf termux:~/models/
```

常见下载地址：
- https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF
- https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF

### 阶段 6：运行

**命令行推理**：
```bash
ssh termux "cd ~/llama.cpp && ./build/bin/llama-cli \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  -p '用中文解释什么是边缘计算' \
  -n 256 -t 6 -c 2048"
```

**启动 OpenAI 兼容 API 服务**：
```bash
ssh termux "cd ~/llama.cpp && ./build/bin/llama-server \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  --host 0.0.0.0 --port 8080 \
  -c 2048 -t 6"
```

API 地址：`http://手机IP:8080/v1/chat/completions`

**测试 API**：
```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "用中文解释什么是 GGUF"}],
    "temperature": 0.7,
    "max_tokens": 300
  }'
```

## 性能建议

1. **线程数**：不要设太大，8 核手机用 `-t 4` 或 `-t 6` 更稳
2. **上下文长度**：建议 `-c 1024` 或 `-c 2048`，不要一开始设 8192+
3. **模型选择**：不要一开始跑 7B，从 1.5B/3B Q4 开始
4. **防止后台被杀**：
   - 保持屏幕亮着
   - 关闭 Termux 电池优化
   - 长期稳定用 Termux:Boot + USB 网络共享

## 关键路径速查

| 项目 | Termux 路径 |
|------|-------------|
| llama.cpp 源码 | `~/llama.cpp` |
| 编译输出 | `~/llama.cpp/build/bin/` |
| 模型目录 | `~/models/` |
| llama-server | `~/llama.cpp/build/bin/llama-server` |
| llama-cli | `~/llama.cpp/build/bin/llama-cli` |

## 常见问题

**Q: 编译失败，提示找不到 CMakeLists.txt**  
A: 确认当前目录是 `~/llama.cpp`，不是 home 目录

**Q: 运行时提示找不到共享库**  
A: 设置 `LD_LIBRARY_PATH=~/llama.cpp/build/bin`

**Q: 手机发热严重/进程被杀**  
A: 降低线程数（-t 4）、减小上下文（-c 1024）、换更小的模型

**Q: 锁屏后 SSH 断开**  
A: Android 锁屏会切断 WiFi，这是系统行为。解决：
- 开发者选项开启「休眠时始终保持 WLAN」
- 使用 USB 网络共享（最稳定）
- 保持屏幕常亮
