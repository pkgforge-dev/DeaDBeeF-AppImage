#!/bin/sh

set -eu

APP=DeaDBeeF_Nightly
SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"
TARGET_BIN="deadbeef"
DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(wget -q "$SITE" -O - | sed 's/"/ /g' | grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)

APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Prepare AppDir
mkdir -p "$APP"/AppDir/usr/share/applications
cd "$APP"/AppDir
url="$(wget -q "$SITE" -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep "x86_64.tar.bz2")"
wget $url -O download.tar.bz2
tar fx ./*.tar*
rm -f ./*.tar*

mv ./deadbeef* ./usr/bin
mv ./usr/bin/lib ./usr/lib

wget "$DESKTOP" -O ./"$APP".desktop
wget "$ICON" -O ./deadbeef.svg
sed -i 's/DeaDBeeF/DeaDBeeF Nightly/g' ./"$APP".desktop
cp ./"$APP".desktop ./usr/share/applications

# remove all traces of gtk2
echo "Deleting GTK2..."
find . -type f -iname '*gtk2*'
find . -type f -iname '*gtk2*' -delete
echo "-------------------------------------------------------------------"

# Deploy all libs
cp -vn /usr/lib/libgtk-*     ./usr/lib
cp -rv /usr/lib/alsa-lib     ./usr/lib
cp -rv /usr/lib/pipewire-0.3 ./usr/lib
cp -rv /usr/lib/spa-0.2      ./usr/lib

ldd ./usr/lib/* ./usr/lib/alsa-lib/* 2>/dev/null \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./usr/lib || true
ldd ./usr/bin/deadbeef 2>/dev/null \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./usr/lib
ldd ./usr/bin/plugins/* 2>/dev/null \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./usr/lib || true

cp -vn /lib64/ld-linux-x86-64.so.2 ./usr/lib

# DEPLOY GDK
echo "Deploying gdk..."
GDK_PATH="$(find /usr/lib -type d -regex ".*/gdk-pixbuf-2.0" -print -quit)"
cp -rv "$GDK_PATH" ./usr/lib

echo "Deploying gdk deps..."
find ./usr/lib/gdk-pixbuf-2.0 -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./usr/lib
find ./usr/lib -type f -regex '.*gdk.*loaders.cache' \
	-exec sed -i 's|/.*lib.*/gdk-pixbuf.*/.*/loaders/||g' {} \;

( cd ./usr/lib && find ./*/* -type f -regex '.*\.so.*' -exec ln -s {} ./ \; )

# Create AppRun
echo '#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
GDK_HERE="$(find "$CURRENTDIR" -type d -regex '.*gdk.*loaders' -print -quit)"
GDK_LOADER="$(find "$CURRENTDIR" -type f -regex '.*gdk.*loaders.cache' -print -quit)"

export GDK_PIXBUF_MODULEDIR="$GDK_HERE"
export GDK_PIXBUF_MODULE_FILE="$GDK_LOADER"
export SPA_PLUGIN_DIR="$CURRENTDIR/usr/lib/spa-0.2"
export PIPEWIRE_MODULE_DIR="$CURRENTDIR/usr/lib/pipewire-0.3"

exec "$CURRENTDIR"/usr/lib/ld-linux-x86-64.so.2 \
	--library-path "$CURRENTDIR"/usr/lib \
	"$CURRENTDIR"/usr/bin/deadbeef "$@"' > ./AppRun
chmod +x ./AppRun

# Strip everything
find ./usr -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$APP"
echo "All Done!"
