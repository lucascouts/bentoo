 
# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop rpm xdg

MY_PN="ExifCleaner"
DESCRIPTION="Cross-platform desktop GUI app to clean image metadata"
HOMEPAGE="https://exifcleaner.com/"
SRC_URI="https://github.com/szTheory/${PN}/releases/download/v${PV}/${P}.x86_64.rpm"

LICENSE="MIT License"
SLOT="0"
KEYWORDS="amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="${DEPEND}
	media-libs/mesa
	media-video/ffmpeg"
	
BDEPEND="dev-util/patchelf"

QA_PREBUILT="opt/${MY_PN}/*"

S="${WORKDIR}"

src_unpack() {
	rpm_src_unpack ${A}
	cd "${S}"
}

src_install() {
	insinto /opt
	doins -r opt/${MY_PN}
	fperms 755 /opt/${MY_PN}/exifcleaner
	fperms 4755 /opt/${MY_PN}/chrome-sandbox

	insinto /usr/share/applications
	doins usr/share/applications/exifcleaner.desktop

	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	dosym -r /opt/${MY_PN}/exifcleaner /usr/bin/exifcleaner
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}