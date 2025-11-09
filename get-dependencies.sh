#!/bin/sh

set -e
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
if [ "$DEVEL" = true ]; then
	echo "Making nightly release..."
	SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"
else
	echo "Making stable release..."
	SITE=$(wget "https://sourceforge.net/projects/deadbeef/files/travis/linux" -O - \
		| sed 's/[()",{} ]/\n/g' | grep -o 'https.*linux.*download$' \
		| grep -vi 'master\|feature\|bugfix' | head -1 | sed 's|/download||')
fi

TARBALL=$(wget "$SITE" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$" | head -1)

if [ "$DEVEL" = true ]; then
	export VERSION=$(wget "$SITE" -O - | sed 's/"/ /g' \
		| grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
else
	export VERSION=$(echo "$TARBALL" | awk -F'_' '{print $2; exit}')
fi
echo "$VERSION" > ~/version

wget --retry-connrefused --tries=30 "$TARBALL" -O /tmp/download.tar.bz2
tar xvf /tmp/download.tar.bz2
mkdir -p ./AppDir
mv -v ./deadbeef* ./AppDir/bin
chmod +x ./AppDir/bin/*

# remove all traces of gtk2
find ./AppDir -type f -iname '*gtk2*'
find ./AppDir -type f -iname '*gtk2*' -delete

