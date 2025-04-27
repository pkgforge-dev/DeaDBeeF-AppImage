#!/bin/sh

set -ex

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"

if [ "$1" = 'devel' ]; then
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

# Prepare AppDir
mkdir ./AppDir
cd ./AppDir

wget "$TARBALL" -O download.tar.bz2
tar xvf ./*.tar.*
rm -f ./*.tar.*

mv -v ./deadbeef* ./bin
mv -v ./bin/lib   ./

wget "$DESKTOP" -O ./"$APP".desktop
wget "$ICON" -O ./deadbeef.svg

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

export GDK_PIXBUF_MODULEDIR="$(echo "$CURRENTDIR"/lib/gdk-pixbuf-*)"
export GDK_PIXBUF_MODULE_FILE="$(echo "$GDK_PIXBUF_MODULEDIR"/*/loaders.cache)"
export SPA_PLUGIN_DIR="$(echo "$CURRENTDIR"/lib/spa-*)"
export PIPEWIRE_MODULE_DIR="$(echo "$CURRENTDIR"/lib/pipewire-*)"

exec "$CURRENTDIR"/ld-linux.so \
	--library-path "$CURRENTDIR"/lib "$CURRENTDIR"/bin/deadbeef "$@"' > ./AppRun
chmod +x ./AppRun

# Strip everything
find ./ -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool -n -u "$UPINFO" \
	"$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "All Done!"
