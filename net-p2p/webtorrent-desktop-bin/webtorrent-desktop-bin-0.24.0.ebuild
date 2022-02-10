# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Source overlay: https://github.com/BlueManCZ/edgets

EAPI=7
inherit desktop unpacker xdg-utils

MY_PN="${PN/-bin/}"
UP_PN="${MY_PN^}"

DESCRIPTION="WebTorrent, the streaming torrent client. For Mac, Windows, and Linux."
HOMEPAGE="https://webtorrent.io/desktop/"
SRC_URI="amd64? ( https://github.com/webtorrent/webtorrent-desktop/releases/download/v${PV}/${MY_PN}_${PV}_amd64.deb -> ${P}-amd64.deb )
	arm64? ( https://github.com/webtorrent/webtorrent-desktop/releases/download/v${PV}/${MY_PN}_${PV}_arm64.deb -> ${P}-arm64.deb )"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="doc gnome-keyring libnotify pulseaudio xscreensaver xtest"

RDEPEND="app-accessibility/at-spi2-core
	dev-libs/nss
	gnome-keyring? ( gnome-base/gnome-keyring )
	gnome-base/gvfs
	libnotify? ( x11-libs/libnotify )
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/vulkan-loader
	media-video/ffmpeg[chromium]
	pulseaudio? ( media-sound/pulseaudio )
	sys-apps/lsb-release
	sys-apps/util-linux
	x11-libs/gtk+
	xscreensaver? ( x11-libs/libXScrnSaver )
	xtest? ( x11-libs/libXtst )
	x11-misc/xdg-utils"

S="${WORKDIR}"

QA_PREBUILT="*"

src_prepare() {
	rm "usr/lib/${MY_PN}/"*".so"
	rm -r "usr/lib/${MY_PN}/swiftshader"

	sed -i "/Version/d" "usr/share/applications/${MY_PN}.desktop"
	sed -i "/^StartupWMClass/ s/-desktop //g" "usr/share/applications/${MY_PN}.desktop"
	# https://github.com/webtorrent/webtorrent-desktop/pull/1865

	default
}

src_install() {
	if use doc; then
		dodoc -r "usr/share/doc/${MY_PN}/"*
	fi

	insinto "/opt/${MY_PN}"
	doins -r "usr/lib/${MY_PN}/"*

	insinto "/usr/share"
	doins -r "usr/share/"{"applications","icons","lintian"}

	exeinto "/opt/${MY_PN}"
	doexe "usr/lib/${MY_PN}/WebTorrent" "usr/lib/${MY_PN}/chrome-sandbox"

	dosym "/usr/"$(get_libdir)"/chromium/libffmpeg.so" "/opt/${MY_PN}/libffmpeg.so"

	dosym "/opt/${MY_PN}/WebTorrent" "/usr/bin/${MY_PN}"
	dosym "/opt/${MY_PN}/" "/usr/share/${MY_PN}"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
