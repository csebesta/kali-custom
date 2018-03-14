#!/bin/bash
# Kali Linux ISO recipe for minimal rescue image
# Written by Chad Sebesta

# Reference material:
# https://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html
# https://docs.kali.org/kali-dojo/02-mastering-live-build
# https://github.com/offensive-security/kali-linux-recipes
# https://kali.training/topic/building-custom-kali-live-iso-images/

################################################################################
# Kaliburn linux
################################################################################

# Update and install dependencies
apt-get update
apt-get install git curl live-build cdebootstrap devscripts stow graphicsmagick -y
git clone git://git.kali.org/live-build-config.git
cd live-build-config

# Custom package list
cat > kali-config/variant-default/package-lists/kali.list.chroot << EOF
# ----------------------------------------------------------------------
# Defaults suggested by kali documentation
alsa-tools
debian-installer-launcher
kali-archive-keyring
kali-debtags
#kali-defaults
#kali-menu
kali-root-login
locales-all
#pulseaudio
#wireless-tools
xorg

# ----------------------------------------------------------------------
# Desktop environment (slide dependencies)
feh
graphicsmagick
rxvt-unicode
suckless-tools
xmobar
xmonad

# ----------------------------------------------------------------------
# Utilities and tools
firefox-esr
git
gparted
#kali-linux-top10
#redshift
stow
vim
EOF

################################################################################
# Modify files and file system
# Single quotes around heredoc prevent expansion within contents
################################################################################

# Add lines to various files after creation
touch kali-config/common/hooks/live/modifications.chroot && chmod +x $_
cat > kali-config/common/hooks/live/modifications.chroot << 'EOF'
#!/bin/bash
# Script to modify contents of file system

# ----------------------------------------------------------------------
# Modify bashrc
cat >> /root/.bashrc << 'END'

# Set editor
export EDITOR='vim'
export VISUAL='vim'

# Set path to include personal scripts
export PATH="$PATH:$HOME/.scripts"
END
EOF

# Blacklist pcspkr module
cat > kali-config/common/hooks/includes.chroot/etc/modprobe.d/nobeep.conf << 'EOF'
blacklist pcspkr
EOF

# Set up slide
git clone https://github.com/csebesta/slide \
kali-config/common/includes.chroot/root/.slide \
&& cd kali-config/common/includes.chroot/root/.slide

# Remove files such that slide will stow correctly
rm ../.bashrc

# Stow directories
# Bash will fail to stow
for directory in */; do

	stow -t .. $directory > /dev/null 2>&1 \
	&& echo "Stowed $directory" \
	|| echo "Failed to stow $directory"

done

# Return to previous directory
cd - > /dev/null 2>&1

################################################################################
# Modify isolinux
################################################################################

# Modify splash screen
gm convert \
	-size 640x480 xc:#002b36 \
	kali-config/common/includes.binary/isolinux/splash.png

# Change color of menu entries

################################################################################
# Build image
################################################################################

## Exit for testing purposes
#exit && echo "Exiting..."

## Build image for older hardware
#sed -i 's/686-pae/686/g' auto/config
#./build.sh --distribution kali-rolling --arch i386 --verbose

# Build image
./build.sh -v
