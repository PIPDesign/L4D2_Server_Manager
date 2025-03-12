#!/bin/bash

####################################### 参数设置 ##########################################
# 服务器名称列表
NAMES=("L4d2-test" "L4d2-1" "L4d2-2" "L4d2-3" "L4d2-4" "L4d2-5" "L4d2-6" "L4d2-11" "L4d2-12" "L4d2-13" "L4d2-14" "L4d2-15")

# 路径设置
STEAM_DIR="/home/l4d2/Steam"
SERVER_DIR="/home/l4d2/L4D2-Servers"

# 启动参数
PARAMS=(
  "-game left4dead2 +ip 0.0.0.0 +hostport 24099 +map c2m1_highway +sm_basepath addons/sourcemod +sv_setmax 31 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24001 +map c2m1_highway +sm_basepath addons/sourcemod1 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24002 +map c3m1_plankcountry +sm_basepath addons/sourcemod2 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24003 +map c5m1_waterfront +sm_basepath addons/sourcemod3 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24004 +map c6m1_riverbank +sm_basepath addons/sourcemod4 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24005 +map c7m1_docks +sm_basepath addons/sourcemod5 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24006 +map c8m1_apartment +sm_basepath addons/sourcemod6 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24011 +map c8m1_apartment +sm_basepath addons/sourcemod11 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24012 +map c8m1_apartment +sm_basepath addons/sourcemod12 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24013 +map c8m1_apartment +sm_basepath addons/sourcemod13 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24014 +map c8m1_apartment +sm_basepath addons/sourcemod14 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
  "-game left4dead2 +ip 0.0.0.0 +hostport 24015 +map c8m1_apartment +sm_basepath addons/sourcemod15 +sv_setmax 31 -pingboost 3 -tickrate 100 +exec server.cfg -noipx -insecure"
)

# 关闭方式
WAY=1  # 1 = screen指令关闭；2 = screen获取pid后kill；3 = ps获取pid后kill

####################################### 函数部分 ##########################################

# 创建用户和设置目录
function setup_user_and_dirs() {
    if ! id "l4d2" &>/dev/null; then
        echo -e "\e[34m创建用户 l4d2...\e[0m"
        sudo useradd -m -s /bin/bash l4d2
        sudo passwd l4d2
    fi
    sudo mkdir -p "$STEAM_DIR" "$SERVER_DIR"
    sudo chown -R l4d2:l4d2 "$STEAM_DIR" "$SERVER_DIR"
}

# 安装运行依赖
function install_dependencies() {
    echo -e "\e[92m安装依赖...\e[0m"
    source "/etc/os-release"
    case "${ID}" in
        ubuntu)
            sudo dpkg --add-architecture i386
            sudo apt update
            case "${VERSION_ID}" in
                16.04|18.04|20.04)
                    sudo apt -y install lib32gcc1 lib32stdc++6 lib32z1-dev curl screen zip unzip
                ;;
                22.04)
                    sudo apt -y install lib32gcc-s1 lib32stdc++6 lib32z1-dev curl screen zip unzip
                ;;
                *)
                    echo -e "\e[31m不支持的 Ubuntu 版本: ${VERSION_ID}\e[0m"
                    exit 1
                ;;
            esac
        ;;
        debian)
            sudo dpkg --add-architecture i386
            sudo apt update
            case "${VERSION_ID}" in
                9|10)
                    sudo apt -y install lib32gcc1 lib32stdc++6 lib32z1-dev curl screen zip unzip
                ;;
                11|12)
                    sudo apt -y install lib32gcc-s1 lib32stdc++6 lib32z1-dev curl screen zip unzip
                ;;
                *)
                    echo -e "\e[31m不支持的 Debian 版本: ${VERSION_ID}\e[0m"
                    exit 1
                ;;
            esac
        ;;
        centos)
            case "${VERSION_ID}" in
                7|8)
                    sudo yum update
                    sudo yum install -y glibc.i686 libstdc++.i686 curl screen zip unzip
                ;;
                *)
                    echo -e "\e[31m不支持的 CentOS 版本: ${VERSION_ID}\e[0m"
                    exit 1
                ;;
            esac
        ;;
        *)
            echo -e "\e[31m不支持的操作系统: ${ID}\e[0m"
            exit 1
        ;;
    esac

    if [ "${?}" -ne 0 ]; then
        echo -e "\e[31m依赖安装失败，请检查网络或权限\e[0m"
        exit 1
    else
        echo -e "\e[92m依赖安装成功\e[0m"
    fi
}

# 安装服务器
function install_server() {
    local STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    local TMPDIR=$(mktemp -d)
    if [ "${?}" -ne 0 ]; then
        echo -e "\e[31m无法创建临时目录\e[0m"
        exit 1
    fi
    trap 'rm -rf "${TMPDIR}"' EXIT

    if [ -f "${STEAM_DIR}/steamcmd.sh" ]; then
        echo -e "\e[34mSteamCMD 已安装，跳过下载\e[0m"
    else
        echo -e "\e[34m下载 SteamCMD...\e[0m"
        if ! curl -fSLo "${TMPDIR}/steamcmd.tar.gz" "${STEAMCMD_URL}"; then
            echo -e "\e[31mSteamCMD 下载失败，请检查网络\e[0m"
            exit 1
        fi
        sudo tar -zxf "${TMPDIR}/steamcmd.tar.gz" -C "${STEAM_DIR}"
        sudo chown -R l4d2:l4d2 "${STEAM_DIR}"
        echo -e "\e[92mSteamCMD 安装成功\e[0m"
    fi

    if [ -f "${SERVER_DIR}/srcds_run" ]; then
        echo -e "\e[34mL4D2 服务器已安装，跳过安装\e[0m"
    else
        echo -e "\e[34m安装 L4D2 服务器...\e[0m"
        sudo -u l4d2 "${STEAM_DIR}/steamcmd.sh" +force_install_dir "${SERVER_DIR}" +login anonymous +@sSteamCmdForcePlatformType windows +app_update 222860 validate +quit
        if [ "${?}" -ne 0 ]; then
            echo -e "\e[31mL4D2 服务器安装失败，请检查网络或磁盘空间\e[0m"
            exit 1
        fi
        echo -e "\e[92mL4D2 服务器安装成功\e[0m"
    fi
}

# 启动服务器的通用函数
function StartServer() {
    local name=$1
    local params=$2

    if screen -ls | grep -qE "[0-9]+\.${name}[[:space:]]"; then
        echo -e "\e[34m已存在名为 ${name} 的 screen 会话\e[0m"
        return 0
    else
        if ! cd "$SERVER_DIR"; then
            echo -e "\e[31m无法切换到目录 $SERVER_DIR\e[0m"
            return 1
        fi
        echo -e "\e[34m开启 ${name} 服务器中...\e[0m"
        sudo -u l4d2 screen -dmS "${name}" ./srcds_run ${params}
        sleep 1
        if screen -ls | grep -qE "[0-9]+\.${name}[[:space:]]"; then
            echo -e "\e[92m${name} 启动完成\e[0m"
        else
            echo -e "\e[31m${name} 启动失败，请检查路径或参数\e[0m"
        fi
        return 0
    fi
}

# 检查所有服务器的状态
function ScreenCheckAll() {
    echo -e "\e[34m#### 服务器状态检查 ####\e[0m"
    for i in "${!NAMES[@]}"; do
        local name=${NAMES[$i]}
        local params=${PARAMS[$i]}
        if screen -ls | grep -qE "[0-9]+\.${name}[[:space:]]"; then
            echo -e "\e[92m服务器: ${name} 正在运行\e[0m"
        else
            echo -e "\e[31m服务器: ${name} 已关闭\e[0m"
        fi
        echo "screen 会话名称: ${name}"
        echo "启动参数: ${params}"
        echo "-----------------------------"
    done
}

# 关闭服务器的通用函数
function CloseServer() {
    local name=$1

    if screen -ls | grep -qE "[0-9]+\.${name}[[:space:]]"; then
        echo -e "\e[34m关闭 ${name} 服务器中...\e[0m"
        case $WAY in
            1) sudo -u l4d2 screen -X -S "${name}" quit ;;
            2) screen -ls | grep -E "[0-9]+\.${name}[[:space:]]" | awk -F . '{print $1}' | awk '{print $1}' | xargs sudo kill ;;
            3) ps aux | grep -v grep | grep SCREEN | grep srcds_run | grep "${name}" | awk '{print $2}' | xargs sudo kill ;;
            *) echo -e "\e[31m未指定关闭方式\e[0m" ;;
        esac
        sleep 1
        if ! screen -ls | grep -qE "[0-9]+\.${name}[[:space:]]"; then
            echo -e "\e[92m${name} 已关闭\e[0m"
        else
            echo -e "\e[31m${name} 关闭失败\e[0m"
        fi
        ScreenCheckAll
    else
        echo -e "\e[34m未找到名为 ${name} 的 screen 会话\e[0m"
    fi
}

# 更新游戏
function Update() {
    if ! cd "$STEAM_DIR"; then
        echo -e "\e[31m无法切换到目录 $STEAM_DIR\e[0m"
        exit 1
    fi
    echo -e "\e[34m更新 L4D2 服务器...\e[0m"
    sudo -u l4d2 ./steamcmd.sh +force_install_dir "$SERVER_DIR" +login anonymous +app_update 222860 validate +quit
    if [ "${?}" -ne 0 ]; then
        echo -e "\e[31m更新失败，请检查网络或路径\e[0m"
    else
        echo -e "\e[92m更新完成\e[0m"
    fi
}

# 检查路径
function PathCheck() {
    [ -f "$SERVER_DIR/srcds_run" ] && echo -e "\e[92msrcds_run 路径正常\e[0m" || echo -e "\e[31msrcds_run 路径异常\e[0m"
    [ -f "$STEAM_DIR/steamcmd.sh" ] && echo -e "\e[92msteamCMD 路径正常\e[0m" || echo -e "\e[31msteamCMD 路径异常\e[0m"
}

# 根据端口获取服务器索引
function GetServerIndexByPort() {
    local port=$1
    for i in "${!PARAMS[@]}"; do
        if [[ "${PARAMS[$i]}" == *"+hostport $port"* ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
}

####################################### 主交互菜单 ##########################################

function MainBody() {
    echo -e "\n\n\n###########[ \033[32mL4d2-批量启动特感速递服.sh\033[0m ]###########"
    echo "00——安装运行依赖"
    echo "01——安装服务器"
    echo "02——开启测试服务器"
    echo "03——关闭测试服务器"
    echo "04——重启测试服务器"
    echo "05——查看所有服务器状态"
    echo "06——更新游戏并重启"
    echo "07——路径检查"
    echo "08——开启1-6、11-15服（依次启动）"
    echo "09——关闭1-6、11-15服（依次关闭）"
    echo "10——开启指定端口服务器"
    echo "11——关闭指定端口服务器"
    echo "#################################################"
    read -n 2 -p "请输入对应数字选择功能: " answer
    echo
    case ${answer} in
        00) install_dependencies ;;
        01) install_server ;;
        02) StartServer "${NAMES[0]}" "${PARAMS[0]}" ;;
        03) CloseServer "${NAMES[0]}" ;;
        04)
            echo -e "\e[34m重启测试服务器\e[0m"
            CloseServer "${NAMES[0]}"
            StartServer "${NAMES[0]}" "${PARAMS[0]}"
            ;;
        05) ScreenCheckAll ;;
        06)
            echo -e "\e[34m执行更新并重启步骤\e[0m"
            CloseServer "${NAMES[0]}"
            Update
            StartServer "${NAMES[0]}" "${PARAMS[0]}"
            ;;
        07) PathCheck ;;
        08)
            for i in {1..6} {7..11}; do
                StartServer "${NAMES[$i]}" "${PARAMS[$i]}"
            done
            ;;
        09)
            for i in {1..6} {7..11}; do
                CloseServer "${NAMES[$i]}"
            done
            ;;
        10)
            read -p "请输入端口号: " port
            server_index=$(GetServerIndexByPort "$port")
            if [ "$server_index" -ge 0 ]; then
                echo -e "\e[34m找到端口 $port 对应的服务器，正在启动...\e[0m"
                StartServer "${NAMES[$server_index]}" "${PARAMS[$server_index]}"
            else
                echo -e "\e[31m未找到对应端口的服务器\e[0m"
            fi
            ;;
        11)
            read -p "请输入端口号: " port
            server_index=$(GetServerIndexByPort "$port")
            if [ "$server_index" -ge 0 ]; then
                echo -e "\e[34m找到端口 $port 对应的服务器，正在关闭...\e[0m"
                CloseServer "${NAMES[$server_index]}"
            else
                echo -e "\e[31m未找到对应端口的服务器\e[0m"
            fi
            ;;
        *)
            echo -e "\033[31m未知指令，请重试\033[0m"
            MainBody
            ;;
    esac
}

# 创建用户和设置目录（无论当前用户是谁）
setup_user_and_dirs

# 直接运行主菜单，无需检查用户
MainBody
