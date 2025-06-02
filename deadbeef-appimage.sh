#!/bin/sh

set -ex

ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# static bins
FAAC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/faac/nixpkgs/faac/raw.dl"
FLAC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/flac/nixpkgs/flac/raw.dl"
LAME_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/lame/nixpkgs/lame/raw.dl"
OGGENC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/vorbis-tools/ppkg/stable/oggenc/raw.dl"
OPUSENC_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/opus-tools/ppkg/stable/opusenc/raw.dl"
WAVPACK_URL="https://pkgs.pkgforge.dev/dl/bincache/x86_64-linux/wavpack/nixpkgs/wavpack/raw.dl"

if [ "$1" = 'devel' ]; then
	echo "Making nightly release..."
	APP=DeaDBeeF_Nightly
	SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"
	UPINFO="$(echo "$UPINFO" | sed 's/latest/nightly/')"
else
	echo "Making stable release..."
	APP=DeaDBeeF
	SITE=$(wget "https://sourceforge.net/projects/deadbeef/files/travis/linux" -O - \
		| sed 's/[()",{} ]/\n/g' | grep -o 'https.*linux.*download$' \
		| grep -vi 'master\|feature\|bugfix' | head -1 | sed 's|/download||')
fi

TARGET_BIN="deadbeef"
DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"
TARBALL=$(wget "$SITE" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -o "https.*linux.*$ARCH.tar.bz2.*download$" | head -1)

if [ "$1" = 'devel' ]; then
	export VERSION=$(wget "$SITE" -O - | sed 's/"/ /g' \
		| grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
else
	export VERSION=$(echo "$TARBALL" | awk -F'_' '{print $2; exit}')
fi
echo "$VERSION" > ~/version

# Prepare AppDir
mkdir ./AppDir
cd ./AppDir

wget "$TARBALL" -O download.tar.bz2
tar xvf ./*.tar.*
rm -f ./*.tar.*
mv -v ./deadbeef* ./bin
mv -v ./bin/lib   ./

wget "$ICON"    -O  ./deadbeef.svg
wget "$ICON"    -O  ./.DirIcon
wget "$DESKTOP" -O  ./"$APP".desktop

wget "$FAAC_URL"    -O  ./bin/faac
wget "$FLAC_URL"    -O  ./bin/flac
wget "$LAME_URL"    -O  ./bin/lame
wget "$OGGENC_URL"  -O  ./bin/oggenc
wget "$OPUSENC_URL" -O  ./bin/opusenc
wget "$WAVPACK_URL" -O  ./bin/wavpack
chmod +x ./bin/*

# remove all traces of gtk2
echo "Deleting GTK2..."
find . -type f -iname '*gtk2*'
find . -type f -iname '*gtk2*' -delete
echo "-------------------------------------------------------------------"

# Deploy all libs
cp -vn /usr/lib/libgtk-*      ./lib
cp -rv /usr/lib/gdk-pixbuf-*  ./lib
cp -rv /usr/lib/alsa-lib      ./lib
cp -rv /usr/lib/pipewire-*    ./lib
cp -rv /usr/lib/spa-*         ./lib
cp -vn /lib64/ld-linux*.so.*  ./ld-linux.so

ldd ./lib/* \
	./lib/alsa-lib/* \
	./bin/deadbeef \
	./bin/plugins/* 2>/dev/null \
	| awk -F"[> ]" '{print $4}' \
	| xargs -I {} cp -vn {} ./lib || true

# deploy gdk
find ./lib/gdk-pixbuf-* -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./lib
find ./lib -type f -regex '.*gdk.*loaders.cache' \
	-exec sed -i 's|/.*lib.*/gdk-pixbuf.*/.*/loaders/||g' {} \;
( cd ./lib && find ./*/* -type f -regex '.*\.so.*' -exec ln -s {} ./ \; )

# Create AppRun
echo '#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"

export PATH="$CURRENTDIR/bin:$PATH"
export GDK_PIXBUF_MODULEDIR="$(echo "$CURRENTDIR"/lib/gdk-pixbuf-*)"
export GDK_PIXBUF_MODULE_FILE="$(echo "$GDK_PIXBUF_MODULEDIR"/*/loaders.cache)"
export SPA_PLUGIN_DIR="$(echo "$CURRENTDIR"/lib/spa-*)"
export PIPEWIRE_MODULE_DIR="$(echo "$CURRENTDIR"/lib/pipewire-*)"

exec "$CURRENTDIR"/ld-linux.so \
	--library-path "$CURRENTDIR"/lib "$CURRENTDIR"/bin/deadbeef "$@"' > ./AppRun
chmod +x ./AppRun

# Strip everything
find ./ -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite \
	-i ./AppDir -o ./"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All done!"
