# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="A powerful and versatile slicer"
HOMEPAGE="https://mango3d.io"
RESTRICT="bindist mirror"

SRC_URI="https://mango-lychee.nyc3.digitaloceanspaces.com/LycheeSlicer-${PVR}.deb -> ${P}.deb"

KEYWORDS="~amd64"

# I honestly have no idea what the license is :-( Sorry...
LICENSE="GPL-3+"
SLOT="0"


RDEPEND="
	app-accessibility/at-spi2-core
	app-arch/bzip2
	app-crypt/libmd
	dev-libs/expat
	dev-libs/fribidi
	dev-libs/glib
	dev-libs/libbsd
	dev-libs/libffi
	dev-libs/libpcre2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/openssl
	media-gfx/graphite2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/harfbuzz
	media-libs/libepoxy
	media-libs/libglvnd
	media-libs/libjpeg-turbo
	media-libs/libpng
	media-libs/mesa
	net-dns/avahi
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-devel/gcc
	sys-libs/glibc
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/gtk+
	x11-libs/libX11
	x11-libs/libXau
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXdmcp
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-libs/pixman"

DEPEND="${RDEPEND}"
S="${WORKDIR}"

src_unpack() {
	unpack ${P}.deb
	unpack ./data.tar.xz
}

src_install() {
	doins -r "opt"
	
	insinto "/usr/share/icons"
	doins -r "usr/share/icons"
	
	insinto "/usr/share/applications"
	doins -r "usr/share/applications"
	
	for F in chrome-sandbox chrome_crashpad_handler lycheeslicer; do
		fperms 755 "/opt/LycheeSlicer/${F}" 
	done
	
	fperms 4755 "/opt/LycheeSlicer/chrome-sandbox"
	
	dosym "/opt/LycheeSlicer/lycheeslicer" "/usr/bin/lycheeslicer"
}
