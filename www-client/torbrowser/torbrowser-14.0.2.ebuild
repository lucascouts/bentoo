# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Tor Browser is a network of virtual tunnels that allows you to improve your privacy and security on the Internet"
HOMEPAGE="https://www.torproject.org/"
SRC_URI="https://www.torproject.org/dist/${PN}/${PV}/tor-browser-linux-x86_64-${PV}.tar.xz"

LICENSE="BSD GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
    x11-libs/gtk+:3
    dev-libs/nss
    dev-libs/nspr
    media-libs/alsa-lib
    media-libs/mesa
    x11-libs/libX11
    x11-libs/libXrender
    x11-libs/libXt
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
    local destdir="/opt/${PN}"
    
    # Install the package to /opt/torbrowser
    insinto "${destdir}"
    doins -r tor-browser/*
    
    # Create wrapper binary
    newbin - "${PN}"
    <<-EOF
    #!/bin/sh
    exec "/opt/${PN}/Browser/start-tor-browser" --detach "\$@"
EOF
    
    # Make the TorBrowser binary executable
    fperms 755 "${destdir}/Browser/"{firefox.real,TorBrowser/Tor/tor,start-tor-browser,execdesktop}
    
    # Install icons
    newicon "${destdir}/Browser/browser/chrome/icons/default/default128.png" "${PN}.png"
    
    # Create desktop entry
    make_desktop_entry "${PN}" "Tor Browser" "${PN}" "Network;WebBrowser" "StartupWMClass=Tor Browser"
}

pkg_postinst() {
    elog "Tor Browser has been installed to /opt/${PN}"
    elog "You can start it by running 'torbrowser' from your terminal"
}