#!/bin/sh

set -eux
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel          \
	curl                \
	desktop-file-utils  \
	git                 \
	libxss              \
	llvm                \
	mesa                \
	patchelf            \
	pipewire-audio      \
	pulseaudio          \
	pulseaudio-alsa     \
	strace              \
	wget                \
	xorg-server-xvfb    \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh libxml2-mini gtk3-mini opus-mini gdk-pixbuf2-mini

echo "All done!"
echo "---------------------------------------------------------------"
