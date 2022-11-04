#!/bin/bash
# forked from lone_wind
clean_up () {
    rm -rf openwrt*.img* ${img_path}/openwrt*.img* sha256sums-sh* *update.sh*
}
#硬盘检查
hd_check () {
    hd_id='mmcblk0'
    if [ ! -d /sys/block/$hd_id ]; then
        hd_id='mmcblk1'
        if [ ! -d /sys/block/$hd_id ]; then
            hd_id='sda'
        fi
    fi
}
#仓库选择
repo_set () {
    repo_url=https://github.com/troubadour-hell/openwrt_x86_autobuild/releases
    firmware_id=openwrt-x86-64-generic-squashfs-combined-efi-sh.img
}
#寻找固件
search_file () {
    cd ${work_path} && clean_up && days=$(($days+1))
    #echo `${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean/sha256sums-sh`
    wget -q ${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean/sha256sums-sh
    exist_judge
}
#存在判断
exist_judge () {
    if [ -f sha256sums-sh ]; then
        echo -e '\e[92m已找到当前日期的固件\e[0m' && echo `(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)`-Lean
        firmware_confirm
    elif [ $days == 21 ]; then
        echo -e '\e[91m未找到合适固件，脚本退出\e[0m' && exit;
    else
        #echo -e '\e[91m当前固件不存在，寻找前一天的固件\e[0m'
        search_file
    fi
}
#固件确认
firmware_confirm () {
    read -r -p "是否使用此固件? [Y/N]确认 [E]退出 " skip
    case $skip in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已确认，开始下载固件\e[0m'
            wget ${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean/${firmware_id}.gz
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m寻找前一天的固件\e[0m' && search_file
            ;;
        [eE][xX][iI][tT]|[eE])
            echo -e '\e[91m取消固件下载，退出升级\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认，输入[E]退出\e[0m' && firmware_confirm
            ;;
    esac
}
#固件验证
firmware_check () {
    if [ -f ${img_path}/${firmware_id}  ]; then
        echo -e '\e[92m检查升级文件大小\e[0m' && du -sh ${img_path}/${firmware_id}
    elif [ -f ${firmware_id}.gz ]; then
        echo -e '\e[92m计算固件的sha256sum值\e[0m' && sha256sum ${firmware_id}.gz
        echo -e '\e[92m对比下列sha256sum值，检查固件是否完整\e[0m' && grep -i ${firmware_id}.gz sha256sums-sh
    else
        echo -e '\e[91m没有相关升级文件，请检查网络\e[0m' && exit;
    fi
    version_confirm
}
#版本确认
version_confirm () {
    read -p "是否确认升级? [Y/N] " confirm
    case $confirm in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已确认升级\e[0m'
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m已确认退出\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认\e[0m' && version_confirm
            ;;
    esac
}
#解压固件
unzip_fireware () {
    echo -e '\e[92m开始解压固件\e[0m' && gzip -cd ${firmware_id}.gz > ${img_path}/${firmware_id}
    if [ -f ${img_path}/${firmware_id} ]; then
        echo -e '\e[92m已解压出升级文件\e[0m' && firmware_check
    else
        echo -e '\e[91m解压固件失败\e[0m' && clean_up && exit;
    fi
}
#升级系统
update_system () {
    echo -e '\e[92m开始升级系统\e[0m'
    read -r -p "是否保存配置? [Y/N]确认 [E]退出 " skip
    case $skip in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已选择保存配置\e[0m' && sysupgrade -F ${firmware_id}
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m已选择不保存配置\e[0m' && sysupgrade -F -n ${firmware_id}
            ;;
        [eE][xX][iI][tT]|[eE])
            echo -e '\e[91m取消升级\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认，输入[E]退出\e[0m' && update_system
            ;;
    esac
}
#刷写系统
dd_system () {
    echo -e '\e[92m开始升级系统\e[0m'
    dd if=${img_path}/${firmware_id} of=/dev/${hd_id}
    echo -e '\e[92m刷写系统完毕，请手动断电再上电\e[0m'
}
#系统更新
update_firmware () {
    img_path=/tmp && clean_up &&  hd_check
    mount -t tmpfs -o remount,size=100% tmpfs /tmp
    real_mem=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}') && mini_mem=1572864
    if [ $real_mem -ge $mini_mem ]; then 
        work_path=/tmp
        repo_set && search_file && firmware_check && unzip_fireware
        update_system
    else
        echo -e '\e[91m您的内存小于2G，升级将不保留配置\e[0m'
        work_path=/root && version_num=3
        repo_set && search_file && firmware_check && unzip_fireware
        dd_system
    fi
}

update_firmware
