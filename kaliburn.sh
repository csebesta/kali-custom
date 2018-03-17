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
alsa-utils
console-setup
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

# Configure environment
mkdir -p kali-config/common/includes.chroot/etc && \
cat > kali-config/common/includes.chroot/etc/environment << 'EOF'
PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.scripts'
EDITOR='vim'
VISUAL='vim'
EOF

# Change hostname
mkdir -p kali-config/common/includes.chroot/etc && \
cat > kali-config/common/includes.chroot/etc/hostname << 'EOF'
kaliburn
EOF

# Change tty attributes
# Values copied from standard kali installation
mkdir -p kali-config/common/includes.chroot/etc/default && \
cat > kali-config/common/includes.chroot/etc/default/console-setup << 'EOF'
ACTIVE_CONSOLES="/dev/tty[1-6]"
CHARMAP="UTF-8"
CODESET="Lat15"
FONTFACE="TerminusBold"
FONTSIZE="20x10"
VIDEOMODE=
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

# Overwrite default xinitrc with testing values
cat > kali-config/common/includes.chroot/root/.xinitrc << 'EOF'
export PATH="$PATH:$HOME/.scripts"
xrdb ~/.Xresources
xsetroot -cursor_name left_ptr
backinfo.sh
exec xmonad
EOF

################################################################################
# Software configuration
################################################################################

# Modify firefox preferences
# https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
mkdir -p kali-config/common/includes.chroot/etc/firefox-esr && \
cat > kali-config/common/includes.chroot/etc/firefox-esr/kaliburn.js << 'EOF'
/* Kaliburn default settings */
lockPref("browser.startup.homepage", "https://google.com");
EOF

################################################################################
# Modify isolinux
################################################################################

# Modify splash screen
gm convert \
	-size 640x480 xc:#002b36 \
	kali-config/common/includes.binary/isolinux/splash.png

# Change color of menu entries
# Color format is #AARRGGBB
# Background highlight (Base02)
sed -i 's/76a1d0ff/ff073642/g' kali-config/common/includes.binary/isolinux/stdmenu.cfg

# Remove menu entries
rm kali-config/common/hooks/live/persistence-menu.binary
rm kali-config/common/hooks/live/accessibility-menu.binary

# Add hook to remove other menu entries
touch kali-config/common/hooks/live/remove-menu.binary && chmod +x $_
cat > kali-config/common/hooks/live/remove-menu.binary << 'EOF'
#!/bin/bash
# Script to remove unwanted menu entries

if [ ! -d isolinux ]; then
	cd binary
fi

rm isolinux/install.cfg
EOF

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
