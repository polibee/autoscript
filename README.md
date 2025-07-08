# Boundless VPS 自动化部署和管理脚本

> 作者: [Coinowodrop](https://x.com/Coinowodrop)  
> 网站: [coinowo.com](https://coinowo.com/)  
> 项目: Boundless ZK Prover 自动化部署工具

## 📋 项目简介

这是一套用于自动化部署和管理 Boundless ZK Prover 节点的脚本工具。Boundless 是一个零知识证明项目，采用竞标机制，类似抢单模式。系统由两个主要组件组成：

- **Bento**: 本地证明基础设施，负责接收请求、生成证明并返回结果
- **Broker**: 与 Boundless 市场交互，获取订单分配给 Bento 计算验证，再将结果返回

## 🎯 功能特性

### ✅ 自动化安装
- 系统环境检测和依赖安装
- Docker 和 NVIDIA Docker 支持自动配置
- Rust 工具链自动安装
- Boundless 项目自动克隆和配置

### 🔧 服务管理
- 一键启动/停止服务
- 实时日志查看
- 服务状态监控
- 自动重启和故障恢复

### 📊 监控和维护
- GPU 使用情况监控
- 系统资源监控
- 配置备份和恢复
- 自动更新功能

### 🖥️ 跨平台支持
- Linux 原生支持 (推荐 Ubuntu 22.04)
- Windows WSL 支持
- 自动环境配置

## 📁 文件说明

```
boundless_scripts/
├── boundless_auto_deploy.sh      # Linux 主脚本
├── boundless_auto_deploy.ps1     # Windows PowerShell 脚本
├── config_template.json          # 配置文件模板
├── README.md                     # 使用说明文档
├── boundless.md                  # 原始部署文档
└── author.md                     # 作者信息
```

## 🚀 快速开始

### Linux 环境 (推荐)

1. **下载脚本**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/boundless_auto_deploy.sh
   chmod +x boundless_auto_deploy.sh
   ```

2. **完整安装**
   ```bash
   ./boundless_auto_deploy.sh install
   ```

3. **运行测试**
   ```bash
   ./boundless_auto_deploy.sh test
   ```

4. **启动服务**
   ```bash
   ./boundless_auto_deploy.sh start
   ```

### Windows 环境 (WSL)

1. **以管理员身份运行 PowerShell**

2. **执行安装**
   ```powershell
   .\boundless_auto_deploy.ps1 install
   ```

3. **检查 WSL 状态**
   ```powershell
   .\boundless_auto_deploy.ps1 wsl-status
   ```

4. **启动服务**
   ```powershell
   .\boundless_auto_deploy.ps1 start
   ```

## ⚙️ 配置说明

### 环境变量配置

脚本会提示您输入以下必要信息：

- **PRIVATE_KEY**: 钱包私钥（确保有足够资金）
- **RPC_URL**: RPC 端点（推荐使用 Alchemy）
- **SEGMENT_SIZE**: 段大小（默认 21，根据 GPU 内存调整）

### GPU 内存要求

| Segment Size | GPU 内存需求 | 适用 GPU |
|--------------|-------------|----------|
| 20 | 8GB | RTX 3070, RTX 4060 Ti |
| 21 | 16GB | RTX 3080, RTX 4070 Ti |
| 22 | 32GB | RTX 3090, RTX 4090 |

### RPC 端点配置

**Base Mainnet:**
```
https://base-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_APP_ID
```

**Base Sepolia (测试网):**
```
https://base-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_APP_ID
```

## 📋 命令参考

### Linux 脚本命令

```bash
# 安装相关
./boundless_auto_deploy.sh install     # 完整安装
./boundless_auto_deploy.sh config      # 重新配置

# 服务管理
./boundless_auto_deploy.sh start       # 启动服务
./boundless_auto_deploy.sh stop        # 停止服务
./boundless_auto_deploy.sh restart     # 重启服务
./boundless_auto_deploy.sh status      # 查看状态

# 监控和日志
./boundless_auto_deploy.sh logs        # 查看日志
./boundless_auto_deploy.sh monitor     # 实时监控

# 测试和维护
./boundless_auto_deploy.sh test        # 运行测试
./boundless_auto_deploy.sh update      # 更新系统
./boundless_auto_deploy.sh backup      # 备份配置
./boundless_auto_deploy.sh clean       # 清理系统
```

### Windows 脚本命令

```powershell
# WSL 管理
.\boundless_auto_deploy.ps1 wsl-status  # 检查 WSL 状态
.\boundless_auto_deploy.ps1 install     # 安装（包括 WSL）

# 服务管理（其他命令与 Linux 版本相同）
.\boundless_auto_deploy.ps1 start
.\boundless_auto_deploy.ps1 stop
.\boundless_auto_deploy.ps1 status
```

## 🔍 监控和故障排除

### 查看服务状态
```bash
./boundless_auto_deploy.sh status
```

### 实时监控
```bash
./boundless_auto_deploy.sh monitor
```

### 查看日志
```bash
./boundless_auto_deploy.sh logs
```

### 常见问题解决

1. **GPU 未检测到**
   - 检查 NVIDIA 驱动安装
   - 验证 Docker GPU 支持
   ```bash
   nvidia-smi
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

2. **内存不足错误**
   - 降低 SEGMENT_SIZE
   - 减少并发证明数量
   - 检查 GPU 内存使用情况

3. **网络连接错误**
   - 验证 RPC URL 正确性
   - 检查网络连接
   - 尝试更换 RPC 端点

4. **权限错误**
   - 确保用户在 docker 组中
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

5. **服务启动失败**
   - 检查详细日志
   - 验证配置文件
   - 重新运行安装脚本

## 📈 性能优化建议

### 硬件优化
- 使用 SSD 存储提高 I/O 性能
- 确保 GPU 有良好的散热
- 配置足够的系统内存（推荐 16GB+）

### 软件优化
- 根据 GPU 内存选择合适的 segment_size
- 调整并发证明数量
- 使用稳定的 RPC 端点
- 定期更新系统和依赖

### 网络优化
- 使用低延迟的网络连接
- 配置多个 RPC 端点作为备份
- 监控网络连接质量

## 🔐 安全注意事项

1. **私钥安全**
   - 妥善保管私钥，不要泄露
   - 使用专用钱包进行证明
   - 定期备份配置文件

2. **系统安全**
   - 保持系统和依赖更新
   - 配置防火墙规则
   - 监控系统日志

3. **网络安全**
   - 使用 HTTPS RPC 端点
   - 避免在公共网络上运行
   - 配置 VPN 保护

## 📊 市场信息

- **当前全网 Provers**: ~30+ 个
- **竞标机制**: 类似抢单模式
- **激励测试网**: 即将推出
- **浏览器**: [Boundless Explorer](https://explorer.boundless.xyz)

## 🔗 相关链接

- **官方文档**: [docs.boundless.xyz](https://docs.boundless.xyz)
- **Discord 社区**: [discord.gg/boundless](https://discord.gg/boundless)
- **GitHub 仓库**: [github.com/boundless-xyz/boundless](https://github.com/boundless-xyz/boundless)
- **项目浏览器**: [explorer.boundless.xyz](https://explorer.boundless.xyz)

## 👨‍💻 作者信息

- **Twitter**: [@Coinowodrop](https://x.com/Coinowodrop)
- **网站**: [coinowo.com](https://coinowo.com/)
- **项目**: Boundless ZK Prover 自动化部署工具

## 📝 更新日志

### v1.0 (当前版本)
- ✅ 完整的自动化安装流程
- ✅ 跨平台支持 (Linux/Windows WSL)
- ✅ 服务管理和监控功能
- ✅ 配置备份和恢复
- ✅ 故障排除和性能优化

### 计划功能
- 🔄 Web 管理界面
- 📱 移动端监控应用
- 🤖 自动化告警系统
- 📈 性能分析报告
- 🔧 一键优化建议

## 🤝 贡献和反馈

欢迎提交 Issue 和 Pull Request！

如果这个工具对您有帮助，请考虑：
- ⭐ 给项目点个星
- 🐦 在 Twitter 上关注作者
- 💬 加入 Discord 社区交流

---

**免责声明**: 本工具仅供学习和研究使用，使用前请确保了解相关风险。作者不对使用本工具造成的任何损失承担责任。