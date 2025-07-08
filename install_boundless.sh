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

# 文件下载URLs
MAIN_SCRIPT_URL="https://raw.githubusercontent.com/polibee/autoscript/main/boundless_auto_deploy.sh"
README_URL="https://raw.githubusercontent.com/polibee/autoscript/main/README.md"

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
        log_error "请不要以root用户运行此脚本"
        log_info "请使用普通用户账户运行，脚本会在需要时提示输入sudo密码"
        exit 1
    fi
    
    # 检查sudo权限
    if ! sudo -n true 2>/dev/null; then
        log_info "此脚本需要sudo权限来安装系统依赖"
        log_info "请确保您的用户账户具有sudo权限"
        echo
        read -p "按回车键继续..."
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

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    log_info "下载 $description..."
    
    if command -v curl &> /dev/null; then
        if curl -fsSL "$url" -o "$output"; then
            log_success "$description 下载完成"
        else
            log_error "$description 下载失败"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "$url" -O "$output"; then
            log_success "$description 下载完成"
        else
            log_error "$description 下载失败"
            return 1
        fi
    else
        log_error "未找到 curl 或 wget，无法下载文件"
        log_info "请安装 curl 或 wget: sudo apt install curl"
        return 1
    fi
}

# 安装Boundless主函数
install_boundless() {
    log_info "开始安装 Boundless ZK Prover..."
    
    # 创建安装目录
    log_info "创建安装目录: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # 下载主脚本
    if ! download_file "$MAIN_SCRIPT_URL" "$SCRIPT_PATH" "主安装脚本"; then
        log_error "主脚本下载失败，请检查网络连接或URL"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x "$SCRIPT_PATH"
    log_success "脚本权限设置完成"
    
    # 下载README文件
    download_file "$README_URL" "$INSTALL_DIR/README.md" "说明文档" || log_warning "说明文档下载失败，但不影响安装"
    
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

# 创建桌面快捷方式
create_desktop_shortcut() {
    local desktop_dir="$HOME/Desktop"
    local shortcut_file="$desktop_dir/Boundless.desktop"
    
    if [[ -d "$desktop_dir" ]]; then
        cat > "$shortcut_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Boundless ZK Prover
Comment=Boundless ZK Prover 管理工具
Exec=gnome-terminal -- bash -c "$SCRIPT_PATH; exec bash"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF
        
        chmod +x "$shortcut_file"
        log_success "桌面快捷方式已创建"
    else
        log_info "未找到桌面目录，跳过快捷方式创建"
    fi
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

# 交互式菜单
show_interactive_menu() {
    while true; do
        echo
        echo -e "${CYAN}请选择操作:${NC}"
        echo "1) 立即开始完整安装 (推荐)"
        echo "2) 仅安装证明者组件"
        echo "3) 添加到系统PATH"
        echo "4) 创建桌面快捷方式"
        echo "5) 查看安装说明"
        echo "6) 退出"
        echo
        
        read -p "请选择 (1-6): " choice
        
        case $choice in
            1)
                log_info "开始完整安装..."
                "$SCRIPT_PATH" install
                break
                ;;
            2)
                log_info "开始安装证明者..."
                "$SCRIPT_PATH" install-prover
                break
                ;;
            3)
                add_to_path
                ;;
            4)
                create_desktop_shortcut
                ;;
            5)
                if [[ -f "$INSTALL_DIR/README.md" ]]; then
                    less "$INSTALL_DIR/README.md" || cat "$INSTALL_DIR/README.md"
                else
                    log_warning "说明文档未找到"
                    echo -e "请访问: ${YELLOW}$WEBSITE${NC} 查看详细说明"
                fi
                ;;
            6)
                log_info "退出安装程序"
                break
                ;;
            *)
                log_error "无效选择，请输入 1-6"
                ;;
        esac
    done
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
    
    # 询问是否创建桌面快捷方式
    read -p "是否创建桌面快捷方式? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        create_desktop_shortcut
    fi
    
    show_completion_info
    
    # 询问是否立即开始安装
    read -p "是否现在开始安装 Boundless? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        show_interactive_menu
    else
        log_info "您可以稍后运行以下命令开始安装:"
        echo -e "  ${CYAN}$SCRIPT_PATH install${NC}"
    fi
}

# 运行主函数
main "$@"