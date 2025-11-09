#!/bin/sh

set -e

ARCH="$(uname -m)"
VERSION="$(cat ~/version)"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

if [ "$DEVEL" = true ]; then
	APP=DeaDBeeF_Nightly
	branch=nightly
else
	APP=DeaDBeeF
	branch=latest
fi

export OUTPUT_APPIMAGE=1
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|$branch|*$ARCH.AppImage.zsync"
export OUTNAME="$APP"-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
export ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"
export DEPLOY_OPENGL=1
export DEPLOY_PIPEWIRE=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun ./AppDir/bin/* ./AppDir/bin/*/* /usr/lib/alsa-lib/*pulse*.so*

mkdir -p ./dist
mv -v ./*.AppImage* ./dist
mv -v ~/version     ./dist
