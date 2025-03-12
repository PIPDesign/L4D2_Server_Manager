#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31m请以 root 权限运行此脚本\e[0m"
    exit 1
fi

# 创建 l4d2 用户（如果不存在）
function create_l4d2_user() {
    if id "l4d2" &>/dev/null; then
        echo -e "\e[34m用户 l4d2 已存在\e[0m"
    else
        useradd -m -s /bin/bash l4d2
        echo -e "\e[92m用户 l4d2 创建成功\e[0m"
    fi
}

# 设置路径
L4D2_USER="l4d2"
STEAMCMD="/home/${L4D2_USER}/Steam"
DIR="${STEAMCMD}/steamapps/common/L4D2-10-15"

# 服务器名称列表
NAMES=("L4d2-test" "L4d2-1" "L4d2-2" "L4d2-3" "L4d2-4" "L4d2-5" "L4d2-6" "L4d2-11" "L4d2-12" "L4d2-13" "L4d2-14" "L4d2-15")

# 启动参数（示例，需根据实际需求填写完整）
PARAMS=(
    "-game left4dead2 +ip 0.0.0.0 +hostport 24099 +map c2m1_highway +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24001 +map c2m1_highway +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24002 +map c3m1_plankcountry +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24003 +map c5m1_waterfront +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24004 +map c6m1_riverbank +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24005 +map c7m1_docks +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24006 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24011 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24012 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24013 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24014 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
    "-game left4dead2 +ip 0.0.0.0 +hostport 24015 +map c8m1_apartment +sv_setmax 31 -tickrate 100 +exec server.cfg"
)

# 关闭方式
WAY=1  # 1 = screen指令关闭；2 = screen获取pid后kill；3 = ps获取pid后kill

####################################### 函数部分 ##########################################

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

    su - "${L4D2_USER}" -c "
        if [ -f \"${STEAMCMD}/steamcmd.sh\" ]; then
            echo -e \"\e[34mSteamCMD 已安装，跳过下载\e[0m\"
        else
            echo -e \"\e[34m下载 SteamCMD...\e[0m\"
            if ! curl -fSLo \"${TMPDIR}/steamcmd.tar.gz\" \"${STEAMCMD_URL}\"; then
                echo -e \"\e[31mSteamCMD 下载失败，请检查网络\e[0m\"
                exit 1
            fi
            mkdir -p \"${STEAMCMD}\"
            if ! tar -zxf \"${TMPDIR}/steamcmd.tar.gz\" -C \"${STEAMCMD}\"; then
                echo -e \"\e[31mSteamCMD 解压失败\e[0m\"
                exit 1
            fi
            echo -e \"\e[92mSteamCMD 安装成功\e[0m\"
        fi

        if [ -f \"${DIR}/srcds_run\" ]; then
            echo -e \"\e[34mL4D2 服务器已安装，跳过安装\e[0m\"
        else
            echo -e \"\e[34m安装 L4D2 服务器...\e[0m\"
            \"${STEAMCMD}/steamcmd.sh\" +force_install_dir \"${DIR}\" +login anonymous +app_update 222860 validate +quit
            if [ \"\${?}\" -ne 0 ]; then
                echo -e \"\e[31mL4D2 服务器安装失败，请检查网络或磁盘空间\e[0m\"
                exit 1
            fi
            echo -e \"\e[92mL4D2 服务器安装成功\e[0m\"
        fi
    "
}

# 启动服务器
function StartServer() {
    local name=$1
    local params=$2
    su - "${L4D2_USER}" -c "
        if screen -ls | grep -qE \"[0-9]+\\\\.${name}[[:space:]]\"; then
            echo -e \"\e[34m已存在名为 ${name} 的 screen 会话\e[0m\"
        else
            if ! cd \"${DIR}\"; then
                echo -e \"\e[31m无法切换到目录 ${DIR}\e[0m\"
                exit 1
            fi
            echo -e \"\e[34m开启 ${name} 服务器中...\e[0m\"
            screen -dmS \"${name}\" ./srcds_run ${params}
            sleep 1
            if screen -ls | grep -qE \"[0-9]+\\\\.${name}[[:space:]]\"; then
                echo -e \"\e[92m${name} 启动完成\e[0m\"
            else
                echo -e \"\e[31m${name} 启动失败，请检查路径或参数\e[0m\"
            fi
        fi
    "
}

# 关闭服务器
function CloseServer() {
    local name=$1
    su - "${L4D2_USER}" -c "
        if screen -ls | grep -qE \"[0-9]+\\\\.${name}[[:space:]]\"; then
            echo -e \"\e[34m关闭 ${name} 服务器中...\e[0m\"
            screen -X -S \"${name}\" quit
            sleep 1
            if ! screen -ls | grep -qE \"[0-9]+\\\\.${name}[[:space:]]\"; then
                echo -e \"\e[92m${name} 已关闭\e[0m\"
            else
                echo -e \"\e[31m${name} 关闭失败\e[0m\"
            fi
        else
            echo -e \"\e[34m未找到名为 ${name} 的 screen 会话\e[0m\"
        fi
    "
}

# 主交互菜单
function MainBody() {
    create_l4d2_user  # 确保 l4d2 用户存在
    echo -e "\n\n\n###########[ \033[32mL4d2-批量启动特感速递服.sh\033[0m ]###########"
    echo "00——安装运行依赖"
    echo "01——安装服务器"
    echo "02——开启测试服务器"
    echo "03——关闭测试服务器"
    echo "#################################################"
    read -n 2 -p "请输入对应数字选择功能: " answer
    echo
    case ${answer} in
        00) install_dependencies ;;
        01) install_server ;;
        02) StartServer "${NAMES[0]}" "${PARAMS[0]}" ;;
        03) CloseServer "${NAMES[0]}" ;;
        *)
            echo -e "\e[31m未知指令，请重试\e[0m"
            MainBody
            ;;
    esac
}

# 执行主函数
MainBody
