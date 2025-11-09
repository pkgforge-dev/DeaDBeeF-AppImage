#!/bin/sh

set -e
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel          \
	curl                \
	git                 \
	libxss              \
	pipewire-audio      \
	pipewire-jack       \
	pulseaudio          \
	pulseaudio-alsa     \
	wget                \
	xorg-server-xvfb    \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-common --prefer-nano

echo "Gettign deadbeef..."
echo "---------------------------------------------------------------"

if [ "$DEVEL" = true ]; then
	echo "Making nightly release..."
	APP=DeaDBeeF_Nightly
	SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"
else
	echo "Making stable release..."
	APP=DeaDBeeF
	SITE=$(wget "https://sourceforge.net/projects/deadbeef/files/travis/linux" -O - \
		| sed 's/[()",{} ]/\n/g' | grep -o 'https.*linux.*download$' \
		| grep -vi 'master\|feature\|bugfix' | head -1 | sed 's|/download||')
fi

if [ "$DEVEL" = true ]; then
	export VERSION=$(wget "$SITE" -O - | sed 's/"/ /g' \
		| grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
else
	export VERSION=$(echo "$TARBALL" | awk -F'_' '{print $2; exit}')
fi
echo "$VERSION" > ~/version

TARBALL=$(wget "$SITE" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$" | head -1)

wget --retry-connrefused --tries=30 "$TARBALL" -O /tmp/download.tar.bz2
tar xvf /tmp/download.tar.bz2
mkdir -p ./AppDir
mv -v ./deadbeef* ./AppDir/bin

# remove all traces of gtk2
find ./AppDir -type f -iname '*gtk2*'
find ./AppDir -type f -iname '*gtk2*' -delete

# add static binaries
echo "Adding static bins..."
FAAC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/faac/nixpkgs/faac/raw.dl"
FLAC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/flac/nixpkgs/flac/raw.dl"
LAME_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/lame/nixpkgs/lame/raw.dl"
OGGENC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/vorbis-tools/ppkg/stable/oggenc/raw.dl"
OPUSENC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/opus-tools/ppkg/stable/opusenc/raw.dl"
WAVPACK_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/wavpack/nixpkgs/wavpack/raw.dl"

wget --retry-connrefused --tries=30 "$FAAC_URL"    -O  ./AppDir/bin/faac
wget --retry-connrefused --tries=30 "$FLAC_URL"    -O  ./AppDir/bin/flac
wget --retry-connrefused --tries=30 "$LAME_URL"    -O  ./AppDir/bin/lame
wget --retry-connrefused --tries=30 "$OGGENC_URL"  -O  ./AppDir/bin/oggenc
wget --retry-connrefused --tries=30 "$OPUSENC_URL" -O  ./AppDir/bin/opusenc
wget --retry-connrefused --tries=30 "$WAVPACK_URL" -O  ./AppDir/bin/wavpack
chmod +x ./AppDir/bin/*
