#!/bin/bash

# Boundless 自动化部署工具一键安装脚本
# 作者: https://x.com/Coinowodrop
# 网站: https://coinowo.com/

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 配置变量
INSTALL_DIR="$HOME/boundless_tools"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/polibee/autoscript/main"

# 如果是本地安装，使用当前目录
if [[ -f "$(dirname "$0")/boundless_auto_deploy.sh" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    LOCAL_INSTALL=true
    log_info "检测到本地文件，使用本地安装模式"
else
    LOCAL_INSTALL=false
    log_info "使用在线安装模式"
fi

# 显示欢迎信息
show_welcome() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "    Boundless 自动化部署工具安装程序"
    echo "================================================"
    echo -e "${NC}"
    echo "作者: Coinowodrop"
    echo "Twitter: https://x.com/Coinowodrop"
    echo "网站: https://coinowo.com/"
    echo ""
    echo "这个工具将帮助您:"
    echo "✅ 自动安装 Boundless ZK Prover 环境"
    echo "✅ 配置所有必要的依赖项"
    echo "✅ 提供完整的服务管理功能"
    echo "✅ 支持监控和故障排除"
    echo ""
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi
    
    source /etc/os-release
    log_info "检测到系统: $PRETTY_NAME"
    
    # 检查网络连接
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "网络连接可能有问题，请检查网络设置"
    fi
    
    # 检查基础工具
    for tool in curl wget git; do
        if ! command -v $tool &> /dev/null; then
            log_warning "$tool 未安装，将在安装过程中自动安装"
        fi
    done
    
    log_success "系统要求检查完成"
}

# 创建安装目录
create_install_dir() {
    log_info "创建安装目录: $INSTALL_DIR"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warning "安装目录已存在，将进行更新"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        mkdir -p "$INSTALL_DIR"
    fi
    
    cd "$INSTALL_DIR"
    log_success "安装目录准备完成"
}

# 下载文件
download_file() {
    local filename="$1"
    local url="$2"
    
    log_info "下载 $filename..."
    
    if [[ "$LOCAL_INSTALL" == "true" ]]; then
        # 本地安装模式
        if [[ -f "$SCRIPT_DIR/$filename" ]]; then
            cp "$SCRIPT_DIR/$filename" "$INSTALL_DIR/"
            log_success "$filename 复制完成"
        else
            log_error "本地文件 $filename 不存在"
            return 1
        fi
    else
        # 在线安装模式
        if curl -fsSL "$url" -o "$filename"; then
            log_success "$filename 下载完成"
        else
            log_error "$filename 下载失败"
            return 1
        fi
    fi
    
    return 0
}

# 下载所有必要文件
download_files() {
    log_info "下载部署工具文件..."
    
    # 文件列表
    declare -A files=(
        ["boundless_auto_deploy.sh"]="$GITHUB_RAW_BASE/boundless_auto_deploy.sh"
        ["config_template.json"]="$GITHUB_RAW_BASE/config_template.json"
        ["README.md"]="$GITHUB_RAW_BASE/README.md"
    )
    
    # 下载每个文件
    for filename in "${!files[@]}"; do
        if ! download_file "$filename" "${files[$filename]}"; then
            log_error "关键文件下载失败，安装中止"
            exit 1
        fi
    done
    
    # 设置执行权限
    chmod +x boundless_auto_deploy.sh
    
    log_success "所有文件下载完成"
}

# 创建快捷命令
create_shortcuts() {
    log_info "创建快捷命令..."
    
    # 创建符号链接到 /usr/local/bin
    local bin_dir="/usr/local/bin"
    local script_path="$INSTALL_DIR/boundless_auto_deploy.sh"
    local shortcut_name="boundless"
    
    if [[ -w "$bin_dir" ]] || sudo -n true 2>/dev/null; then
        if sudo ln -sf "$script_path" "$bin_dir/$shortcut_name" 2>/dev/null; then
            log_success "创建全局命令: $shortcut_name"
            log_info "现在可以在任何地方使用 'boundless' 命令"
        else
            log_warning "无法创建全局命令，请手动添加到 PATH"
        fi
    else
        log_warning "没有权限创建全局命令"
    fi
    
    # 添加到 .bashrc
    local bashrc="$HOME/.bashrc"
    local alias_line="alias boundless='$script_path'"
    
    if ! grep -q "alias boundless=" "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo "# Boundless 自动化部署工具" >> "$bashrc"
        echo "$alias_line" >> "$bashrc"
        log_success "添加别名到 .bashrc"
    fi
}

# 显示安装完成信息
show_completion() {
    echo -e "${GREEN}"
    echo "================================================"
    echo "           安装完成！"
    echo "================================================"
    echo -e "${NC}"
    echo "安装目录: $INSTALL_DIR"
    echo ""
    echo "快速开始:"
    echo "1. 重新加载 shell 配置:"
    echo "   source ~/.bashrc"
    echo ""
    echo "2. 运行完整安装:"
    echo "   boundless install"
    echo "   # 或者"
    echo "   cd $INSTALL_DIR && ./boundless_auto_deploy.sh install"
    echo ""
    echo "3. 查看帮助信息:"
    echo "   boundless help"
    echo ""
    echo "常用命令:"
    echo "  boundless install   - 完整安装 Boundless 环境"
    echo "  boundless start     - 启动服务"
    echo "  boundless status    - 查看服务状态"
    echo "  boundless logs      - 查看日志"
    echo "  boundless monitor   - 实时监控"
    echo ""
    echo "配置文件:"
    echo "  $INSTALL_DIR/config_template.json"
    echo ""
    echo "文档:"
    echo "  $INSTALL_DIR/README.md"
    echo ""
    echo -e "${YELLOW}注意事项:${NC}"
    echo "- 首次运行需要配置私钥和 RPC URL"
    echo "- 确保系统有 NVIDIA GPU 和足够的内存"
    echo "- 建议在 Ubuntu 22.04 LTS 上运行"
    echo ""
    echo -e "${BLUE}获取支持:${NC}"
    echo "- Twitter: https://x.com/Coinowodrop"
    echo "- 网站: https://coinowo.com/"
    echo "- Discord: https://discord.gg/boundless"
    echo ""
}

# 主安装流程
main() {
    show_welcome
    
    # 确认安装
    read -p "是否继续安装? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    check_requirements
    create_install_dir
    download_files
    create_shortcuts
    show_completion
    
    log_success "安装程序执行完成！"
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查网络连接和权限设置"' ERR

# 运行主函数
main "$@"