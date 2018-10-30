# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

SRC_URI_BASE="https://github.com/electron/electron/releases/download"
DESCRIPTION="Cross platform application development framework based on web technologies"
HOMEPAGE="https://electron.atom.io"
SRC_URI="
	amd64? ( ${SRC_URI_BASE}/v${PV}/${PN/-bin}-v${PV}-linux-x64.zip -> ${P}-x64.zip )
	x86? ( ${SRC_URI_BASE}/v${PV}/${PN/-bin}-v${PV}-linux-ia32.zip -> ${P}-ia32.zip )
	arm? ( ${SRC_URI_BASE}/v${PV}/${PN/-bin}-v${PV}-linux-arm.zip -> ${P}-arm.zip )
	arm64? ( ${SRC_URI_BASE}/v${PV}/${PN/-bin}-v${PV}-linux-arm64.zip -> ${P}-arm64.zip )
"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="2.0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~x86"

RDEPEND="
	dev-libs/atk
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nss
	gnome-base/gconf:2
	media-gfx/graphite2
	media-libs/alsa-lib
	media-libs/fontconfig:1.0
	media-libs/libepoxy
	media-libs/libpng
	net-print/cups
	sys-apps/dbus
	virtual/opengl
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libxcb
	x11-libs/libXtst
	x11-libs/pango
"
DEPEND="app-arch/unzip"

QA_PRESTRIPPED="
	/opt/${MY_PN}/libffmpeg.so
	/opt/${MY_PN}/libnode.so
	/opt/${MY_PN}/electron
"

S="${WORKDIR}"
MY_PN="${PN}-${SLOT}"

src_install() {
	exeinto "/opt/${MY_PN}"
	doexe electron

	insinto "/opt/${MY_PN}"
	doins -r locales resources
	doins ./*.pak \
		icudtl.dat \
		natives_blob.bin \
		snapshot_blob.bin \
		libnode.so \
		libffmpeg.so

	dosym "../../opt/${MY_PN}/electron" "/usr/bin/electron-${SLOT}"
}
