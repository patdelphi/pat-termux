---
name: termux-remote-management
description: 通过 SSH 远程管理 Termux 设备时的可靠命令执行模式，解决变量展开和引号转义问题
source: auto-skill
extracted_at: '2026-06-05T09:24:49.202Z'
---

# Termux SSH 远程管理

## 问题

通过 SSH 从 Windows 向 Termux 发送命令时，`$PREFIX` 等环境变量会被**本地 Shell 先展开**，导致远程执行失败：

```bash
# 错误：$PREFIX 被本地展开为空字符串
ssh termux "cat $PREFIX/etc/apt/sources.list"
# 实际执行的是: cat /etc/apt/sources.list （本地路径）

# 错误：单引号在 Windows cmd 中不生效
ssh termux 'sed -i "s|old|new|" $PREFIX/etc/apt/sources.list'
# Windows cmd 不识别单引号引用，会报 unexpected EOF
```

## 解决方案：脚本上传模式

**不要在 SSH 命令中直接执行复杂操作**，而是：

### 步骤 1：在本地创建 Shell 脚本

```bash
#!/bin/bash
# 脚本中使用正常的 $PREFIX 等变量，不会被提前展开
sed -i 's|old|new|' $PREFIX/etc/apt/sources.list
cat $PREFIX/etc/apt/sources.list
```

### 步骤 2：通过 SCP 上传到 Termux

```bash
scp -P 8022 "本地路径\script.sh" termux:~/script.sh
```

### 步骤 3：用绝对路径执行

```bash
# 使用 Termux 的绝对路径，避免 bash 找不到的问题
ssh termux "/data/data/com.termux/files/usr/bin/bash /data/data/com.termux/files/home/script.sh"
```

## SSH 配置参考

```
Host termux
    HostName 192.168.10.100
    User u0_a299
    Port 8022
    IdentityFile C:/Users/patde/.ssh/id_ed25519_termux
    IdentitiesOnly yes
    StrictHostKeyChecking no
```

## 关键路径速查

| 项目 | Termux 绝对路径 |
|------|----------------|
| bash | `/data/data/com.termux/files/usr/bin/bash` |
| home | `/data/data/com.termux/files/home` |
| PREFIX | `/data/data/com.termux/files/usr` |

## 注意事项

- SSH 连接可能因网络波动断开，复杂操作建议分步执行并验证
- `termux-change-repo` 等交互式命令无法通过 SSH 非交互调用
- Termux sshd 默认端口是 **8022**，不是 22
- 手机可能休眠导致 SSH 超时，保活见 Termux 保活指南
