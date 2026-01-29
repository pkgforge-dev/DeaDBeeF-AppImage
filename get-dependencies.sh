#!/bin/sh

set -e

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	faac             \
	flac             \
	lame             \
	libxss           \
	musepack-tools   \
	opus-tools       \
	pipewire-audio   \
	pipewire-jack    \
	vorbis-tools     \
	wavpack

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

pacman -Rsndd --noconfirm mesa # gtk3 app doesn't need mesa

echo "Gettign deadbeef..."
echo "---------------------------------------------------------------"
PROXY=https://api.rv.pkgforge.dev
STABLE="$PROXY/https://sourceforge.net/projects/deadbeef/files/travis/linux"
NIGHTLY="$PROXY/https://sourceforge.net/projects/deadbeef/files/Builds/master/linux"

if [ "$DEVEL_RELEASE" = true ]; then
	echo "Making nightly release..."
	SITE="$NIGHTLY"
else
	echo "Making stable release..."
	SITE=$(wget --retry-connrefused --tries=30 "$STABLE" -O - \
		| sed 's/[()",{} ]/\n/g'                          \
		| grep -o 'https.*linux.*download$'               \
		| grep -vi 'master\|feature\|bugfix'              \
		| head -1                                         \
		| sed 's|/download||'
	)
fi

# the amount of hacks to get a working link...
ARTIFACT=$(wget --retry-connrefused --tries=30 "$SITE" -O - \
	| sed 's/[()",{} ]/\n/g'                            \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$"  \
	| awk -F '/' '{print  $(NF-1); exit}'
)
VERSION=$(wget --retry-connrefused --tries=30 "$SITE" -O - \
	| sed 's/[()",{} ]/\n/g'                            \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$"  \
	| awk -F '/' '{print  $(NF-2); exit}'
)

if [ "$DEVEL_RELEASE" = true ]; then
	TARBALL="https://flylife.dl.sourceforge.net/project/deadbeef/Builds/master/linux/$ARTIFACT?viasf=1"
else
	TARBALL="https://excellmedia.dl.sourceforge.net/project/deadbeef/travis/linux/$VERSION/$ARTIFACT?viasf=1"
fi

echo ------------------------------------------------------------------------
echo "$TARBALL"
echo ------------------------------------------------------------------------
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
