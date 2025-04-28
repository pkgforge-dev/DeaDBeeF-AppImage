# DeaDBeeF-AppImage
Unofficial AppImage of the DeaDBeeF music player: https://github.com/DeaDBeeF-Player/deadbeef

Uses the officla portable builds and turns them into AppImage: https://sourceforge.net/projects/deadbeef/files/travis/linux/

* [Latest Stable Release](https://github.com/pkgforge-dev/DeaDBeeF-AppImage/releases/latest)

* [Latest Nightly Release](https://github.com/pkgforge-dev/DeaDBeeF-AppImage/releases/tag/nightly)

---------------------------------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i deadbeef` or `appman -i deadbeef`

* [dbin](https://github.com/xplshn/dbin) `dbin install deadbeef.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install deadbeef`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>
