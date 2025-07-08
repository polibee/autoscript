#!/bin/bash

# Boundless ZK Prover 自动化部署和管理脚本
# 作者: https://x.com/Coinowodrop
# 网站: https://coinowo.com/
# 版本: 2.0
# 描述: 自动化部署和管理 Boundless ZK Prover 节点和Broker

set -e

# 脚本版本
SCRIPT_VERSION="2.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 配置变量
BOUNDLESS_DIR="$HOME/boundless"
BOUNDLESS_REPO="https://github.com/boundless-xyz/boundless"
BOUNDLESS_RELEASE="release-0.12"
LOG_DIR="$HOME/boundless_logs"
CONFIG_FILE="$HOME/.boundless_config"
BACKUP_DIR="$HOME/boundless_backup"

# 网络配置
declare -A NETWORKS
NETWORKS["mainnet"]="Base Mainnet|https://base-mainnet.g.alchemy.com/v2/YOUR_API_KEY|8453|https://basescan.org|ETH"
NETWORKS["testnet"]="Base Sepolia|https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY|84532|https://sepolia.basescan.org|ETH"

# 创建必要目录
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Boundless ZK Prover                      ║${NC}"
    echo -e "${CYAN}║                  自动化部署和管理脚本                        ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  版本: ${SCRIPT_VERSION}                                              ║${NC}"
    echo -e "${CYAN}║  作者: https://x.com/Coinowodrop                            ║${NC}"
    echo -e "${CYAN}║  网站: https://coinowo.com/                                 ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  支持功能:                                                   ║${NC}"
    echo -e "${CYAN}║  • 一键安装证明者和Broker                                   ║${NC}"
    echo -e "${CYAN}║  • 交互式配置管理                                           ║${NC}"
    echo -e "${CYAN}║  • GPU自动检测和配置                                        ║${NC}"
    echo -e "${CYAN}║  • 网络切换(主网/测试网)                                    ║${NC}"
    echo -e "${CYAN}║  • 一键卸载和清理                                           ║${NC}"
    echo -e "${CYAN}║  • 实时监控和日志查看                                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# 获取GPU信息
get_gpu_info() {
    log_info "检测GPU信息..."
    
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}检测到NVIDIA GPU:${NC}"
        nvidia-smi -L | while read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
        
        echo
        echo -e "${GREEN}GPU使用情况:${NC}"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | while IFS=',' read -r index name util mem_used mem_total temp; do
            echo -e "  GPU $index: ${CYAN}$name${NC} | 使用率: ${YELLOW}$util%${NC} | 内存: ${YELLOW}$mem_used/$mem_total MB${NC} | 温度: ${YELLOW}$temp°C${NC}"
        done
        
        # 检测可用GPU数量
        gpu_count=$(nvidia-smi -L | wc -l)
        log_success "检测到 $gpu_count 个GPU"
        
        return 0
    else
        log_warning "未检测到NVIDIA GPU或驱动未安装"
        return 1
    fi
}

# 设置网络配置
set_network_config() {
    echo -e "${CYAN}请选择网络:${NC}"
    echo "1) Base Mainnet (主网)"
    echo "2) Base Sepolia (测试网)"
    echo
    
    while true; do
        read -p "请选择网络 (1-2): " network_choice
        case $network_choice in
            1)
                SELECTED_NETWORK="mainnet"
                break
                ;;
            2)
                SELECTED_NETWORK="testnet"
                break
                ;;
            *)
                log_error "无效选择，请输入 1 或 2"
                ;;
        esac
    done
    
    # 解析网络信息
    IFS='|' read -r network_name rpc_url chain_id explorer currency <<< "${NETWORKS[$SELECTED_NETWORK]}"
    
    log_success "已选择: $network_name (Chain ID: $chain_id)"
    echo -e "${YELLOW}浏览器: $explorer${NC}"
    echo
}

# 设置RPC配置
set_rpc_config() {
    local default_rpc="$1"
    
    echo -e "${CYAN}RPC URL 配置:${NC}"
    echo -e "默认RPC: ${YELLOW}$default_rpc${NC}"
    echo "推荐使用 Alchemy 端点以获得更好的性能和稳定性"
    echo
    
    while true; do
        read -p "请输入RPC URL (回车使用默认): " rpc_input
        
        if [[ -z "$rpc_input" ]]; then
            if [[ "$default_rpc" == *"YOUR_API_KEY"* ]]; then
                log_error "默认RPC包含占位符，请输入有效的RPC URL"
                continue
            fi
            RPC_URL="$default_rpc"
        else
            RPC_URL="$rpc_input"
        fi
        
        # 验证RPC URL格式
        if [[ "$RPC_URL" =~ ^https?:// ]]; then
            log_success "RPC URL 已设置: $RPC_URL"
            break
        else
            log_error "无效的RPC URL格式，请输入以 http:// 或 https:// 开头的URL"
        fi
    done
}

# 设置私钥配置
set_private_key_config() {
    echo -e "${CYAN}钱包私钥配置:${NC}"
    echo -e "${RED}警告: 请确保私钥安全，不要泄露给他人${NC}"
    echo "私钥用于代表您的证明者在市场上进行交易"
    echo "请确保钱包有足够的资金用于质押和gas费用"
    echo
    
    while true; do
        read -s -p "请输入私钥 (不会显示): " private_key_input
        echo
        
        if [[ -z "$private_key_input" ]]; then
            log_error "私钥不能为空"
            continue
        fi
        
        # 验证私钥格式 (64位十六进制字符，可选0x前缀)
        if [[ "$private_key_input" =~ ^(0x)?[a-fA-F0-9]{64}$ ]]; then
            # 确保私钥有0x前缀
            if [[ "$private_key_input" != 0x* ]]; then
                PRIVATE_KEY="0x$private_key_input"
            else
                PRIVATE_KEY="$private_key_input"
            fi
            log_success "私钥格式验证通过"
            break
        else
            log_error "无效的私钥格式，请输入64位十六进制字符"
        fi
    done
}

# 设置段大小配置
set_segment_size_config() {
    echo -e "${CYAN}段大小 (SEGMENT_SIZE) 配置:${NC}"
    echo "段大小影响GPU内存使用和性能:"
    echo "• 较大的段大小需要更多GPU内存但性能更好"
    echo "• 推荐值: 21 (适合大多数GPU)"
    echo "• 范围: 16-24 (根据GPU内存调整)"
    echo
    
    while true; do
        read -p "请输入段大小 (默认21): " segment_size_input
        
        if [[ -z "$segment_size_input" ]]; then
            SEGMENT_SIZE="21"
        else
            SEGMENT_SIZE="$segment_size_input"
        fi
        
        # 验证段大小范围
        if [[ "$SEGMENT_SIZE" =~ ^[0-9]+$ ]] && [[ $SEGMENT_SIZE -ge 16 ]] && [[ $SEGMENT_SIZE -le 24 ]]; then
            log_success "段大小已设置: $SEGMENT_SIZE"
            break
        else
            log_error "无效的段大小，请输入16-24之间的数字"
        fi
    done
}

# 保存配置
save_config() {
    log_info "保存配置到 $CONFIG_FILE..."
    
    cat > "$CONFIG_FILE" << EOF
# Boundless 配置文件
# 生成时间: $(date)
SELECTED_NETWORK="$SELECTED_NETWORK"
PRIVATE_KEY="$PRIVATE_KEY"
RPC_URL="$RPC_URL"
SEGMENT_SIZE="$SEGMENT_SIZE"
CHAIN_ID="$chain_id"
NETWORK_NAME="$network_name"
EXPLORER="$explorer"
CURRENCY="$currency"
EOF
    
    chmod 600 "$CONFIG_FILE"  # 限制文件权限
    log_success "配置已保存"
}

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "已加载配置: $NETWORK_NAME"
        return 0
    else
        return 1
    fi
}

# 交互式配置
interactive_config() {
    log_info "开始交互式配置..."
    
    set_network_config
    
    # 解析网络信息
    IFS='|' read -r network_name rpc_url chain_id explorer currency <<< "${NETWORKS[$SELECTED_NETWORK]}"
    
    set_rpc_config "$rpc_url"
    set_private_key_config
    set_segment_size_config
    
    save_config
    
    log_success "配置完成!"
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi
    
    source /etc/os-release
    log_info "当前系统: $PRETTY_NAME"
    
    if [[ "$ID" == "ubuntu" ]] && [[ "$VERSION_ID" == "22.04" ]]; then
        log_success "推荐系统版本: Ubuntu 22.04 LTS"
    else
        log_warning "当前系统不是推荐的 Ubuntu 22.04 LTS"
        echo "脚本仍会尝试运行，但可能遇到兼容性问题"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 检查GPU
    get_gpu_info
    
    # 检查内存
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $total_mem -lt 8 ]]; then
        log_warning "系统内存少于8GB (当前: ${total_mem}GB)，可能影响性能"
    else
        log_success "系统内存: ${total_mem}GB"
    fi
    
    # 检查磁盘空间
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 20 ]]; then
        log_warning "可用磁盘空间少于20GB (当前: ${available_space}GB)"
    else
        log_success "可用磁盘空间: ${available_space}GB"
    fi
    
    log_success "系统要求检查完成"
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    # 更新包列表
    $SUDO_CMD apt update
    
    # 安装基础工具
    $SUDO_CMD apt install -y \
        curl \
        wget \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https
    
    log_success "系统依赖安装完成"
}

# 安装Docker
install_docker() {
    log_info "安装 Docker..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_info "Docker 已安装，版本: $docker_version"
        return 0
    fi
    
    # 添加Docker官方GPG密钥
    $SUDO_CMD mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 添加Docker仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    $SUDO_CMD apt update
    $SUDO_CMD apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动Docker服务
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
    
    # 添加用户到docker组
    $SUDO_CMD usermod -aG docker $BOUNDLESS_USER
    
    log_success "Docker 安装完成"
    log_warning "请重新登录以使docker组权限生效"
}

# 安装NVIDIA Docker支持
install_nvidia_docker() {
    log_info "安装 NVIDIA Docker 支持..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_warning "未检测到 NVIDIA 驱动，跳过 NVIDIA Docker 安装"
        return 0
    fi
    
    # 检查是否已安装
    if command -v nvidia-ctk &> /dev/null; then
        log_info "NVIDIA Container Toolkit 已安装"
        return 0
    fi
    
    # 获取系统发行版信息
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    
    # 定义多个镜像源
    declare -a NVIDIA_SOURCES=(
        "https://nvidia.github.io/libnvidia-container"
        "https://mirrors.aliyun.com/nvidia-container-toolkit"
        "https://mirrors.tuna.tsinghua.edu.cn/nvidia-container-toolkit"
        "https://mirrors.ustc.edu.cn/nvidia-container-toolkit"
    )
    
    # 定义GPG密钥源
    declare -a GPG_SOURCES=(
        "https://nvidia.github.io/libnvidia-container/gpgkey"
        "https://mirrors.aliyun.com/nvidia-container-toolkit/gpgkey"
        "https://mirrors.tuna.tsinghua.edu.cn/nvidia-container-toolkit/gpgkey"
        "https://mirrors.ustc.edu.cn/nvidia-container-toolkit/gpgkey"
    )
    
    log_info "尝试从多个源安装 NVIDIA Container Toolkit..."
    
    # 尝试安装GPG密钥
    local gpg_success=false
    for gpg_url in "${GPG_SOURCES[@]}"; do
        log_info "尝试从 $gpg_url 获取GPG密钥..."
        if curl -fsSL "$gpg_url" | $SUDO_CMD gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null; then
            log_success "GPG密钥获取成功: $gpg_url"
            gpg_success=true
            break
        else
            log_warning "GPG密钥获取失败: $gpg_url"
        fi
    done
    
    if [[ "$gpg_success" != "true" ]]; then
        log_error "所有GPG密钥源都无法访问，尝试跳过GPG验证..."
        # 创建一个空的GPG密钥文件以避免错误
        $SUDO_CMD touch /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    fi
    
    # 尝试添加仓库源
    local repo_success=false
    for nvidia_url in "${NVIDIA_SOURCES[@]}"; do
        log_info "尝试添加仓库源: $nvidia_url"
        
        # 构建仓库URL
        if [[ "$nvidia_url" == *"nvidia.github.io"* ]]; then
            repo_url="$nvidia_url/stable/deb/nvidia-container-toolkit.list"
        else
            repo_url="$nvidia_url/stable/deb/nvidia-container-toolkit.list"
        fi
        
        # 尝试获取仓库列表
        if curl -s -L "$repo_url" 2>/dev/null | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            $SUDO_CMD tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null 2>&1; then
            log_success "仓库源添加成功: $nvidia_url"
            repo_success=true
            break
        else
            log_warning "仓库源添加失败: $nvidia_url"
        fi
    done
    
    if [[ "$repo_success" != "true" ]]; then
        log_warning "所有仓库源都无法访问，尝试手动创建仓库配置..."
        # 手动创建基本的仓库配置
        echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/ /" | \
            $SUDO_CMD tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    fi
    
    # 更新包列表
    log_info "更新包列表..."
    if ! $SUDO_CMD apt update 2>/dev/null; then
        log_warning "包列表更新失败，继续尝试安装..."
    fi
    
    # 尝试安装nvidia-container-toolkit
    log_info "安装 nvidia-container-toolkit..."
    if $SUDO_CMD apt install -y nvidia-container-toolkit 2>/dev/null; then
        log_success "nvidia-container-toolkit 安装成功"
    else
        log_warning "通过apt安装失败，尝试其他安装方式..."
        
        # 尝试直接下载deb包安装
        log_info "尝试直接下载deb包安装..."
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # 定义deb包下载源
        declare -a DEB_SOURCES=(
            "https://github.com/NVIDIA/nvidia-container-toolkit/releases/latest/download"
            "https://mirrors.aliyun.com/nvidia-container-toolkit/releases/latest"
        )
        
        local deb_success=false
        for deb_url in "${DEB_SOURCES[@]}"; do
            log_info "尝试从 $deb_url 下载deb包..."
            if wget -q "$deb_url/nvidia-container-toolkit_1.17.8-1_amd64.deb" 2>/dev/null || \
               curl -sL "$deb_url/nvidia-container-toolkit_1.17.8-1_amd64.deb" -o nvidia-container-toolkit_1.17.8-1_amd64.deb 2>/dev/null; then
                if $SUDO_CMD dpkg -i nvidia-container-toolkit_1.17.8-1_amd64.deb 2>/dev/null; then
                    log_success "deb包安装成功"
                    deb_success=true
                    break
                fi
            fi
        done
        
        cd - > /dev/null
        rm -rf "$temp_dir"
        
        if [[ "$deb_success" != "true" ]]; then
            log_error "所有安装方式都失败，请手动安装 nvidia-container-toolkit"
            log_info "您可以访问 https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html 获取帮助"
            return 1
        fi
    fi
    
    # 配置Docker运行时
    log_info "配置Docker运行时..."
    if command -v nvidia-ctk &> /dev/null; then
        $SUDO_CMD nvidia-ctk runtime configure --runtime=docker
        $SUDO_CMD systemctl restart docker
        log_success "NVIDIA Docker 支持安装完成"
    else
        log_error "nvidia-ctk 命令未找到，安装可能未成功"
        return 1
    fi
}

# 安装Rust
install_rust() {
    log_info "安装 Rust..."
    
    if command -v cargo &> /dev/null; then
        local rust_version=$(rustc --version | cut -d' ' -f2)
        log_info "Rust 已安装，版本: $rust_version"
        return 0
    fi
    
    # 安装Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # 添加到PATH
    if ! grep -q 'source "$HOME/.cargo/env"' ~/.bashrc; then
        echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
    fi
    
    log_success "Rust 安装完成"
}

# 安装Just
install_just() {
    log_info "安装 Just..."
    
    if command -v just &> /dev/null; then
        local just_version=$(just --version | cut -d' ' -f2)
        log_info "Just 已安装，版本: $just_version"
        return 0
    fi
    
    # 确保cargo可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    cargo install just
    
    log_success "Just 安装完成"
}

# 克隆Boundless仓库
clone_boundless_repo() {
    log_info "克隆 Boundless 仓库..."
    
    if [[ -d "$BOUNDLESS_DIR" ]]; then
        log_info "Boundless 目录已存在，更新代码..."
        cd "$BOUNDLESS_DIR"
        git fetch origin
        git checkout "$BOUNDLESS_RELEASE"
        git pull origin "$BOUNDLESS_RELEASE"
    else
        git clone "$BOUNDLESS_REPO" "$BOUNDLESS_DIR"
        cd "$BOUNDLESS_DIR"
        git checkout "$BOUNDLESS_RELEASE"
    fi
    
    log_success "Boundless 仓库准备完成 (版本: $BOUNDLESS_RELEASE)"
}

# 运行Boundless安装脚本
run_boundless_setup() {
    log_info "运行 Boundless 安装脚本..."
    
    cd "$BOUNDLESS_DIR"
    
    if [[ -f "scripts/setup.sh" ]]; then
        $SUDO_CMD ./scripts/setup.sh
        log_success "Boundless 安装脚本执行完成"
    else
        log_warning "未找到 Boundless 安装脚本，跳过"
    fi
}

# 安装CLI工具
install_cli_tools() {
    log_info "安装 CLI 工具..."
    
    # 确保cargo可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    # 安装 bento_cli
    log_info "安装 bento_cli..."
    if ! command -v bento_cli &> /dev/null; then
        cargo install --locked --git https://github.com/risc0/risc0 bento-client --branch release-2.1 --bin bento_cli
        log_success "bento_cli 安装完成"
    else
        log_info "bento_cli 已安装"
    fi
    
    # 安装 boundless-cli
    log_info "安装 boundless-cli..."
    if ! command -v boundless &> /dev/null; then
        cargo install --locked boundless-cli
        log_success "boundless-cli 安装完成"
    else
        log_info "boundless-cli 已安装"
    fi
    
    log_success "CLI 工具安装完成"
}

# 配置环境文件
configure_environment_files() {
    log_info "配置环境文件..."
    
    cd "$BOUNDLESS_DIR"
    
    # 加载配置
    if ! load_config; then
        log_error "未找到配置文件，请先运行配置"
        return 1
    fi
    
    # 创建 .env.broker 文件
    if [[ -f ".env.broker-template" ]]; then
        cp .env.broker-template .env.broker
        
        # 更新配置
        sed -i "s|PRIVATE_KEY=.*|PRIVATE_KEY=\"$PRIVATE_KEY\"|" .env.broker
        sed -i "s|RPC_URL=.*|RPC_URL=\"$RPC_URL\"|" .env.broker
        sed -i "s|SEGMENT_SIZE=.*|SEGMENT_SIZE=$SEGMENT_SIZE|" .env.broker
        
        log_success "环境配置文件已创建: .env.broker"
    else
        # 手动创建配置文件
        cat > .env.broker << EOF
PRIVATE_KEY="$PRIVATE_KEY"
RPC_URL="$RPC_URL"
SEGMENT_SIZE=$SEGMENT_SIZE
EOF
        log_success "环境配置文件已手动创建: .env.broker"
    fi
    
    # 配置多GPU支持
    configure_multi_gpu
    
    log_success "环境配置完成"
}

# 配置多GPU支持
configure_multi_gpu() {
    log_info "配置多GPU支持..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_warning "未检测到NVIDIA GPU，跳过多GPU配置"
        return 0
    fi
    
    local gpu_count=$(nvidia-smi -L | wc -l)
    
    if [[ $gpu_count -eq 0 ]]; then
        log_warning "未检测到可用GPU"
        return 0
    elif [[ $gpu_count -eq 1 ]]; then
        log_info "检测到1个GPU，使用默认配置"
        return 0
    fi
    
    log_info "检测到 $gpu_count 个GPU，配置多GPU支持..."
    
    # 备份原始compose.yml
    if [[ -f "compose.yml" ]] && [[ ! -f "compose.yml.backup" ]]; then
        cp compose.yml compose.yml.backup
        log_info "已备份原始 compose.yml"
    fi
    
    # 这里可以添加自动修改compose.yml的逻辑
    # 由于compose.yml结构复杂，建议用户手动配置或提供专门的配置工具
    
    log_info "多GPU配置提示:"
    echo -e "  ${YELLOW}检测到 $gpu_count 个GPU，您可以手动编辑 compose.yml 文件来启用多GPU支持${NC}"
    echo -e "  ${YELLOW}参考官方文档中的多GPU配置部分${NC}"
}

# 运行测试证明
run_test_proof() {
    log_info "运行测试证明..."
    
    cd "$BOUNDLESS_DIR"
    
    # 确保环境变量可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    # 启动 bento
    log_info "启动 bento 服务..."
    just bento &
    local bento_pid=$!
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 15
    
    # 检查服务是否正常启动
    if ! docker ps | grep -q bento; then
        log_error "Bento 服务启动失败"
        kill $bento_pid 2>/dev/null || true
        return 1
    fi
    
    # 运行测试
    log_info "执行测试证明 (最多等待5分钟)..."
    if timeout 300 bash -c 'RUST_LOG=info bento_cli -c 32'; then
        log_success "测试证明成功!"
        local test_result=0
    else
        log_error "测试证明失败或超时"
        local test_result=1
    fi
    
    # 停止 bento
    log_info "停止测试服务..."
    kill $bento_pid 2>/dev/null || true
    sleep 5
    just bento down 2>/dev/null || true
    
    return $test_result
}

# 启动服务
start_services() {
    log_info "启动 Boundless 服务..."
    
    cd "$BOUNDLESS_DIR"
    
    # 确保环境变量可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    # 检查配置文件
    if [[ ! -f ".env.broker" ]]; then
        log_error "未找到环境配置文件，请先运行配置"
        return 1
    fi
    
    # 启动 broker (包含bento)
    log_info "启动 Broker 和 Bento 服务..."
    just broker up ./.env.broker
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    if docker ps | grep -q boundless; then
        log_success "服务启动完成"
        echo
        log_info "有用的命令:"
        echo -e "  ${CYAN}查看日志:${NC} $0 logs"
        echo -e "  ${CYAN}查看状态:${NC} $0 status"
        echo -e "  ${CYAN}停止服务:${NC} $0 stop"
    else
        log_error "服务启动失败，请检查日志"
        return 1
    fi
}

# 停止服务
stop_services() {
    log_info "停止 Boundless 服务..."
    
    cd "$BOUNDLESS_DIR"
    
    # 确保环境变量可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    if [[ -f ".env.broker" ]]; then
        just broker down ./.env.broker
    else
        just broker down
    fi
    
    # 等待服务完全停止
    sleep 5
    
    log_success "服务已停止"
}

# 重启服务
restart_services() {
    log_info "重启 Boundless 服务..."
    
    stop_services
    sleep 5
    start_services
}

# 检查订单状态和挖矿成功率
check_mining_status() {
    log_info "检查挖矿状态和订单情况..."
    
    if [[ ! -d "$BOUNDLESS_DIR" ]]; then
        log_error "Boundless 未安装"
        return 1
    fi
    
    cd "$BOUNDLESS_DIR"
    
    # 检查最近的日志以获取订单信息
    local recent_logs=$(docker logs $(docker ps -q --filter "name=broker") 2>&1 | tail -100 2>/dev/null)
    
    if [[ -n "$recent_logs" ]]; then
        echo -e "${CYAN}=== 挖矿状态分析 ===${NC}"
        
        # 统计订单相关信息
        local locked_orders=$(echo "$recent_logs" | grep -c "Successfully processed order" || echo "0")
        local fulfilled_orders=$(echo "$recent_logs" | grep -c "fulfilled" || echo "0")
        local failed_locks=$(echo "$recent_logs" | grep -c "soft failed to lock" || echo "0")
        local order_expired=$(echo "$recent_logs" | grep -c "Order already" || echo "0")
        
        echo -e "✅ 成功锁定订单: ${GREEN}$locked_orders${NC}"
        echo -e "🎯 完成订单: ${GREEN}$fulfilled_orders${NC}"
        echo -e "❌ 锁定失败: ${RED}$failed_locks${NC}"
        echo -e "⏰ 订单过期: ${YELLOW}$order_expired${NC}"
        
        # 计算成功率
        local total_attempts=$((locked_orders + failed_locks))
        if [[ $total_attempts -gt 0 ]]; then
            local success_rate=$((locked_orders * 100 / total_attempts))
            echo -e "📊 锁定成功率: ${CYAN}$success_rate%${NC}"
        fi
        
        # 检查最近的订单活动
        local recent_activity=$(echo "$recent_logs" | grep -E "(LockAndFulfill|fulfilled|locked by)" | tail -5)
        if [[ -n "$recent_activity" ]]; then
            echo -e "\n${CYAN}=== 最近订单活动 ===${NC}"
            echo "$recent_activity" | while read -r line; do
                if echo "$line" | grep -q "fulfilled"; then
                    echo -e "${GREEN}✅ $line${NC}"
                elif echo "$line" | grep -q "locked by another"; then
                    echo -e "${YELLOW}⚠️  $line${NC}"
                else
                    echo -e "${BLUE}ℹ️  $line${NC}"
                fi
            done
        fi
        
        # 检查错误信息
        local errors=$(echo "$recent_logs" | grep -i "error" | tail -3)
        if [[ -n "$errors" ]]; then
            echo -e "\n${CYAN}=== 最近错误 ===${NC}"
            echo -e "${RED}$errors${NC}"
        fi
    else
        echo -e "${YELLOW}无法获取挖矿日志，服务可能未运行${NC}"
    fi
}

# 优化broker配置以提高订单获取率
optimize_broker_config() {
    log_info "优化 Broker 配置以提高订单获取成功率..."
    
    if [[ ! -f "$BOUNDLESS_DIR/Broker.toml" ]]; then
        log_error "未找到 Broker.toml 配置文件"
        return 1
    fi
    
    # 备份原配置
    cp "$BOUNDLESS_DIR/Broker.toml" "$BOUNDLESS_DIR/Broker.toml.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 优化配置参数
    cat > "$BOUNDLESS_DIR/Broker.toml" << 'EOF'
# Boundless Broker 优化配置
# 基于社区经验优化，提高订单获取成功率

[broker]
# 降低最小价格以增加竞争力
min_cycle_price = 0.00005

# 增加订单检查频率
order_polling_interval_ms = 1000

# 优化锁定策略
lock_timeout_seconds = 45
max_concurrent_orders = 3

# 提高响应速度
max_response_time_ms = 2000

# 优化gas配置
max_gas_price_gwei = 50
gas_price_multiplier = 1.2

[performance]
# 性能优化
max_memory_usage_mb = 8192
thread_pool_size = 4

[logging]
level = "info"
file_rotation = true
max_file_size_mb = 100
EOF
    
    log_success "Broker 配置已优化"
    log_warning "配置更改后需要重启服务才能生效"
    
    echo -e "${CYAN}优化内容:${NC}"
    echo "• 降低最小价格以增加竞争力"
    echo "• 增加订单检查频率"
    echo "• 优化锁定超时时间"
    echo "• 提高响应速度"
    echo "• 优化gas配置"
}

# 查看服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    echo -e "${CYAN}=== Docker 容器状态 ===${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAME|boundless|bento|broker)"; then
        echo
    else
        echo -e "${YELLOW}未发现运行中的 Boundless 相关容器${NC}"
    fi
    
    echo -e "${CYAN}=== GPU 使用情况 ===${NC}"
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | while IFS=',' read -r index name util mem_used mem_total temp; do
            echo -e "GPU $index: ${CYAN}$name${NC} | 使用率: ${YELLOW}$util%${NC} | 内存: ${YELLOW}$mem_used/$mem_total MB${NC} | 温度: ${YELLOW}$temp°C${NC}"
        done
    else
        echo -e "${YELLOW}未检测到 NVIDIA GPU${NC}"
    fi
    
    echo
    echo -e "${CYAN}=== 系统资源 ===${NC}"
    echo -e "CPU使用率: ${YELLOW}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%${NC}"
    echo -e "内存使用: ${YELLOW}$(free -h | awk '/^Mem:/ {printf "%.1f/%.1f GB (%.1f%%)", $3/1024, $2/1024, $3*100/$2}')${NC}"
    echo -e "磁盘使用: ${YELLOW}$(df -h "$HOME" | awk 'NR==2 {printf "%s/%s (%s)", $3, $2, $5}')${NC}"
    
    # 添加挖矿状态检查
    echo
    check_mining_status
}

# 查看日志
view_logs() {
    cd "$BOUNDLESS_DIR"
    
    echo -e "${CYAN}选择要查看的日志:${NC}"
    echo "1) Broker 日志"
    echo "2) Bento 日志"
    echo "3) 实时日志 (Ctrl+C 退出)"
    echo "4) 错误日志"
    echo "5) 返回主菜单"
    echo
    
    read -p "请选择 (1-5): " choice
    
    # 确保环境变量可用
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    case $choice in
        1)
            log_info "显示 Broker 日志..."
            just broker logs 2>/dev/null || echo -e "${YELLOW}无法获取日志，服务可能未运行${NC}"
            ;;
        2)
            log_info "显示 Bento 日志..."
            just bento logs 2>/dev/null || echo -e "${YELLOW}无法获取日志，服务可能未运行${NC}"
            ;;
        3)
            log_info "显示实时日志 (按 Ctrl+C 退出)..."
            just broker logs -f 2>/dev/null || echo -e "${YELLOW}无法获取日志，服务可能未运行${NC}"
            ;;
        4)
            log_info "显示错误日志..."
            docker logs $(docker ps -q --filter "name=broker") 2>&1 | grep -i error | tail -20 || echo -e "${YELLOW}未找到错误日志${NC}"
            ;;
        5)
            return 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

# 切换网络
switch_network() {
    log_info "切换网络配置..."
    
    # 显示当前网络
    if load_config; then
        echo -e "${CYAN}当前网络: ${YELLOW}$NETWORK_NAME${NC}"
        echo
    fi
    
    # 重新配置网络
    set_network_config
    
    # 解析网络信息
    IFS='|' read -r network_name rpc_url chain_id explorer currency <<< "${NETWORKS[$SELECTED_NETWORK]}"
    
    set_rpc_config "$rpc_url"
    
    # 保留其他配置
    if load_config; then
        # 只更新网络相关配置
        cat > "$CONFIG_FILE" << EOF
# Boundless 配置文件
# 更新时间: $(date)
SELECTED_NETWORK="$SELECTED_NETWORK"
PRIVATE_KEY="$PRIVATE_KEY"
RPC_URL="$RPC_URL"
SEGMENT_SIZE="$SEGMENT_SIZE"
CHAIN_ID="$chain_id"
NETWORK_NAME="$network_name"
EXPLORER="$explorer"
CURRENCY="$currency"
EOF
        chmod 600 "$CONFIG_FILE"
    fi
    
    # 更新环境文件
    if [[ -d "$BOUNDLESS_DIR" ]]; then
        configure_environment_files
    fi
    
    log_success "网络已切换到: $network_name"
    log_warning "请重启服务以使新配置生效"
}

# 一键卸载
uninstall_boundless() {
    log_warning "这将完全卸载 Boundless 及其所有数据"
    echo -e "${RED}警告: 此操作不可逆，将删除:${NC}"
    echo "• Boundless 安装目录"
    echo "• Docker 容器和镜像"
    echo "• 配置文件和日志"
    echo "• CLI 工具"
    echo
    
    read -p "确定要继续吗? 请输入 'YES' 确认: " confirm
    
    if [[ "$confirm" != "YES" ]]; then
        log_info "取消卸载"
        return 0
    fi
    
    log_info "开始卸载 Boundless..."
    
    # 停止所有服务
    if [[ -d "$BOUNDLESS_DIR" ]]; then
        cd "$BOUNDLESS_DIR"
        log_info "停止服务..."
        just broker down 2>/dev/null || true
        just bento down 2>/dev/null || true
        sleep 5
    fi
    
    # 清理Docker资源
    log_info "清理 Docker 资源..."
    docker stop $(docker ps -aq --filter "name=boundless") 2>/dev/null || true
    docker stop $(docker ps -aq --filter "name=bento") 2>/dev/null || true
    docker stop $(docker ps -aq --filter "name=broker") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=boundless") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=bento") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=broker") 2>/dev/null || true
    
    # 删除Docker镜像
    docker rmi $(docker images --filter "reference=*boundless*" -q) 2>/dev/null || true
    docker rmi $(docker images --filter "reference=*bento*" -q) 2>/dev/null || true
    
    # 清理Docker卷
    docker volume rm $(docker volume ls --filter "name=boundless" -q) 2>/dev/null || true
    docker volume rm $(docker volume ls --filter "name=bento" -q) 2>/dev/null || true
    
    # 删除安装目录
    if [[ -d "$BOUNDLESS_DIR" ]]; then
        log_info "删除安装目录..."
        rm -rf "$BOUNDLESS_DIR"
    fi
    
    # 删除配置文件
    log_info "删除配置文件..."
    rm -f "$CONFIG_FILE"
    rm -rf "$LOG_DIR"
    rm -rf "$BACKUP_DIR"
    
    # 卸载CLI工具
    log_info "卸载 CLI 工具..."
    if command -v cargo &> /dev/null; then
        cargo uninstall boundless-cli 2>/dev/null || true
        cargo uninstall bento-client 2>/dev/null || true
        cargo uninstall just 2>/dev/null || true
    fi
    
    # 清理Docker系统
    log_info "清理 Docker 系统..."
    docker system prune -af 2>/dev/null || true
    
    log_success "Boundless 卸载完成!"
    log_info "如需重新安装，请重新运行安装脚本"
}

# 备份配置
backup_config() {
    log_info "备份配置文件..."
    
    local backup_dir="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份配置文件
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$backup_dir/"
    [[ -f "$BOUNDLESS_DIR/.env.broker" ]] && cp "$BOUNDLESS_DIR/.env.broker" "$backup_dir/"
    [[ -f "$BOUNDLESS_DIR/Broker.toml" ]] && cp "$BOUNDLESS_DIR/Broker.toml" "$backup_dir/"
    [[ -f "$BOUNDLESS_DIR/compose.yml" ]] && cp "$BOUNDLESS_DIR/compose.yml" "$backup_dir/"
    
    # 创建备份信息文件
    cat > "$backup_dir/backup_info.txt" << EOF
备份时间: $(date)
脚本版本: $SCRIPT_VERSION
系统信息: $(uname -a)
Docker版本: $(docker --version 2>/dev/null || echo "未安装")
GPU信息:
$(nvidia-smi -L 2>/dev/null || echo "未检测到GPU")
EOF
    
    log_success "配置已备份到: $backup_dir"
}

# 恢复配置
restore_config() {
    log_info "恢复配置文件..."
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        log_error "未找到备份文件"
        return 1
    fi
    
    echo -e "${CYAN}可用的备份:${NC}"
    local backups=()
    local i=1
    
    for backup in "$BACKUP_DIR"/backup_*; do
        if [[ -d "$backup" ]]; then
            local backup_name=$(basename "$backup")
            local backup_time=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')
            echo "$i) $backup_time"
            backups[i]="$backup"
            ((i++))
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "未找到有效的备份"
        return 1
    fi
    
    echo
    read -p "请选择要恢复的备份 (1-$((i-1))): " choice
    
    if [[ -z "${backups[$choice]}" ]]; then
        log_error "无效选择"
        return 1
    fi
    
    local selected_backup="${backups[$choice]}"
    
    log_info "恢复备份: $(basename "$selected_backup")..."
    
    # 恢复配置文件
    [[ -f "$selected_backup/.boundless_config" ]] && cp "$selected_backup/.boundless_config" "$CONFIG_FILE"
    [[ -f "$selected_backup/.env.broker" ]] && [[ -d "$BOUNDLESS_DIR" ]] && cp "$selected_backup/.env.broker" "$BOUNDLESS_DIR/"
    [[ -f "$selected_backup/Broker.toml" ]] && [[ -d "$BOUNDLESS_DIR" ]] && cp "$selected_backup/Broker.toml" "$BOUNDLESS_DIR/"
    [[ -f "$selected_backup/compose.yml" ]] && [[ -d "$BOUNDLESS_DIR" ]] && cp "$selected_backup/compose.yml" "$BOUNDLESS_DIR/"
    
    log_success "配置恢复完成"
}

# 监控服务
monitor_services() {
    log_info "启动服务监控 (按 Ctrl+C 退出)..."
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    Boundless 服务监控                       ║${NC}"
        echo -e "${CYAN}║                  时间: $(date '+%Y-%m-%d %H:%M:%S')                  ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        check_service_status
        
        echo
        echo -e "${YELLOW}监控中... (按 Ctrl+C 退出)${NC}"
        sleep 30
    done
}

# 更新系统
update_system() {
    log_info "更新 Boundless 系统..."
    
    # 备份配置
    backup_config
    
    # 停止服务
    if [[ -d "$BOUNDLESS_DIR" ]]; then
        stop_services
    fi
    
    # 更新代码
    clone_boundless_repo
    
    # 重新安装CLI工具
    install_cli_tools
    
    # 恢复配置
    if load_config; then
        configure_environment_files
    fi
    
    log_success "系统更新完成"
    log_info "请运行 '$0 start' 启动服务"
}

# 自动监控挖矿状态
start_mining_monitor() {
    log_info "启动挖矿状态监控..."
    
    local monitor_script="$BOUNDLESS_DIR/mining_monitor.sh"
    
    # 创建监控脚本
    cat > "$monitor_script" << 'EOF'
#!/bin/bash

# 挖矿监控脚本
MONITOR_LOG="/tmp/boundless_monitor.log"
ALERT_THRESHOLD=300  # 5分钟无活动则报警

log_monitor() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG"
}

while true; do
    # 检查broker容器状态
    if ! docker ps | grep -q "broker"; then
        log_monitor "WARNING: Broker容器未运行"
        # 尝试重启
        cd /opt/boundless && just broker &
        sleep 30
    fi
    
    # 检查最近活动
    recent_activity=$(docker logs $(docker ps -q --filter "name=broker") 2>&1 | tail -50 | grep -E "(fulfilled|locked|processed)" | tail -1)
    
    if [[ -n "$recent_activity" ]]; then
        log_monitor "INFO: 检测到挖矿活动 - $recent_activity"
    else
        log_monitor "WARNING: 最近5分钟无挖矿活动"
    fi
    
    # 检查GPU状态
    if command -v nvidia-smi &> /dev/null; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)
        if [[ $gpu_temp -gt 85 ]]; then
            log_monitor "WARNING: GPU温度过高: ${gpu_temp}°C"
        fi
    fi
    
    sleep 60
done
EOF
    
    chmod +x "$monitor_script"
    
    # 启动监控（后台运行）
    nohup "$monitor_script" > /dev/null 2>&1 &
    echo $! > "$BOUNDLESS_DIR/monitor.pid"
    
    log_success "挖矿监控已启动，PID: $(cat $BOUNDLESS_DIR/monitor.pid)"
    log_info "监控日志: /tmp/boundless_monitor.log"
}

# 停止监控
stop_mining_monitor() {
    if [[ -f "$BOUNDLESS_DIR/monitor.pid" ]]; then
        local pid=$(cat "$BOUNDLESS_DIR/monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "挖矿监控已停止"
        else
            log_warning "监控进程不存在"
        fi
        rm -f "$BOUNDLESS_DIR/monitor.pid"
    else
        log_warning "未找到监控进程"
    fi
}

# 性能分析
performance_analysis() {
    log_info "执行性能分析..."
    
    echo -e "${CYAN}=== 性能分析报告 ===${NC}"
    
    # GPU性能分析
    if command -v nvidia-smi &> /dev/null; then
        echo -e "\n${CYAN}GPU性能:${NC}"
        nvidia-smi --query-gpu=index,name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits | while IFS=',' read -r index name gpu_util mem_util mem_used mem_total temp power; do
            echo -e "GPU $index ($name):"
            echo -e "  • GPU使用率: ${YELLOW}$gpu_util%${NC}"
            echo -e "  • 显存使用率: ${YELLOW}$mem_util%${NC}"
            echo -e "  • 显存: ${YELLOW}$mem_used/$mem_total MB${NC}"
            echo -e "  • 温度: ${YELLOW}$temp°C${NC}"
            echo -e "  • 功耗: ${YELLOW}$power W${NC}"
            
            # 性能建议
            if [[ $gpu_util -lt 50 ]]; then
                echo -e "  ${YELLOW}⚠️  GPU使用率较低，可能需要优化配置${NC}"
            fi
            if [[ $temp -gt 80 ]]; then
                echo -e "  ${RED}🔥 GPU温度较高，注意散热${NC}"
            fi
        done
    fi
    
    # 网络延迟测试
    echo -e "\n${CYAN}网络性能:${NC}"
    local rpc_url=$(grep "rpc_url" "$BOUNDLESS_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
    if [[ -n "$rpc_url" ]]; then
        local domain=$(echo "$rpc_url" | sed 's|https\?://||' | cut -d'/' -f1)
        local ping_result=$(ping -c 3 "$domain" 2>/dev/null | tail -1 | awk -F'/' '{print $5}' || echo "N/A")
        echo -e "  • RPC延迟: ${YELLOW}${ping_result}ms${NC}"
        
        if [[ "$ping_result" != "N/A" ]] && (( $(echo "$ping_result > 100" | bc -l) )); then
            echo -e "  ${YELLOW}⚠️  网络延迟较高，可能影响订单获取${NC}"
        fi
    fi
    
    # 系统资源分析
    echo -e "\n${CYAN}系统资源:${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_info=$(free | awk '/^Mem:/ {printf "%.1f %.1f %.1f", $3/1024/1024, $2/1024/1024, $3*100/$2}')
    read -r mem_used mem_total mem_percent <<< "$mem_info"
    
    echo -e "  • CPU使用率: ${YELLOW}$cpu_usage%${NC}"
    echo -e "  • 内存使用: ${YELLOW}${mem_used}GB/${mem_total}GB (${mem_percent}%)${NC}"
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo -e "  ${RED}⚠️  CPU使用率过高${NC}"
    fi
    if (( $(echo "$mem_percent > 90" | bc -l) )); then
        echo -e "  ${RED}⚠️  内存使用率过高${NC}"
    fi
    
    # 挖矿效率分析
    echo -e "\n${CYAN}挖矿效率:${NC}"
    if docker ps | grep -q "broker"; then
        local recent_logs=$(docker logs $(docker ps -q --filter "name=broker") 2>&1 | tail -200)
        local orders_per_hour=$(echo "$recent_logs" | grep "$(date '+%Y-%m-%d %H')" | grep -c "fulfilled" || echo "0")
        echo -e "  • 本小时完成订单: ${YELLOW}$orders_per_hour${NC}"
        
        if [[ $orders_per_hour -eq 0 ]]; then
            echo -e "  ${YELLOW}⚠️  本小时暂无完成订单，检查配置和网络${NC}"
        fi
    fi
}

# 故障诊断
diagnose_issues() {
    log_info "执行故障诊断..."
    
    echo -e "${CYAN}=== 故障诊断报告 ===${NC}"
    
    local issues_found=0
    
    # 检查Docker状态
    echo -e "\n${CYAN}1. Docker服务检查:${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "  ✅ Docker服务正常运行"
    else
        echo -e "  ${RED}❌ Docker服务未运行${NC}"
        issues_found=$((issues_found + 1))
    fi
    
    # 检查容器状态
    echo -e "\n${CYAN}2. 容器状态检查:${NC}"
    local broker_running=$(docker ps | grep -c "broker" || echo "0")
    local bento_running=$(docker ps | grep -c "bento" || echo "0")
    
    if [[ $broker_running -gt 0 ]]; then
        echo -e "  ✅ Broker容器正在运行"
    else
        echo -e "  ${RED}❌ Broker容器未运行${NC}"
        issues_found=$((issues_found + 1))
    fi
    
    if [[ $bento_running -gt 0 ]]; then
        echo -e "  ✅ Bento容器正在运行"
    else
        echo -e "  ${RED}❌ Bento容器未运行${NC}"
        issues_found=$((issues_found + 1))
    fi
    
    # 检查GPU
    echo -e "\n${CYAN}3. GPU检查:${NC}"
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            echo -e "  ✅ NVIDIA GPU正常"
        else
            echo -e "  ${RED}❌ NVIDIA GPU驱动异常${NC}"
            issues_found=$((issues_found + 1))
        fi
    else
        echo -e "  ${YELLOW}⚠️  未检测到NVIDIA GPU${NC}"
    fi
    
    # 检查网络连接
    echo -e "\n${CYAN}4. 网络连接检查:${NC}"
    if ping -c 1 google.com &> /dev/null; then
        echo -e "  ✅ 网络连接正常"
    else
        echo -e "  ${RED}❌ 网络连接异常${NC}"
        issues_found=$((issues_found + 1))
    fi
    
    # 检查配置文件
     echo -e "\n${CYAN}5. 配置文件检查:${NC}"
     local config_found=false
     
     # 检查.env.broker文件
     if [[ -f "$BOUNDLESS_DIR/.env.broker" ]]; then
         echo -e "  ✅ Broker环境配置文件存在"
         config_found=true
         
         # 检查关键配置
         if grep -q "PRIVATE_KEY" "$BOUNDLESS_DIR/.env.broker"; then
             echo -e "  ✅ 私钥配置存在"
         else
             echo -e "  ${RED}❌ 私钥配置缺失${NC}"
             issues_found=$((issues_found + 1))
         fi
         
         if grep -q "RPC_URL" "$BOUNDLESS_DIR/.env.broker"; then
             echo -e "  ✅ RPC配置存在"
         else
             echo -e "  ${RED}❌ RPC配置缺失${NC}"
             issues_found=$((issues_found + 1))
         fi
     fi
     
     # 检查.env.bento文件
     if [[ -f "$BOUNDLESS_DIR/.env.bento" ]]; then
         echo -e "  ✅ Bento环境配置文件存在"
         config_found=true
     fi
     
     # 检查Broker.toml文件
     if [[ -f "$BOUNDLESS_DIR/Broker.toml" ]]; then
         echo -e "  ✅ Broker配置文件存在"
     else
         echo -e "  ${YELLOW}⚠️  Broker.toml配置文件不存在${NC}"
     fi
     
     if [[ "$config_found" == "false" ]]; then
         echo -e "  ${RED}❌ 未找到任何环境配置文件${NC}"
         issues_found=$((issues_found + 1))
     fi
    
    # 检查磁盘空间
    echo -e "\n${CYAN}6. 磁盘空间检查:${NC}"
    local disk_usage=$(df "$HOME" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 90 ]]; then
        echo -e "  ✅ 磁盘空间充足 (${disk_usage}%)"
    else
        echo -e "  ${RED}❌ 磁盘空间不足 (${disk_usage}%)${NC}"
        issues_found=$((issues_found + 1))
    fi
    
    # 总结
    echo -e "\n${CYAN}=== 诊断总结 ===${NC}"
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✅ 未发现问题，系统运行正常${NC}"
    else
        echo -e "${RED}❌ 发现 $issues_found 个问题，请根据上述信息进行修复${NC}"
        
        echo -e "\n${CYAN}建议修复步骤:${NC}"
        echo "1. 检查并重启相关服务"
        echo "2. 验证配置文件完整性"
        echo "3. 确保网络连接稳定"
        echo "4. 检查系统资源使用情况"
    fi
}

# 清理系统
clean_system() {
    log_warning "这将清理所有 Boundless 数据和容器，但保留配置"
    read -p "确定要继续吗? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -d "$BOUNDLESS_DIR" ]]; then
            cd "$BOUNDLESS_DIR"
            
            # 确保环境变量可用
            source "$HOME/.cargo/env" 2>/dev/null || true
            
            just broker clean 2>/dev/null || true
        fi
        
        docker system prune -f
        
        # 清理监控日志
        if [[ -f "/tmp/boundless_monitor.log" ]]; then
            log_info "清理监控日志..."
            > /tmp/boundless_monitor.log
        fi
        
        log_success "系统清理完成"
    fi
}

# 重置配置
reset_config() {
    log_warning "这将删除所有配置文件"
    read -p "确定要继续吗? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$CONFIG_FILE"
        [[ -f "$BOUNDLESS_DIR/.env.broker" ]] && rm -f "$BOUNDLESS_DIR/.env.broker"
        log_success "配置已重置"
        log_info "请重新运行配置: $0 config"
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}Boundless ZK Prover 自动化部署和管理脚本 v$SCRIPT_VERSION${NC}"
    echo -e "作者: ${YELLOW}https://x.com/Coinowodrop${NC}"
    echo -e "网站: ${YELLOW}https://coinowo.com/${NC}"
    echo
    echo -e "${GREEN}安装选项:${NC}"
    echo -e "  ${CYAN}install-prover${NC}     - 仅安装证明者组件"
    echo -e "  ${CYAN}install-broker${NC}     - 仅安装Broker组件 (需要先安装证明者)"
    echo -e "  ${CYAN}install${NC}            - 完整安装 (证明者 + Broker)"
    echo
    echo -e "${GREEN}服务管理:${NC}"
    echo -e "  ${CYAN}start${NC}              - 启动服务"
    echo -e "  ${CYAN}stop${NC}               - 停止服务"
    echo -e "  ${CYAN}restart${NC}            - 重启服务"
    echo -e "  ${CYAN}status${NC}             - 查看服务状态"
    echo -e "  ${CYAN}logs${NC}               - 查看日志"
    echo -e "  ${CYAN}monitor${NC}            - 实时监控服务"
    echo
    echo -e "${GREEN}配置管理:${NC}"
    echo -e "  ${CYAN}config${NC}             - 交互式配置"
    echo -e "  ${CYAN}switch-network${NC}     - 切换网络 (主网/测试网)"
    echo -e "  ${CYAN}optimize-broker${NC}    - 优化Broker配置"
    echo -e "  ${CYAN}reset-config${NC}       - 重置配置"
    echo -e "  ${CYAN}backup${NC}             - 备份配置"
    echo -e "  ${CYAN}restore${NC}            - 恢复配置"
    echo
    echo -e "${GREEN}系统管理:${NC}"
    echo -e "  ${CYAN}test${NC}               - 运行测试证明"
    echo -e "  ${CYAN}update${NC}             - 更新系统"
    echo -e "  ${CYAN}clean${NC}              - 清理系统数据"
    echo -e "  ${CYAN}uninstall${NC}          - 完全卸载"
    echo -e "  ${CYAN}gpu-info${NC}           - 显示GPU信息"
    echo
    echo -e "${GREEN}监控和诊断:${NC}"
    echo -e "  ${CYAN}start-monitor${NC}      - 启动自动监控"
    echo -e "  ${CYAN}stop-monitor${NC}       - 停止自动监控"
    echo -e "  ${CYAN}performance${NC}        - 性能分析"
    echo -e "  ${CYAN}diagnose${NC}           - 故障诊断"
    echo
    echo -e "${GREEN}其他:${NC}"
    echo -e "  ${CYAN}help${NC}               - 显示此帮助信息"
    echo
    echo -e "${YELLOW}示例:${NC}"
    echo -e "  ${CYAN}$0 install${NC}         # 完整安装"
    echo -e "  ${CYAN}$0 config${NC}          # 配置网络和私钥"
    echo -e "  ${CYAN}$0 start${NC}           # 启动服务"
    echo -e "  ${CYAN}$0 logs${NC}            # 查看日志"
    echo
}

# 安装证明者
install_prover() {
    show_welcome
    
    log_info "开始安装 Boundless 证明者..."
    
    check_system_requirements
    install_system_dependencies
    install_docker
    install_nvidia_docker
    install_rust
    install_just
    clone_boundless_repo
    run_boundless_setup
    install_cli_tools
    
    log_success "Boundless 证明者安装完成!"
    echo
    log_info "下一步:"
    echo -e "  ${CYAN}1. 配置网络和私钥:${NC} $0 config"
    echo -e "  ${CYAN}2. 运行测试:${NC} $0 test"
    echo -e "  ${CYAN}3. 启动服务:${NC} $0 start"
}

# 安装Broker
install_broker() {
    log_info "开始安装 Boundless Broker..."
    
    # 检查是否已安装基础组件
    if [[ ! -d "$BOUNDLESS_DIR" ]]; then
        log_error "未找到Boundless安装目录，请先安装证明者"
        echo -e "运行: ${CYAN}$0 install-prover${NC}"
        return 1
    fi
    
    # 检查配置
    if ! load_config; then
        log_warning "未找到配置文件，开始配置..."
        interactive_config
    fi
    
    # 配置环境文件
    configure_environment_files
    
    log_success "Boundless Broker安装完成!"
    echo
    log_info "下一步:"
    echo -e "  ${CYAN}1. 启动服务:${NC} $0 start"
    echo -e "  ${CYAN}2. 查看状态:${NC} $0 status"
    echo -e "  ${CYAN}3. 查看日志:${NC} $0 logs"
}

# 完整安装流程
full_install() {
    show_welcome
    
    log_info "开始完整安装流程..."
    
    # 安装证明者
    install_prover
    
    echo
    read -p "是否继续安装Broker? (Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo
        log_info "开始配置和安装Broker..."
        
        # 交互式配置
        interactive_config
        
        # 安装Broker
        install_broker
        
        echo
        log_success "Boundless 完整安装完成!"
        echo
        log_info "建议下一步:"
        echo -e "  ${CYAN}1. 运行测试:${NC} $0 test"
        echo -e "  ${CYAN}2. 启动服务:${NC} $0 start"
        echo -e "  ${CYAN}3. 监控服务:${NC} $0 monitor"
    else
        log_info "仅安装了证明者组件"
        echo -e "如需安装Broker，请运行: ${CYAN}$0 install-broker${NC}"
    fi
}

# 检查用户权限并设置适当的命令前缀
setup_user_environment() {
    if [[ $EUID -eq 0 ]]; then
        # root用户
        log_warning "检测到root用户，将以root权限运行"
        SUDO_CMD=""
        USER_HOME="/root"
        # 为了安全，创建一个普通用户来运行Docker容器
        if ! id "boundless" &>/dev/null; then
            log_info "创建boundless用户用于运行服务..."
            useradd -m -s /bin/bash boundless
            usermod -aG docker boundless 2>/dev/null || true
        fi
        BOUNDLESS_USER="boundless"
    else
        # 普通用户
        log_info "检测到普通用户: $(whoami)"
        SUDO_CMD="sudo"
        USER_HOME="$HOME"
        BOUNDLESS_USER="$(whoami)"
        
        # 检查sudo权限
        if ! $SUDO_CMD -n true 2>/dev/null; then
            log_warning "某些操作需要sudo权限，请确保当前用户有sudo权限"
        fi
    fi
    
    # 更新目录路径
    if [[ $EUID -eq 0 ]]; then
        BOUNDLESS_DIR="/opt/boundless"
        LOG_DIR="/var/log/boundless"
        CONFIG_DIR="/etc/boundless"
    else
        BOUNDLESS_DIR="$USER_HOME/boundless"
        LOG_DIR="$USER_HOME/.local/share/boundless/logs"
        CONFIG_DIR="$USER_HOME/.config/boundless"
    fi
}

# 主函数
main() {
    # 设置用户环境
    setup_user_environment
    
    case "${1:-help}" in
        install)
            full_install
            ;;
        install-prover)
            install_prover
            ;;
        install-broker)
            install_broker
            ;;
        config)
            interactive_config
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            check_service_status
            ;;
        logs)
            view_logs
            ;;
        test)
            run_test_proof
            ;;
        update)
            update_system
            ;;
        clean)
            clean_system
            ;;
        backup)
            backup_config
            ;;
        restore)
            restore_config
            ;;
        monitor)
            monitor_services
            ;;
        switch-network)
            switch_network
            ;;
        reset-config)
            reset_config
            ;;
        uninstall)
            uninstall_boundless
            ;;
        gpu-info)
            get_gpu_info
            ;;
        start-monitor)
            start_mining_monitor
            ;;
        stop-monitor)
            stop_mining_monitor
            ;;
        performance)
            performance_analysis
            ;;
        diagnose)
            diagnose_issues
            ;;
        optimize-broker)
            optimize_broker_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"