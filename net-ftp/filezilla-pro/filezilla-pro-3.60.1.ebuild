# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

WX_GTK_VER="3.0-gtk3"

inherit autotools wxwidgets xdg

MY_PV="${PV/_/-}"
MY_P="FileZilla_Pro_${MY_PV}"

DESCRIPTION="Commercial verison of FileZilla"
HOMEPAGE="https://filezillapro.com/"
SRC_URI="https://binhost.bentoo.info/${MY_P}_x86_64-linux-gnu.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# pugixml 1.7 minimal dependency is for c++11 proper configuration
RDEPEND="
	!!net-ftp/filezilla
	>=app-eselect/eselect-wxwidgets-0.7-r1
	>=dev-libs/nettle-3.1:=
	>=dev-db/sqlite-3.7
	>=dev-libs/pugixml-1.7
	>=net-libs/gnutls-3.5.7
	>=x11-libs/wxGTK-3.0.4:${WX_GTK_VER}[X]
	x11-misc/xdg-utils"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack() {
	unpack ${A} || die
	cd ${WORKDIR} || die
	mkdir opt || die
	mv Filezilla3 opt/ || die
}

src_install() {
	doins -r opt
	fperms +x /opt/FileZilla3bin/filezilla
	fperms +x /opt/FileZilla3bin/fzputtygen
	fperms +x /opt/FileZilla3bin/fzsftp
	fperms +x /opt/FileZilla3bin/fzstorj
	dodir /opt/bin
	dosym ../FileZilla3bin/filezilla /opt/bin/filezilla
	dosym ../FileZilla3bin/fzputtygen /opt/bin/fzputtygen
	dosym ../FileZilla3bin/fzsftp /opt/bin/fzsftp
	dosym ../FileZilla3bin/fzstorj /opt/bin/fzstorj
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}