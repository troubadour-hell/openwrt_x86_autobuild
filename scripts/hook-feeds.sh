#!/bin/bash
# Svn checkout packages from immortalwrt's repository
pushd customfeeds



# Add tmate
git clone --depth=1 https://github.com/immortalwrt/openwrt-tmate

# Add gotop
rm -rf packages/admin/gotop
svn co https://github.com/immortalwrt/packages/branches/openwrt-18.06/admin/gotop packages/admin/gotop
popd

# Set to local feeds
pushd customfeeds/packages
export packages_feed="$(pwd)"
popd
pushd customfeeds/luci
export luci_feed="$(pwd)"
popd
sed -i '/src-git packages/d' feeds.conf.default
echo "src-link packages $packages_feed" >> feeds.conf.default
sed -i '/src-git luci/d' feeds.conf.default
echo "src-link luci $luci_feed" >> feeds.conf.default

# Update feeds
./scripts/feeds update -a