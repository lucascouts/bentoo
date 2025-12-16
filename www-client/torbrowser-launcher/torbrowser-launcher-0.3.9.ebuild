# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1 optfeature xdg

DESCRIPTION="Securely download, verify, install and launch Tor Browser"
HOMEPAGE="https://gitlab.torproject.org/tpo/applications/torbrowser-launcher"
SRC_URI="https://gitlab.torproject.org/tpo/applications/${PN}/-/archive/v${PV}/${PN}-v${PV}.tar.bz2"
S="${WORKDIR}/${PN}-v${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Firefox/Tor Browser binary dependencies
FIREFOX_BIN="
	app-accessibility/at-spi2-core
	dev-libs/dbus-glib
	>=dev-libs/glib-2.26:2
	media-libs/fontconfig
	>=media-libs/freetype-2.4.10
	sys-apps/dbus
	virtual/freedesktop-icon-theme
	>=x11-libs/cairo-1.10[X]
	x11-libs/gdk-pixbuf
	>=x11-libs/gtk+-3.11:3[wayland?,X]
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libXt
	>=x11-libs/pango-1.22.0
"

# Runtime dependencies
RDEPEND="
	${PYTHON_DEPS}
	${FIREFOX_BIN}
	dev-python/distro[${PYTHON_USEDEP}]
	dev-python/gpgmepy[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/PySide6[${PYTHON_USEDEP},widgets]
	dev-python/pysocks[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	!www-client/torbrowser
"

# Build-time dependencies
BDEPEND="
	${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

IUSE="wayland"

python_install_all() {
	distutils-r1_python_install_all

	# Install documentation
	dodoc README.md CHANGELOG.md

	# Install AppArmor profiles if available
	if use kernel_linux; then
		insinto /etc/apparmor.d
		if [[ -d "${S}"/apparmor ]]; then
			doins -r "${S}"/apparmor/*
		fi
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	elog ""
	elog "Tor Browser Launcher downloads and verifies Tor Browser Bundle"
	elog "from https://www.torproject.org/"
	elog ""
	elog "The first time you run torbrowser-launcher, it will download"
	elog "Tor Browser Bundle for you and verify its signature."
	elog ""
	
	optfeature "updating over system Tor" net-vpn/tor dev-python/txsocksx
	
	if use kernel_linux; then
		elog ""
		elog "AppArmor profiles have been installed to /etc/apparmor.d/"
		elog "You may need to reload them with:"
		elog "  systemctl reload apparmor"
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
}
