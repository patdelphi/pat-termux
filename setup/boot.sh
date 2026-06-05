#!/data/data/com.termux/files/usr/bin/bash
# Termux 启动脚本：获取唤醒锁 + 启动 sshd

# 获取唤醒锁，防止系统休眠杀死进程
termux-wake-lock

# 等待 2 秒确保网络就绪
sleep 2

# 启动 SSH 服务
sshd

# 输出状态
echo "SSH is running on port 8022"
echo "Connect with: ssh -p 8022 u0_a299@<phone-ip>"
