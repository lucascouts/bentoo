# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

DESCRIPTION="The Mullvad VPN client app for desktop"
HOMEPAGE="https://www.mullvad.net"
SRC_URI="
	amd64? ( https://github.com/mullvad/mullvadvpn-app/releases/download/${PV}/MullvadVPN-${PV}_amd64.deb )
	arm64? ( https://github.com/mullvad/mullvadvpn-app/releases/download/${PV}/MullvadVPN-${PV}_arm64.deb )
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

DEPEND="
	net-misc/iputils
	x11-libs/libnotify
	dev-libs/libappindicator:3
	dev-libs/nss
"
RDEPEND="${DEPEND}"
BDEPENDS="
	$(unpacker_src_uri_depends)
"

src_unpack() {
	mkdir ${S}
	cd ${S}
	unpacker ${A}
}

src_prepare() {
	# Fix zsh-completion path
	mv ${S}/usr/{local,}/share/zsh
	rm -r  ${S}/usr/local

	# don't install "docs" (they're just deb changelogs)
	rm -r ${S}/usr/share/doc

	eapply_user
}

src_install() {
	# 'install' messes with permissions so just cp here
	cp -r ${S}/* ${ED}

	# Wrapper for the GUI
	newbin ${FILESDIR}/wrapper.sh mullvad-gui
}
