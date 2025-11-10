#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel       \
	curl             \
	faac             \
	flac             \
	git              \
	lame             \
	libxss           \
	musepack-tools   \
	opus-tools       \
	pipewire-audio   \
	pipewire-jack    \
	pulseaudio       \
	pulseaudio-alsa  \
	vorbis-tools     \
	wavpack          \
	wget             \
	xorg-server-xvfb \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh gtk3-mini gdk-pixbuf2-mini librsvg-mini opus-mini libxml2-mini

pacman -Rsndd --noconfirm mesa

echo "Gettign deadbeef..."
echo "---------------------------------------------------------------"
PROXY=https://api.rv.pkgforge.dev
STABLE="$PROXY/https://sourceforge.net/projects/deadbeef/files/travis/linux"
NIGHTLY="$PROXY/https://sourceforge.net/projects/deadbeef/files/Builds/master/linux"

if [ "$DEVEL" = true ]; then
	echo "Making nightly release..."
	SITE="$NIGHTLY"
else
	echo "Making stable release..."
	SITE=$(wget "$STABLE" -O - \
		| sed 's/[()",{} ]/\n/g' | grep -o 'https.*linux.*download$' \
		| grep -vi 'master\|feature\|bugfix' | head -1 | sed 's|/download||')
fi

TARBALL=$(wget "$SITE" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$" | head -1)

wget --retry-connrefused --tries=30 "$TARBALL" -O /tmp/download.tar.bz2
tar xvf /tmp/download.tar.bz2
VERSION=$(echo ./deadbeef-*)
echo "${VERSION#*-}" > ~/version

mkdir -p ./AppDir
mv -v ./deadbeef-* ./AppDir/bin
chmod +x ./AppDir/bin/*

# remove all traces of gtk2
find ./AppDir -type f -iname '*gtk2*'
find ./AppDir -type f -iname '*gtk2*' -delete
