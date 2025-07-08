# Boundless ZK Prover 一键安装脚本

🚀 **自动化部署和管理 Boundless ZK Prover 节点的完整解决方案**

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/polibee/autoscript)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://github.com/polibee/autoscript)

---

## 🎯 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/polibee/autoscript/main/install_boundless.sh | bash
```

> 🎉 **零配置安装**: 自动检测系统环境、安装依赖、配置GPU、设置网络，全程交互式引导！

---

## 🚀 三步开始挖矿

1. **🎯 一键安装**: 运行安装命令，脚本自动处理所有依赖
2. **⚙️ 交互配置**: 按提示选择网络、输入私钥、配置RPC
3. **🎮 开始挖矿**: 启动服务，开始赚取收益！

## ✨ 核心特性

- 🎯 **零门槛安装**: 一条命令完成所有安装和配置
- 🔧 **智能引导**: 交互式配置向导，新手友好
- 🌐 **网络灵活**: 支持Base主网/测试网一键切换
- 🎮 **GPU优化**: 自动检测配置NVIDIA GPU，支持多卡
- 📦 **模块化**: 可选择安装证明者、Broker或完整套件
- 🗑️ **干净卸载**: 一键清理所有安装内容和Docker资源
- 📊 **实时监控**: GPU状态、收益情况、系统资源全面监控
- 🎯 **成功检测**: 智能分析挖矿状态和订单成功率
- ⚡ **性能优化**: 基于社区经验的Broker配置优化
- 🔍 **故障诊断**: 全面的系统健康检查和问题诊断
- 🤖 **自动监控**: 后台监控挖矿状态，异常自动重启
- 🔒 **安全第一**: 私钥加密存储，权限严格控制
- 💾 **配置管理**: 支持配置备份、恢复和版本管理
- 🔄 **持续更新**: 自动检测和更新脚本及组件

## 🚀 快速开始

### ⚡ 一键安装 (推荐)

```bash
# 一键安装命令 (自动检测curl/wget)
curl -fsSL https://raw.githubusercontent.com/polibee/autoscript/main/install_boundless.sh | bash
```

> 💡 **提示**: 安装过程中会自动引导您完成网络选择、私钥配置、RPC设置等步骤

### 🔄 备用安装方法

```bash
# 如果curl不可用，使用wget
wget -qO- https://raw.githubusercontent.com/polibee/autoscript/main/install_boundless.sh | bash
```

### 手动下载安装

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/polibee/autoscript/main/install_boundless.sh

# 设置执行权限
chmod +x install_boundless.sh

# 运行安装
./install_boundless.sh
```

### 📥 手动下载安装

```bash
# 下载主脚本
wget https://raw.githubusercontent.com/polibee/autoscript/main/boundless_auto_deploy.sh
chmod +x boundless_auto_deploy.sh

# 开始安装
./boundless_auto_deploy.sh install
```

## ⚡ 快速命令参考

```bash
# 🚀 安装相关
./boundless_auto_deploy.sh install          # 完整安装
./boundless_auto_deploy.sh install-prover   # 仅安装证明者
./boundless_auto_deploy.sh install-broker   # 仅安装Broker

# 🎮 服务管理
./boundless_auto_deploy.sh start           # 启动服务
./boundless_auto_deploy.sh stop            # 停止服务
./boundless_auto_deploy.sh restart         # 重启服务
./boundless_auto_deploy.sh status          # 查看状态

# 📊 监控和日志
./boundless_auto_deploy.sh monitor         # 实时监控
./boundless_auto_deploy.sh logs            # 查看日志
./boundless_auto_deploy.sh logs-error      # 查看错误日志
./boundless_auto_deploy.sh gpu-info        # GPU信息
./boundless_auto_deploy.sh start-monitor   # 启动自动监控
./boundless_auto_deploy.sh stop-monitor    # 停止自动监控
./boundless_auto_deploy.sh performance     # 性能分析报告
./boundless_auto_deploy.sh diagnose        # 故障诊断检查

# ⚙️ 配置管理
./boundless_auto_deploy.sh config          # 交互式配置
./boundless_auto_deploy.sh switch-network  # 切换网络
./boundless_auto_deploy.sh optimize-broker # 优化Broker配置
./boundless_auto_deploy.sh backup          # 备份配置
./boundless_auto_deploy.sh restore         # 恢复配置
./boundless_auto_deploy.sh reset-config    # 重置配置

# 🗑️ 清理和卸载
./boundless_auto_deploy.sh clean           # 清理数据
./boundless_auto_deploy.sh uninstall       # 完全卸载
```

## 💻 系统要求

- **操作系统**: Ubuntu 22.04 LTS (推荐) 或其他Linux发行版
- **内存**: 至少 8GB RAM (推荐 16GB+)
- **存储**: 至少 20GB 可用空间
- **GPU**: NVIDIA GPU (推荐，用于加速证明生成)
- **网络**: 稳定的互联网连接
- **权限**: 具有sudo权限的普通用户账户

### GPU要求
- NVIDIA GPU with CUDA support
- NVIDIA驱动程序已安装
- 足够的GPU内存 (取决于SEGMENT_SIZE配置)

## 📋 安装选项

### 证明者 (Prover)
```bash
./boundless_auto_deploy.sh install-prover
```

### Broker
```bash
./boundless_auto_deploy.sh install-broker
```

### 完整安装 (推荐)
```bash
./boundless_auto_deploy.sh install
```

### 交互式配置
```bash
./boundless_auto_deploy.sh config
```

## 🎮 常用命令

```bash
# 启动服务
./boundless_auto_deploy.sh start

# 停止服务
./boundless_auto_deploy.sh stop

# 重启服务
./boundless_auto_deploy.sh restart

# 查看状态
./boundless_auto_deploy.sh status

# 查看日志
./boundless_auto_deploy.sh logs

# 运行测试
./boundless_auto_deploy.sh test

# 实时监控
./boundless_auto_deploy.sh monitor

# 显示GPU信息
./boundless_auto_deploy.sh gpu-info

# 查看帮助
./boundless_auto_deploy.sh help
```

## 🌐 网络配置

脚本支持以下网络:

### Base 主网 (推荐用于生产)
- **网络名称**: Base Mainnet
- **Chain ID**: 8453
- **RPC URL**: `https://base-mainnet.g.alchemy.com/v2/YOUR_API_KEY`
- **浏览器**: https://basescan.org
- **货币**: ETH

### Base 测试网 (推荐用于测试)
- **网络名称**: Base Sepolia
- **Chain ID**: 84532
- **RPC URL**: `https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY`
- **浏览器**: https://sepolia.basescan.org
- **货币**: ETH

### 网络切换
```bash
# 切换网络
./boundless_auto_deploy.sh switch-network
```

### ⚡ Broker配置优化
```bash
# 优化Broker配置以提高订单获取成功率
./boundless_auto_deploy.sh optimize-broker
```

优化内容包括：
- 🎯 降低最小价格以增加竞争力
- ⚡ 增加订单检查频率
- 🔒 优化锁定超时时间
- 🚀 提高响应速度
- ⛽ 优化gas配置
- 📊 性能参数调优

> **注意**: 配置优化后需要重启服务才能生效

## 🔧 RPC 配置

### 推荐的RPC提供商

1. **Alchemy** (推荐)
   - 注册: https://www.alchemy.com/
   - 免费额度: 每月300M请求
   - Base主网: `https://base-mainnet.g.alchemy.com/v2/YOUR_API_KEY`
   - Base测试网: `https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY`

2. **Infura**
   - 注册: https://infura.io/
   - 免费额度: 每天100K请求
   - Base主网: `https://base-mainnet.infura.io/v3/YOUR_PROJECT_ID`

3. **QuickNode**
   - 注册: https://www.quicknode.com/
   - 提供专用端点

4. **公共RPC** (仅用于测试)
   - Base主网: `https://mainnet.base.org`
   - Base测试网: `https://sepolia.base.org`

> ⚠️ **注意**: 生产环境强烈建议使用付费RPC服务以确保稳定性和性能

## ⚙️ 配置说明

### 私钥配置
- **用途**: 代表您的证明者在市场上进行交易
- **安全**: 私钥将加密存储，文件权限设为600
- **格式**: 64位十六进制字符，支持0x前缀
- **资金**: 确保钱包有足够ETH用于质押和gas费用
- **备份**: 请务必备份您的私钥

### GPU配置
- **自动检测**: 脚本自动检测NVIDIA GPU数量和型号
- **多GPU支持**: 自动配置多GPU环境
- **内存监控**: 实时显示GPU内存使用情况
- **温度监控**: 监控GPU温度防止过热

### 段大小 (SEGMENT_SIZE)
- **作用**: 控制证明生成的内存使用和性能
- **推荐值**: 21 (适合8GB+ GPU内存)
- **调整范围**: 16-24
- **选择建议**:
  - GPU内存 < 8GB: 使用16-18
  - GPU内存 8-16GB: 使用19-21
  - GPU内存 > 16GB: 使用22-24

### 网络选择
- **测试网**: 适合初学者，免费获取测试币
- **主网**: 生产环境，需要真实ETH
- **切换**: 支持运行时网络切换

## 📊 监控和日志

### 实时监控
```bash
# 启动监控面板 (每30秒刷新)
./boundless_auto_deploy.sh monitor

# 启动自动监控（后台运行）
./boundless_auto_deploy.sh start-monitor

# 停止自动监控
./boundless_auto_deploy.sh stop-monitor
```

### 🎯 挖矿成功检测
脚本会自动分析挖矿状态，包括：
- ✅ 成功锁定订单数量
- 🎯 完成订单数量
- ❌ 锁定失败次数
- ⏰ 订单过期情况
- 📊 锁定成功率计算
- 📈 最近订单活动追踪

### ⚡ 性能分析
```bash
# 执行性能分析
./boundless_auto_deploy.sh performance
```

性能分析包括：
- 🖥️ GPU性能监控（使用率、温度、功耗）
- 🌐 网络延迟测试
- 💾 系统资源分析
- ⛏️ 挖矿效率统计
- 💡 性能优化建议

### 🔍 故障诊断
```bash
# 执行故障诊断
./boundless_auto_deploy.sh diagnose
```

诊断检查项目：
- 🐳 Docker服务状态
- 📦 容器运行状态
- 🖥️ GPU驱动检查
- 🌐 网络连接测试
- 📄 配置文件完整性
- 💾 磁盘空间检查

### 查看日志
```bash
# 交互式日志查看
./boundless_auto_deploy.sh logs

# 选项:
# 1) Broker 日志
# 2) Bento 日志  
# 3) 实时日志 (跟踪模式)
# 4) 错误日志
```

### 服务状态
```bash
./boundless_auto_deploy.sh status
```

**显示信息**:
- Docker容器运行状态
- GPU使用率、内存、温度
- CPU和系统内存使用
- 磁盘空间使用情况

### GPU信息
```bash
# 详细GPU信息
./boundless_auto_deploy.sh gpu-info
```

## 🔄 网络切换

```bash
# 切换网络配置
./boundless_auto_deploy.sh switch-network
```

**切换流程**:
1. 显示当前网络状态
2. 选择目标网络 (主网/测试网)
3. 配置新的RPC URL
4. 自动更新配置文件
5. 提示重启服务

**注意事项**:
- 切换网络后需要重启服务
- 不同网络的代币和合约地址不同
- 测试网代币无实际价值

## 🗑️ 卸载

```bash
# 完全卸载 Boundless (需要输入 'YES' 确认)
./boundless_auto_deploy.sh uninstall
```

**卸载内容**:
- 停止所有运行中的服务
- 删除Docker容器、镜像和卷
- 清理安装目录和配置文件
- 删除日志和备份文件
- 卸载CLI工具 (boundless-cli, bento_cli, just)
- 清理Docker系统缓存

**安全提示**:
- 卸载前请备份重要配置
- 确保已停止所有挖矿活动
- 私钥文件将被删除，请提前备份

## 🛠️ 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 检查用户是否在docker组中
   groups $USER
   
   # 如果不在，添加用户到docker组
   sudo usermod -aG docker $USER
   
   # 重新登录或重启系统
   ```

2. **GPU未检测到**
   ```bash
   # 检查NVIDIA驱动
   nvidia-smi
   
   # 检查NVIDIA Docker支持
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   
   # 重新安装GPU支持
   ./boundless_auto_deploy.sh install-prover
   ```

3. **服务启动失败**
   ```bash
   # 查看详细错误日志
   ./boundless_auto_deploy.sh logs
   
   # 检查Docker容器状态
   docker ps -a
   
   # 重新配置
   ./boundless_auto_deploy.sh config
   ```

4. **网络连接问题**
   ```bash
   # 测试RPC连接
   curl -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        YOUR_RPC_URL
   
   # 切换到不同的RPC提供商
   ./boundless_auto_deploy.sh switch-network
   ```

5. **内存不足**
   ```bash
   # 检查系统资源
   free -h
   df -h
   
   # 调整SEGMENT_SIZE
   ./boundless_auto_deploy.sh config
   ```

6. **配置文件损坏**
   ```bash
   # 重置配置
   ./boundless_auto_deploy.sh reset-config
   
   # 或恢复备份
   ./boundless_auto_deploy.sh restore
   ```

## 🤝 贡献

欢迎提交问题和改进建议!

### 如何贡献
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

### 报告问题
- 使用GitHub Issues报告bug
- 提供详细的错误信息和日志
- 说明您的系统环境和配置

### 功能请求
- 在Issues中描述新功能需求
- 解释功能的用途和价值
- 提供实现建议（如果有的话）

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⚠️ 免责声明

- 本脚本仅供学习和研究使用
- 使用前请充分了解Boundless项目的风险
- 作者不对使用本脚本造成的任何损失负责
- 请确保遵守当地法律法规

## 👨‍💻 作者

**Coinowodrop**
- 推特: [@Coinowodrop](https://x.com/Coinowodrop)
- 网站: [coinowo.com](https://coinowo.com/)
- 邮箱: contact@coinowo.com

## 🙏 致谢

- 感谢 [Boundless](https://boundless.xyz/) 团队提供优秀的ZK证明技术
- 感谢社区用户的反馈和建议
- 感谢所有贡献者的努力

## 📈 统计

![GitHub stars](https://img.shields.io/github/stars/polibee/autoscript?style=social)
![GitHub forks](https://img.shields.io/github/forks/polibee/autoscript?style=social)
![GitHub issues](https://img.shields.io/github/issues/polibee/autoscript)
![GitHub pull requests](https://img.shields.io/github/issues-pr/polibee/autoscript)

---

**如果这个脚本对您有帮助，请给个⭐️支持一下！**