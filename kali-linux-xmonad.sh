#!/bin/bash
# Kali Linux ISO recipe for minimal rescue image
# Written by Chad Sebesta

# Reference material:
# https://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html
# https://docs.kali.org/kali-dojo/02-mastering-live-build
# https://github.com/offensive-security/kali-linux-recipes
# https://kali.training/topic/building-custom-kali-live-iso-images/

# Update and install dependencies
#apt-get update
#apt-get install git curl live-build cdebootstrap devscripts stow graphicsmagick -y
git clone git://git.kali.org/live-build-config.git
cd live-build-config

# Custom package list
cat > kali-config/variant-default/package-lists/kali.list.chroot << EOF
# Defaults suggested by kali documentation
alsa-tools
#debian-installer-launcher
kali-archive-keyring
kali-debtags
kali-defaults
kali-menu
kali-root-login
locales-all
pulseaudio
wireless-tools
xorg

# Desktop environment (slide dependencies)
feh
graphicsmagick
suckless-tools
xmobar
xmonad

# Utilities and tools
firefox-esr
git
gparted
#kali-linux-top10
redshift
rxvt-unicode
stow
vim
EOF

# Populate skel directory
mkdir -p kali-config/common/includes.chroot/etc/skel/{Desktop,Documents,Downloads,Music,Pictures,Public,Templates,Videos}

# Modify splash screen
gm convert \
	-size 640x480 xc:#002b36 \
	kali-config/common/bootloaders/grub-pc/splash.png

# Modify splash screen
# This is the one that works
gm convert \
	-size 640x480 xc:#002b36 \
	kali-config/common/includes.binary/isolinux/splash.png

# This method does not work because information cannot be appended to a file that does not exist yet
# The file does not exist until build.sh is run
## Configure profile
#mkdir -p kali-config/common/includes.chroot/etc
#cat >> kali-config/common/includes.chroot/etc/profile << EOF
#
## Include scripts directory
#export PATH="$PATH:$HOME/.scripts"
#EOF

# Set up slide
git clone https://github.com/csebesta/slide \
kali-config/common/includes.chroot/root/.slide \
&& cd kali-config/common/includes.chroot/root/.slide

# Stow directories
# Bash will fail to stow
for directory in */; do

	stow -t .. $directory > /dev/null 2>&1 \
	&& echo "Stowed $directory" \
	|| echo "Failed to stow $directory"

done

# Return to previous directory
cd -

# Exit for testing purposes
exit && echo "Exiting program"

# Build image
./build.sh -v
