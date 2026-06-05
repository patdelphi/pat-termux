# Termux Llama.cpp 环境配置

## 项目概述

在 Termux/Android 设备上部署 llama.cpp，实现本地 LLM 推理和 OpenAI 兼容 API 服务。

## 环境信息

- **Termux SSH**: `ssh termux` (端口 8022, IP 192.168.10.100)
- **镜像源**: 阿里云 `https://mirrors.aliyun.com/termux/termux-main`
- **设备架构**: aarch64 (ARM64)

## 执行进度

### ✅ 已完成

1. **修复镜像源** (2026-06-05)
   - 清华镜像源大量 404 错误
   - 切换到官方源后自动选择阿里云镜像
   - 脚本: `setup/fix-repo.sh`

2. **系统升级** (2026-06-05)
   - 升级 57 个系统包
   - 包含 openssl, git, cmake, python 等核心组件

3. **安装编译依赖** (2026-06-05)
   - git 2.54.0 ✅
   - cmake 4.3.3 ✅
   - clang 21.1.8 ✅
   - make 4.4.1 ✅
   - wget 1.25.0 ✅
   - curl 8.20.0 ✅
   - 脚本: `setup/install-deps.sh`

### ⏸️ 阻塞中

4. **编译 llama.cpp** (待解决)
   - **问题**: Termux 无法访问 GitHub (SSL 超时)
   - **测试**: `curl -I https://github.com` 超时
   - **备选方案**:
     - 方案 A: Windows 下载源码后 SCP 上传
     - 方案 B: Termux 配置网络代理

### ⏳ 待执行

5. 下载 GGUF 模型 (推荐 Qwen2.5-1.5B-Instruct-Q4)
6. 测试 llama-cli 命令行推理
7. 启动 llama-server OpenAI 兼容 API
8. 测试 API 接口

## 脚本清单

| 脚本 | 作用 | 状态 |
|------|------|------|
| `setup/fix-repo.sh` | 修复镜像源配置 | ✅ 已执行 |
| `setup/install-deps.sh` | 安装编译依赖 | ✅ 已执行 |
| `setup/build-llama.sh` | 编译 llama.cpp | ⏸️ 阻塞 |
| `setup/boot.sh` | Termux 开机自启 sshd | ✅ 已存在 |
| `setup/change-repo.sh` | 切换镜像源 | ✅ 已存在 |
| `setup/verify-repo.sh` | 验证镜像源 | ✅ 已存在 |
| `setup/fix-x11.sh` | 修复 X11 配置 | ✅ 已存在 |

## 下一步操作

### 方案 A: Windows 下载上传 (推荐)

```powershell
# 1. Windows 下载 llama.cpp
cd C:\Users\patde\Documents\Github\pat-termux
git clone https://github.com/ggml-org/llama.cpp

# 2. 上传到 Termux
scp -P 8022 -r llama.cpp termux:~/llama.cpp

# 3. 在 Termux 编译
ssh termux "cd ~/llama.cpp && cmake -B build && cmake --build build --config Release"
```

### 方案 B: Termux 配置代理

如果有 HTTP 代理 (例如 192.168.10.1:7890):

```bash
export https_proxy=http://192.168.10.1:7890
git clone https://github.com/ggml-org/llama.cpp
```

## 参考文档

- `setup-llama.md`: 完整的 llama.cpp 配置指南
- `memory/project/llama_termux_deployment.md`: 部署方案和锁屏断连问题

## 推荐配置

编译完成后启动服务:

```bash
./build/bin/llama-server \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 2048 \
  -t 6
```

API 测试:

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "你好"}],
    "temperature": 0.7,
    "max_tokens": 300
  }'
```
