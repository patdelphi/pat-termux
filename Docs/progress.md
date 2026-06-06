# Termux Llama.cpp 环境配置

## 项目概述

在 Termux/Android 设备上部署 llama.cpp，实现本地 LLM 推理和 OpenAI 兼容 API 服务。

## 环境信息

- **Termux SSH**: `ssh termux` (端口 8022, IP 192.168.71.83)
- **镜像源**: 阿里云 `https://mirrors.aliyun.com/termux/termux-main`
- **设备架构**: aarch64 (ARM64)
- **设备内存**: 14GB RAM + 15GB Swap
- **网络代理**: Windows本机代理 `http://192.168.71.199:7890`
- **编译工具**: Clang 21.1.8, CMake 4.3.3
- **llama.cpp版本**: commit 2016bf2b3, version 0.13.1, build 9528

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

4. **配置网络代理** (2026-06-05)
   - Windows代理: `http://192.168.71.199:7890`
   - Termux环境变量已配置 (写入 ~/.bashrc)
   - GitHub访问恢复正常
   - 脚本: `setup/setup-proxy.sh`

5. **编译 llama.cpp** (2026-06-05)
   - **方案**: Windows下载源码 → SCP上传 → Termux编译
   - **问题**: Android Bionic libc 缺少 `spawn.h`,导致 llama-server 编译失败
   - **解决**: 创建完整 `spawn.h` stub (实现 fork+exec 替代 posix_spawn)
   - **编译产物**:
     - `llama-cli` ✅ (主推理工具,已验证)
     - `llama-quantize` ✅ (模型量化工具)
     - `llama-gguf-split` ✅ (模型分割工具)
     - `llama-imatrix` ✅ (重要性矩阵)
     - `llama-bench` ✅ (性能测试)
     - `llama-tts` ✅ (文本转语音)
     - `llama-mtmd-cli` ✅ (多模态推理)
     - 等18个工具

6. **下载 Qwen3.5-2B 模型** (2026-06-05)
   - **模型**: Qwen3.5-2B Q4_K_M (GGUF格式)
   - **大小**: 1.3GB
   - **来源**: HuggingFace `prithivMLmods/Qwen3.5-2B-MTP-GGUF`
   - **路径**: `~/models/qwen3.5-2b-q4km.gguf`

7. **验证模型推理** (2026-06-05)
   - **工具**: `llama-cli`
   - **提示词**: "你好,请用一句话介绍自己"
   - **性能**:
     - Prompt处理: 40.9-45.8 t/s
     - 文本生成: 18.1 t/s
   - **结果**: ✅ 模型正常运行,成功识别Qwen3.5身份

8. **部署 llama.cpp 自带 Web UI** (2026-06-06)
   - **工具**: `llama-server`
   - **访问地址**: `http://192.168.71.83:8080`
   - **监听地址**: `0.0.0.0:8080`
   - **模型**: `~/models/qwen3.5-2b-q4km.gguf`
   - **参数**: `-c 2048 -t 4`
   - **日志**: `~/llama-server-8080.log`
   - **验证**:
     - `http://192.168.71.83:8080` 返回 200
     - `http://192.168.71.83:8080/health` 返回 `{"status":"ok"}`
   - **结果**: ✅ 手机浏览器和局域网设备可访问 Web UI

9. **创建一键启动脚本 startllama** (2026-06-06)
   - **本地脚本**: `setup/startllama`
   - **Termux路径**:
     - `~/startllama`
     - `~/.local/bin/startllama`
   - **能力**:
     - 检查 `llama-server` 和模型文件
     - 避免重复启动已运行服务
     - 后台启动 Web UI
     - 自动健康检查 `/health`
     - 支持通过环境变量覆盖 `PORT`, `THREADS`, `CTX_SIZE`, `MODEL_PATH`, `ACCESS_HOST`
   - **验证**: `bash -n` 语法检查通过，远端执行健康检查通过

### ⏳ 待执行

10. 安装 Android 客户端 (Box App, 可选)
11. 下载更多 GGUF 模型 (如 Qwen2.5-3B, Llama-3.2-3B)
12. 测试 llama-server OpenAI 兼容 API
13. 配置 Termux 后台保活 (防止休眠断连)
14. 评估是否仍需要额外 Python WebUI (当前 llama.cpp 自带 Web UI 已可用)

## 脚本清单

| 脚本 | 作用 | 状态 |
|------|------|------|
| `setup/fix-repo.sh` | 修复镜像源配置 | ✅ 已执行 |
| `setup/install-deps.sh` | 安装编译依赖 | ✅ 已执行 |
| `setup/setup-proxy.sh` | 配置网络代理 | ✅ 已执行 |
| `setup/build-llama.sh` | 编译 llama.cpp | ✅ 已执行(完全成功) |
| `setup/boot.sh` | Termux 开机自启 sshd | ✅ 已存在 |
| `setup/change-repo.sh` | 切换镜像源 | ✅ 已存在 |
| `setup/verify-repo.sh` | 验证镜像源 | ✅ 已存在 |
| `setup/fix-x11.sh` | 修复 X11 配置 | ✅ 已存在 |
| `setup/spawn.h` | Android spawn.h 完整实现 | ✅ 已创建(已解决编译问题) |
| `setup/startllama` | 一键启动 llama.cpp Web UI | ✅ 已创建并部署到 Termux |

## 已知问题

### 手机休眠导致 SSH 断连

**现象**: Termux 后台运行时,手机休眠会导致 SSH 连接超时

**影响**:
- 长时间推理任务可能被中断
- 需要唤醒手机后重新连接

**临时方案**:
- 保持屏幕常亮
- 使用 `nohup` 或 `tmux` 后台运行任务

**解决方向**:
1. 安装 `termux-services` 配置后台保活
2. 使用 WakeLock 防止手机休眠
3. 配置 Termux 通知栏常驻

### spawn.h 问题 (已解决)

**问题**: Android Bionic libc 不包含完整的 POSIX spawn.h

**解决方案**: 创建完整 stub 实现 (`setup/spawn.h`)
- 实现了 `posix_spawn`, `posix_spawnp`
- 实现了 `posix_spawn_file_actions_*` 系列函数
- 使用 `fork + execv/execvp` 替代原生实现
- 已复制到系统路径 `/data/data/com.termux/files/usr/include/spawn.h`

## 模型信息

### 已部署模型

| 模型 | 路径 | 大小 | 量化 | 状态 |
|------|------|------|------|------|
| Qwen3.5-2B | `~/models/qwen3.5-2b-q4km.gguf` | 1.3GB | Q4_K_M | ✅ 已验证 |

### 推荐下载模型

| 模型 | 推荐规格 | 适合内存 | 说明 |
|------|----------|----------|------|
| Qwen2.5-1.5B-Instruct | Q4_K_M | 4GB+ | 轻量,速度快 |
| Qwen2.5-3B-Instruct | Q4_K_M | 6GB+ | 平衡性能 |
| Llama-3.2-3B-Instruct | Q4_K_M | 6GB+ | Meta官方,英文强 |
| Gemma-2-2B-it | Q4_K_M | 4GB+ | Google,多语言 |

## 下一步操作

### 启动 llama.cpp 自带 Web UI

```bash
# 在 Termux 执行
startllama

# 或显式指定参数
PORT=8081 THREADS=6 CTX_SIZE=2048 startllama
```

浏览器访问:

```text
http://192.168.71.83:8080
```

### 当前可用工具

```bash
# 命令行推理
~/llama.cpp/build/bin/llama-cli \
  -m ~/models/qwen3.5-2b-q4km.gguf \
  -p "用中文解释什么是边缘计算" \
  -n 256 -t 4 -c 2048

# 模型量化
~/llama.cpp/build/bin/llama-quantize --help

# 性能测试
~/llama.cpp/build/bin/llama-bench --help
```

## 性能基准

| 测试项 | 数值 | 说明 |
|--------|------|------|
| 模型加载 | ~60秒 | 1.3GB模型加载到内存 |
| Prompt处理 | 40-46 t/s | 短提示处理速度 |
| 文本生成 | 18 t/s | 生成速度(4线程) |
| 内存占用 | ~3GB | 运行时总内存 |
| CPU占用 | 30-40% | 4线程运行时 |

## 版本记录

| 日期 | 操作 | 结果 |
|------|------|------|
| 2026-06-05 | SSH配置更新 | IP改为192.168.71.83 |
| 2026-06-05 | 代理配置 | 成功,写入~/.bashrc |
| 2026-06-05 | llama.cpp编译 | 完全成功,所有工具可用 |
| 2026-06-05 | spawn.h修复 | 完整stub实现,解决编译问题 |
| 2026-06-05 | 模型下载 | Qwen3.5-2B Q4_K_M 1.3GB |
| 2026-06-05 | 推理验证 | 成功,18 t/s生成速度 |
| 2026-06-06 | llama-server补编译 | 成功生成 `build/bin/llama-server` |
| 2026-06-06 | Web UI部署 | `http://192.168.71.83:8080` 可访问 |
| 2026-06-06 | startllama脚本 | 已部署到 Termux 并验证健康检查 |
