#!/bin/bash
#=================================================
# File name: lean.sh
# System Required: Linux
# Version: 1.0
# Lisence: MIT
# Author: SuLingGG
# Blog: https://mlapp.cn
#=================================================


# Clone community packages to package/community
mkdir package/community
pushd package/community

# Add Lienol's Packages
git clone --depth=1 https://github.com/Lienol/openwrt-package
rm -rf ../../customfeeds/luci/applications/luci-app-kodexplorer
rm -rf openwrt-package/verysync
rm -rf openwrt-package/luci-app-verysync
rm -rf package/helloworld

# Add luci-app-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall
svn co https://github.com/xiaorouji/openwrt-passwall/branches/luci/luci-app-passwall

# Add OpenClash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash

# Add luci-app-poweroff
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff

# Add luci-theme-argon
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config
rm -rf ../../customfeeds/luci/themes/luci-theme-argon
rm -rf ./luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
cp -f $GITHUB_WORKSPACE/data/The_Nymphaeum.jpg luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg || cp -f $WORK_DIR/data/The_Nymphaeum.jpg luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# Add apk (Apk Packages Manager)
svn co https://github.com/openwrt/packages/trunk/utils/apk
popd

# Mod zzz-default-settings
pushd package/lean/default-settings/files
sed -i '/http/d' zzz-default-settings
sed -i '/18.06/d' zzz-default-settings
export orig_version=$(cat "zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
export date_version=$(date -d "$(rdate -n -4 -p ntp.aliyun.com)" +'%Y-%m-%d')
sed -i "s/${orig_version}/${orig_version} (${date_version})/g" zzz-default-settings
popd

# Change default shell to zsh
sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# Modify default IP
sed -i 's/192.168.1.1/192.168.11.1/g' package/base-files/files/bin/config_generate

# Test kernel 5.19
sed -i 's/5.15/5.19/g' target/linux/x86/Makefile

# Add MGLRU
pushd target/linux/generic/pending-5.19
wget -O Multi-Gen-LRU-Framework.patch https://patchwork.kernel.org/series/657196/mbox/
popd
echo '
CONFIG_LRU_GEN=y
CONFIG_LRU_GEN_ENABLED=y
# CONFIG_LRU_GEN_STATS is not set
' >>./target/linux/generic/config-5.19