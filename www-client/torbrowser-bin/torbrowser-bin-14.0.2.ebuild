# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="The Tor Browser"
HOMEPAGE="https://www.torproject.org/"
SRC_URI="amd64? ( ${HOMEPAGE}/dist/torbrowser/${PV}/tor-browser-linux-x86_64-${PV}.tar.xz -> ${P}-amd64.tar.xz )"

LICENSE="BSD GPL-3 MPL-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="wayland"
RESTRICT="strip"

BDEPEND="app-arch/xz-utils"

RDEPEND="
    dev-libs/dbus-glib
    dev-libs/glib:2
    dev-libs/nspr
    dev-libs/nss
    media-libs/alsa-lib
    media-libs/fontconfig
    media-libs/freetype:2
    media-libs/mesa
    sys-apps/dbus
    virtual/freedesktop-icon-theme
    x11-libs/cairo[X]
    x11-libs/gdk-pixbuf:2
    x11-libs/gtk+:3[X,wayland?]
    x11-libs/libX11
    x11-libs/libXcomposite
    x11-libs/libXcursor
    x11-libs/libXdamage
    x11-libs/libXext
    x11-libs/libXfixes
    x11-libs/libXi
    x11-libs/libXrandr
    x11-libs/libXrender
    x11-libs/libxcb
    x11-libs/pango
"

QA_PREBUILT="
    opt/${PN}/Browser/firefox
    opt/${PN}/Browser/firefox.real
    opt/${PN}/Browser/libmozavcodec.so
    opt/${PN}/Browser/libmozavutil.so
    opt/${PN}/Browser/libxul.so
    opt/${PN}/Browser/TorBrowser/Tor/tor
    opt/${PN}/Browser/TorBrowser/Tor/libevent-2.1.so.7
    opt/${PN}/Browser/TorBrowser/Tor/libssl.so.3
    opt/${PN}/Browser/TorBrowser/Tor/libcrypto.so.3
    opt/${PN}/Browser/TorBrowser/Tor/PluggableTransports/conjure-client
    opt/${PN}/Browser/TorBrowser/Tor/PluggableTransports/snowflake-client
    opt/${PN}/Browser/TorBrowser/Tor/PluggableTransports/lyrebird
"

S="${WORKDIR}"

src_install() {
    local MOZILLA_FIVE_HOME="/opt/${PN}"

    # Install to /opt
    dodir /opt
    mv "${WORKDIR}/tor-browser" "${ED}${MOZILLA_FIVE_HOME}" || die

    # Create wrapper
    newbin - "${PN}" <<-EOF
#!/bin/sh
unset SESSION_MANAGER

export MOZ_ENABLE_WAYLAND=$(usex wayland 1 0)
export TOR_HIDE_UPDATE_CHECK_UI=1
export TOR_NO_DISPLAY_NETWORK_SETTINGS=1
export TOR_SKIP_LAUNCH=1
export TOR_SKIP_CONTROLPORTTEST=1

exec "${MOZILLA_FIVE_HOME}/Browser/start-tor-browser" --name="Tor Browser" --class="Tor Browser" "\$@"
EOF

    # Set permissions
    fperms 755 "${MOZILLA_FIVE_HOME}/Browser/"{firefox.real,TorBrowser/Tor/tor,start-tor-browser,execdesktop}
    fperms 755 "${MOZILLA_FIVE_HOME}/Browser/TorBrowser/Tor/PluggableTransports/"{conjure-client,snowflake-client,lyrebird}

    # Install icons
    local size icon_path="${ED}${MOZILLA_FIVE_HOME}/Browser/browser/chrome/icons/default"
    for size in 16 32 48 64 128; do
        newicon -s ${size} "${icon_path}/default${size}.png" "${PN}.png"
    done

    # Create symlink
    dosym "${PN}" /usr/bin/torbrowser

    # Desktop entry
    make_desktop_entry "${PN}" "Tor Browser" "${PN}" "Network;WebBrowser" "StartupWMClass=Tor Browser"
}

pkg_postinst() {
    xdg_desktop_database_update
    xdg_icon_cache_update
    elog "Tor Browser has been installed in ${MOZILLA_FIVE_HOME}"
}

pkg_postrm() {
    xdg_desktop_database_update
    xdg_icon_cache_update
}