#!/bin/bash

# Boundless ZK Prover 一键安装脚本
# 作者: https://x.com/Coinowodrop
# 网站: https://coinowo.com/
# 版本: 2.0
# 描述: 用于GitHub分享的一键安装脚本

set -e

# 脚本信息
SCRIPT_VERSION="2.0"
SCRIPT_NAME="Boundless ZK Prover 一键安装脚本"
AUTHOR="Coinowodrop"
WEBSITE="https://coinowo.com/"
TWITTER="https://x.com/Coinowodrop"

# 本地文件路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/boundless_auto_deploy.sh"
SOURCE_README="$SCRIPT_DIR/README.md"

# 安装目录
INSTALL_DIR="$HOME/boundless-scripts"
SCRIPT_PATH="$INSTALL_DIR/boundless_auto_deploy.sh"

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

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Boundless ZK Prover                      ║${NC}"
    echo -e "${CYAN}║                     一键安装脚本                            ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  版本: ${SCRIPT_VERSION}                                              ║${NC}"
    echo -e "${CYAN}║  作者: ${AUTHOR}                                        ║${NC}"
    echo -e "${CYAN}║  网站: ${WEBSITE}                                 ║${NC}"
    echo -e "${CYAN}║  推特: ${TWITTER}                            ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  这个脚本将帮助您快速安装和配置 Boundless ZK Prover         ║${NC}"
    echo -e "${CYAN}║  支持交互式配置、GPU自动检测、网络切换等功能                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# 检查管理员权限
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到root用户，将以管理员权限运行"
        log_info "建议使用普通用户账户运行以提高安全性"
        SUDO_CMD=""
    else
        log_info "检测到普通用户: $(whoami)"
        SUDO_CMD="sudo"
        
        # 检查sudo权限
        if ! sudo -n true 2>/dev/null; then
            log_info "此脚本需要sudo权限来安装系统依赖"
            log_info "请确保您的用户账户具有sudo权限"
            echo
            read -p "按回车键继续..."
        fi
    fi
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
    
    # 检查网络连接
    if ! ping -c 1 google.com &> /dev/null && ! ping -c 1 github.com &> /dev/null; then
        log_error "网络连接失败，请检查网络设置"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 安装Boundless主函数
install_boundless() {
    log_info "开始安装 Boundless ZK Prover..."
    
    # 创建安装目录
    log_info "创建安装目录: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # 检查本地主脚本是否存在
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        log_error "本地主脚本不存在: $SOURCE_SCRIPT"
        log_error "请确保在正确的目录中运行此脚本"
        exit 1
    fi
    
    # 复制主脚本
    log_info "复制主安装脚本..."
    cp "$SOURCE_SCRIPT" "$SCRIPT_PATH"
    
    # 设置执行权限
    chmod +x "$SCRIPT_PATH"
    log_success "脚本权限设置完成"
    
    # 复制README文件
    if [[ -f "$SOURCE_README" ]]; then
        cp "$SOURCE_README" "$INSTALL_DIR/README.md"
        log_success "说明文档复制完成"
    else
        log_warning "说明文档不存在，但不影响安装"
    fi
    
    log_success "Boundless 脚本安装完成!"
    echo
    log_info "安装位置: $INSTALL_DIR"
    log_info "主脚本: $SCRIPT_PATH"
    echo
}

# 添加到PATH
add_to_path() {
    local shell_rc="$HOME/.bashrc"
    
    # 检测shell类型
    if [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == */fish ]]; then
        shell_rc="$HOME/.config/fish/config.fish"
    fi
    
    # 创建符号链接
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    if [[ -L "$bin_dir/boundless" ]]; then
        rm "$bin_dir/boundless"
    fi
    
    ln -s "$SCRIPT_PATH" "$bin_dir/boundless"
    
    # 添加到PATH
    if [[ "$shell_rc" == *"fish"* ]]; then
        if ! grep -q "$bin_dir" "$shell_rc" 2>/dev/null; then
            echo "set -gx PATH $bin_dir \$PATH" >> "$shell_rc"
        fi
    else
        if ! grep -q "$bin_dir" "$shell_rc" 2>/dev/null; then
            echo "export PATH=\"$bin_dir:\$PATH\"" >> "$shell_rc"
        fi
    fi
    
    log_success "已添加到PATH，重新登录后可直接使用 'boundless' 命令"
}

# 显示安装完成信息
show_completion_info() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     安装完成!                               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}下一步操作:${NC}"
    echo -e "  ${YELLOW}1. 完整安装:${NC} $SCRIPT_PATH install"
    echo -e "  ${YELLOW}2. 仅安装证明者:${NC} $SCRIPT_PATH install-prover"
    echo -e "  ${YELLOW}3. 查看帮助:${NC} $SCRIPT_PATH help"
    echo
    echo -e "${CYAN}如果已添加到PATH，也可以使用:${NC}"
    echo -e "  ${YELLOW}boundless install${NC}"
    echo -e "  ${YELLOW}boundless help${NC}"
    echo
    echo -e "${CYAN}更多信息:${NC}"
    echo -e "  ${YELLOW}作者推特:${NC} $TWITTER"
    echo -e "  ${YELLOW}教程网站:${NC} $WEBSITE"
    echo -e "  ${YELLOW}安装目录:${NC} $INSTALL_DIR"
    echo
}

# 主函数
main() {
    show_welcome
    
    check_permissions
    check_system_requirements
    
    install_boundless
    
    # 询问是否添加到PATH
    echo
    read -p "是否将脚本添加到系统PATH? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        add_to_path
    fi
    
    show_completion_info
    
    # 询问是否立即开始安装
    read -p "是否现在开始安装 Boundless? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$SCRIPT_PATH" install
    else
        log_info "您可以稍后运行以下命令开始安装:"
        echo -e "  ${CYAN}$SCRIPT_PATH install${NC}"
    fi
}

# 运行主函数
main "$@"