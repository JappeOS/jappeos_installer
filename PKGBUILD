# Maintainer: Jappe02 <Jappe00001@gmail.com>
pkgbase=jappeos_installer
pkgname=('jappeos_installer' 'jappeos_installerd')
pkgver=0.0.14
_tag=dev-v0.0.14
pkgrel=2
arch=('x86_64')
url="https://github.com/JappeOS/$pkgbase"
license=('AGPL-3.0-or-later')
makedepends=('git' 'clang' 'cmake' 'ninja')
makedepends=(
  'git'
  'clang'
  'cmake>=3.31'
  'ninja'
  'pkgconf'
  'gtk3'
  'dbus'
  'glib2'
  'parted'
  'systemd-libs'
)
source=("$pkgbase-$pkgver.tar.gz::$url/archive/refs/tags/$_tag.tar.gz")
sha256sums=('SKIP')

build() {
  cd "$srcdir/$pkgbase-$_tag"

  cmake -S backend -B build/backend -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build build/backend

  flutter build linux --release
}

package_jappeos_installerd() {
  pkgdesc="System installation backend for JappeOS"
  depends=(
    'coreutils'
    'util-linux'
    'pacman'
    'dbus'
    'glib2'
    'parted'
    'udev'
    'systemd'
    'arch-install-scripts'
    'jappeos_core'
    'dosfstools'
    'e2fsprogs'
    'btrfs-progs'
    'xfsprogs'
    'squashfs-tools'
  )

  cd "$srcdir/$pkgbase-$_tag"

  DESTDIR="$pkgdir" cmake --install build/backend
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/jappeos_installerd/LICENSE"
}

package_jappeos_installer() {
  pkgdesc="Installer application for JappeOS"
  depends=(
    'glibc'
    'gtk3'
    "jappeos_installerd=$pkgver-$pkgrel"
  )

  cd "$srcdir/$pkgbase-$_tag/build/linux/x64/release/bundle"

  # Install to /opt
  install -dm755 "$pkgdir/opt/jappeos_installer"
  cp -a . "$pkgdir/opt/jappeos_installer"

  # Symlink executable to /usr/bin
  install -dm755 "$pkgdir/usr/bin"
  ln -s "/opt/jappeos_installer/jappeos_installer" "$pkgdir/usr/bin/jappeos_installer"

  # Install desktop entry
  install -Dm644 "$srcdir/$pkgbase-$_tag/jappeos-installer.desktop" \
    "$pkgdir/usr/share/applications/jappeos-installer.desktop"

  install -Dm644 "$srcdir/$pkgbase-$_tag/LICENSE" \
    "$pkgdir/usr/share/licenses/jappeos_installer/LICENSE"
}