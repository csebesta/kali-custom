#!/bin/bash
# Kali Linux ISO recipe for minimal rescue image
# Written by Chad Sebesta

# Update and install dependencies
apt-get update
apt-get install git live-build cdebootstrap devscripts stow -y
git clone git://git.kali.org/live-build-config.git
cd live-build-config

# Custom package list
cat > kali-config/variant-default/package-lists/kali.list.chroot << EOF
# Defaults
alsa-tools
debian-installer-launcher
kali-archive-keyring
kali-debtags
kali-defaults
kali-menu
kali-root-login
locales-all
xorg

# Desktop environment (slide dependencies)
feh
graphicsmagick
suckless-tools
xmobar
xmonad

# Utilities
git
gparted
#kali-linux-top10
redshift
rxvt-unicode
vim
EOF

# Set up slide
git clone https://github.com/csebesta/slide kali-config/common/includes.chroot/root
cd kali-config/common/includes.chroot/root/slide
./setup.sh

# Build image
./build.sh -v
