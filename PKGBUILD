pkgname="nweather"
pkgver="0.0.1"
pkgrel="1"
pkgdesc="A command-line application for fetching weather data from NOAA."
arch=("x86_64")
depends=("dmd" "dub")
license=("Boost")
source=("https://github.com/will-hinson/nweather/archive/refs/tags/0.0.1.tar.gz")
sha512sums=("SKIP")

package() {
    cd $pkgname-$pkgver
    dub build
    mkdir -p $pkgdir/usr/bin
    cp ./nweather $pkgdir/usr/bin
    cd ..
}