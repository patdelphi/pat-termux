## 结论

在 **Termux / Android** 下：

| 方案                           | 可行性 |          推荐度 | 说明                                                                      |
| ---------------------------- | --: | -----------: | ----------------------------------------------------------------------- |
| **llama.cpp / llama-server** |   高 |            高 | 最现实，支持 GGUF，CPU 可跑，部分设备可尝试 OpenCL/GPU                                   |
| **vLLM**                     |   低 |          不推荐 | vLLM 主要面向 Linux 服务器、CUDA/ROCm/XPU/CPU 等环境；Termux/Android 不是常规目标环境，依赖链很重 |
| **Ollama**                   | 低到中 | 不如 llama.cpp | Android/Termux 上可折腾，但兼容性和资源占用不如 llama.cpp 稳                             |

llama.cpp 官方有 Android 相关文档，社区也长期用 Termux 编译运行；vLLM 官方安装文档面向 GPU、CPU、Linux 等后端，但 Android/Termux 不属于它的常规部署路径。([GitHub][1])

---

# 一、Termux 跑 llama.cpp

## 1. 安装 Termux

建议从 **F-Droid** 安装最新版 Termux，不建议用 Play Store 旧版。

然后执行：

```bash
pkg update && pkg upgrade -y
termux-setup-storage
```

---

## 2. 安装依赖

```bash
pkg install -y git cmake clang make wget curl
```

可选：

```bash
pkg install -y python
```

---

## 3. 拉取 llama.cpp

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
```

---

## 4. 编译 CPU 版本

```bash
cmake -B build
cmake --build build --config Release -j$(nproc)
```

编译完成后，主要二进制文件在：

```bash
./build/bin/
```

常用的是：

```bash
./build/bin/llama-cli
./build/bin/llama-server
```

llama.cpp 的 Android/Termux 路线核心就是：在 Android 上编译 llama.cpp，然后用 GGUF 模型推理。([GitHub][1])

---

# 二、下载 GGUF 模型

建议从小模型开始。

## 推荐模型规格

|      手机内存 | 推荐模型                   |
| --------: | ---------------------- |
|   6GB RAM | 1B / 1.5B / 2B，Q4 或 Q5 |
|   8GB RAM | 3B，Q4_K_M              |
|  12GB RAM | 3B / 7B Q4，勉强可用        |
| 16GB+ RAM | 7B Q4 较稳               |

常见选择：

```text
Qwen2.5-1.5B-Instruct-GGUF
Qwen2.5-3B-Instruct-GGUF
Llama-3.2-1B-Instruct-GGUF
Llama-3.2-3B-Instruct-GGUF
Phi-3.5-mini-instruct-GGUF
Gemma-2-2B-it-GGUF
```

下载示例：

```bash
mkdir -p ~/models
cd ~/models

wget -O qwen2.5-1.5b-q4.gguf "模型下载地址"
```

实际下载地址通常来自 Hugging Face 的 GGUF 仓库。

---

# 三、命令行运行

```bash
cd ~/llama.cpp

./build/bin/llama-cli \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  -p "用中文解释什么是边缘计算" \
  -n 256
```

参数说明：

| 参数   | 含义           |
| ---- | ------------ |
| `-m` | 模型路径         |
| `-p` | 输入提示词        |
| `-n` | 最大生成 token 数 |
| `-t` | CPU 线程数      |
| `-c` | 上下文长度        |

例如指定线程和上下文：

```bash
./build/bin/llama-cli \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  -p "介绍一下 ESP32-S3 的多媒体能力" \
  -n 512 \
  -t 6 \
  -c 2048
```

---

# 四、启动 OpenAI 兼容 API 服务

这是最实用的方式，可以让浏览器、App、第三方工具调用本地模型。

```bash
./build/bin/llama-server \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 2048 \
  -t 6
```

本机访问：

```text
http://127.0.0.1:8080
```

如果其他设备访问，需要手机和电脑在同一局域网，并查看手机 IP：

```bash
ip addr
```

API 地址类似：

```text
http://手机IP:8080/v1/chat/completions
```

社区示例中也常用 `llama-server` 在 Termux 里启动本地 HTTP 服务，然后让前端 App 连接 `localhost:8080`。([Gist][2])

---

# 五、用 curl 测试 API

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [
      {"role": "user", "content": "用中文解释什么是 GGUF"}
    ],
    "temperature": 0.7,
    "max_tokens": 300
  }'
```

---

# 六、性能建议

## 1. 不要一开始跑 7B

Android 手机跑 7B 很容易：

* 首 token 很慢
* 发热严重
* 后台被系统杀进程
* 内存不足

建议先跑：

```text
1.5B Q4
3B Q4_K_M
```

---

## 2. 控制上下文长度

上下文越长，内存越高。

建议：

```bash
-c 1024
-c 2048
```

不要一开始设：

```bash
-c 8192
-c 32768
```

---

## 3. 控制线程数

线程数不是越大越好。

例如 8 核手机可以试：

```bash
-t 4
-t 6
-t 8
```

一般 `4~6` 比较稳，发热更低。

---

## 4. 防止 Termux 后台被杀

可以安装：

```bash
pkg install termux-services
```

或者运行时保持屏幕亮着。部分手机需要在系统设置里关闭 Termux 的电池优化。

---

# 七、OpenCL / GPU 加速是否值得搞？

部分 Android 设备可以尝试 OpenCL 后端，但不保证稳定。

大致路线是：

```bash
pkg install -y ocl-icd opencl-headers clinfo
```

然后检查：

```bash
clinfo
```

如果能识别 GPU，再尝试编译 CLBlast/OpenCL 相关版本。

但现实情况是：

| 方案                   | 稳定性                     |
| -------------------- | ----------------------- |
| CPU 跑 llama.cpp      | 最稳                      |
| Android GPU / OpenCL | 看设备，容易踩坑                |
| Vulkan               | 有潜力，但 Android 上仍需具体设备测试 |
| vLLM GPU             | 基本不适合 Termux            |

---

# 八、vLLM 在 Termux 下为什么不推荐

vLLM 的核心价值是高吞吐服务、PagedAttention、批量请求调度，主要用于服务器推理。官方文档列出的安装平台包括 NVIDIA CUDA、AMD ROCm、Intel XPU、Apple Silicon、CPU 等，但实际生产部署通常依赖完整 Linux、Python、PyTorch、编译工具链和硬件后端。([vLLM][3])

Termux 的问题是：

```text
Android libc / bionic
非标准 Linux 发行版环境
PyTorch wheel 兼容性问题
CUDA 不存在
ROCm 不存在
移动端 GPU 驱动不可控
编译依赖复杂
收益很低
```

所以：

```text
Termux 跑 vLLM：理论上可折腾 CPU/AArch64 源码编译，但不建议。
Termux 跑 llama.cpp：实际可用。
```

---

# 推荐命令汇总

```bash
pkg update && pkg upgrade -y
termux-setup-storage

pkg install -y git cmake clang make wget curl

git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

cmake -B build
cmake --build build --config Release -j$(nproc)

mkdir -p ~/models
cd ~/models
# 下载一个 GGUF 模型到这里，例如 qwen2.5-1.5b-q4.gguf

cd ~/llama.cpp

./build/bin/llama-server \
  -m ~/models/qwen2.5-1.5b-q4.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 2048 \
  -t 6
```

---

## 最佳实践

在 Termux 下本地跑 LLM，优先选择：

```text
llama.cpp + GGUF + 1.5B/3B Q4 模型
```

不要优先折腾：

```text
vLLM
Ollama
Transformers + PyTorch
```

除非目标是研究兼容性，而不是稳定使用。

[1]: https://github.com/ggml-org/llama.cpp/blob/master/docs/android.md?utm_source=chatgpt.com "llama.cpp/docs/android.md at master · ggml-org ..."
[2]: https://gist.github.com/EnigmaCurry/747f3da8a8e8d62fa7849f1beae5c307?utm_source=chatgpt.com "Run Llama.cpp on Android in Termux"
[3]: https://docs.vllm.ai/en/latest/getting_started/installation/?utm_source=chatgpt.com "Installation - vLLM"
