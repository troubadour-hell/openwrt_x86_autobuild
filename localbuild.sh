#!/bin/bash
#=================================================
# File name: lean.sh
# System Required: Linux
# Version: 1.0
# Lisence: MIT
# Author: SuLingGG
# Blog: https://mlapp.cn
#=================================================

export WORK_DIR=`pwd`
export OPENWRTROOT="$WORK_DIR/lede"

if [ -d "lede" ]
then
    echo "lede directory exists."
    cd lede
    rm feeds.conf.default
    wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/feeds.conf.default
    git pull
else
    echo "lede directory does not exist."
    git clone https://github.com/coolsnowwolf/lede
fi
chmod +x $WORK_DIR/scripts/*.sh
if [ -d "files" ]
then
    rm -rf files
fi

# Update feeds
echo "Updating feeds..."
cd $OPENWRTROOT
make distclean
if [ -d "customfeeds" ]
then
    rm -rf customfeeds
fi
mkdir customfeeds
git clone --depth=1 https://github.com/coolsnowwolf/packages customfeeds/packages
git clone --depth=1 https://github.com/coolsnowwolf/luci customfeeds/luci
$WORK_DIR/scripts/hook-feeds.sh

# Install Feeds
echo "Installing feeds..."
cd $OPENWRTROOT
./scripts/feeds install -a

# Load Custom Configurations
echo "Loading custom configurations..."
cd $OPENWRTROOT
cp $WORK_DIR/configs/.config .config
if [ -d "package/community" ]
then
    rm -rf package/community
fi
$WORK_DIR/scripts/lean.sh
$WORK_DIR/scripts/preset-terminal-tools.sh
sed -i '$a\CONFIG_DEVEL=y\nCONFIG_LOCALMIRROR=\"https://openwrt.cc/dl/coolsnowwolf/lede\"' .config
make defconfig

# Download Packages
echo "Downloading packages..."
cd $OPENWRTROOT
#wget https://github.com/coolsnowwolf/lede/pull/6526.patch
#git apply 6526.patch
make download -j20

# Compile
echo "Compiling..."
cd $OPENWRTROOT
make tools/compile -j$((`nproc`+1)) || make tools/compile -j72
make toolchain/compile -j$((`nproc`+1)) || make toolchain/compile -j72
make target/compile -j$((`nproc`+1)) || make target/compile -j72 IGNORE_ERRORS=1
make diffconfig
make package/compile -j$((`nproc`+1)) IGNORE_ERRORS=1 || make package/compile -j72 IGNORE_ERRORS=1
make package/index
cd $OPENWRTROOT/bin/packages/*
PLATFORM=$(basename `pwd`)
cd $OPENWRTROOT/bin/targets/*
TARGET=$(basename `pwd`)
cd *
SUBTARGET=$(basename `pwd`)

# Gnerate Firmware
cd $WORK_DIR/configs/opkg
sed -i "s/subtarget/$SUBTARGET/g" distfeeds*.conf
sed -i "s/target\//$TARGET\//g" distfeeds*.conf
sed -i "s/platform/$PLATFORM/g" distfeeds*.conf
cd $OPENWRTROOT
mkdir -p files/etc/uci-defaults/
cp $WORK_DIR/scripts/init-settings.sh files/etc/uci-defaults/99-init-settings
mkdir -p files/etc/opkg
cp $WORK_DIR/configs/opkg/distfeeds-packages-server.conf files/etc/opkg/distfeeds.conf.server
mkdir -p files/www/snapshots
cp -r bin/targets files/www/snapshots
cp $WORK_DIR/configs/opkg/distfeeds-18.06-local.conf files/etc/opkg/distfeeds.conf
cp files/etc/opkg/distfeeds.conf.server files/etc/opkg/distfeeds.conf.mirror
sed -i "s/http:\/\/192.168.123.100:2345\/snapshots/https:\/\/openwrt.cc\/snapshots\/$(date +"%Y-%m-%d")\/lean/g" files/etc/opkg/distfeeds.conf.mirror
make package/install -j$((`nproc`+1)) || make package/install -j1 V=s
make target/install -j$((`nproc`+1)) || make target/install -j1 V=s
make checksum
