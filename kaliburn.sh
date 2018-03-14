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
coreutils
debian-installer-launcher
kali-archive-keyring
kali-debtags
#kali-defaults
#kali-menu
#kali-root-login
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
p7zip-full
parted
#python3
#redshift
stow
vim
EOF

################################################################################
# Modify files within file system
# Single quotes around heredoc prevent expansion within contents
################################################################################

# Add lines to default bashrc
touch kali-config/common/hooks/live/bashrc.chroot && chmod +x $_
cat > kali-config/common/hooks/live/bashrc.chroot << 'EOF'
#!/bin/bash
# Script to modify bashrc

# Append the following lines
cat >> /root/.bashrc << 'END'

# Set editor
export EDITOR='vim'
export VISUAL='vim'

# Set path to include personal scripts
export PATH="$PATH:$HOME/.scripts"

# Solarized theme for tty
# https://github.com/joepvd/tty-solarized
if [ "$TERM" = "linux" ]; then
    echo -en "\e]PB657b83" # S_base00
    echo -en "\e]PA586e75" # S_base01
    echo -en "\e]P0073642" # S_base02
    echo -en "\e]P62aa198" # S_cyan
    echo -en "\e]P8002b36" # S_base03
    echo -en "\e]P2859900" # S_green
    echo -en "\e]P5d33682" # S_magenta
    echo -en "\e]P1dc322f" # S_red
    echo -en "\e]PC839496" # S_base0
    echo -en "\e]PE93a1a1" # S_base1
    echo -en "\e]P9cb4b16" # S_orange
    echo -en "\e]P7eee8d5" # S_base2
    echo -en "\e]P4268bd2" # S_blue
    echo -en "\e]P3b58900" # S_yellow
    echo -en "\e]PFfdf6e3" # S_base3
    echo -en "\e]PD6c71c4" # S_violet
    clear # against bg artifacts
fi
END
EOF

# Change hostname
mkdir -p kali-config/common/includes.chroot/etc && \
cat > kali-config/common/includes.chroot/etc/hostname << 'EOF'
kaliburn
EOF

# Change tty font size
touch kali-config/common/hooks/live/tty.chroot && chmod +x $_
cat > kali-config/common/hooks/live/tty.chroot << 'EOF'
#!/bin/bash
# Script to change tty font size
# See man console-setup

# Target file
TARGET=/etc/default/console-setup

# Replace variables in target file
sed -i 's/FONTFACE=/c\FONTFACE="TerminusBold"' $TARGET
sed -i 's/FONTSIZE=/c\FONTSIZE="16"' $TARGET
EOF

# Blacklist pcspkr module
mkdir -p kali-config/common/includes.chroot/etc/modprobe.d && \
cat > kali-config/common/includes.chroot/etc/modprobe.d/nobeep.conf << 'EOF'
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
# Background highlight (Base02)
sed -i 's/76a1d0/073642/g' kali-config/common/includes.binary/isolinux/stdmenu.cfg

# Remove menu entries
rm kali-config/common/hooks/live/persistence-menu.binary
rm kali-config/common/hooks/live/accessibility-menu.binary

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
