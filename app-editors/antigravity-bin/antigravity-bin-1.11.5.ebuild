# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PN="${PN%-bin}"
MY_PV="${PV}-5234145629700096"

DESCRIPTION="Antigravity - Modern code editor built on Electron"
HOMEPAGE="https://antigravity.app"
SRC_URI="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/${MY_PN}/stable/${MY_PV}/linux-x64/Antigravity.tar.gz -> ${P}.tar.gz"

# Replace with correct license when known
LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""

# Minimal dependencies for running Electron binaries
# Based on: https://wiki.gentoo.org/wiki/Electron
RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
"

S="${WORKDIR}"

# All binaries are pre-built
QA_PREBUILT="*"

src_install() {
	# Install to /opt following FHS for large binary software
	insinto /opt/${MY_PN}
	doins -r .

	# Make necessary binaries executable
	fperms 755 /opt/${MY_PN}/${MY_PN}
	fperms 4755 /opt/${MY_PN}/chrome-sandbox
	fperms 755 /opt/${MY_PN}/chrome_crashpad_handler

	# Create symlink in /usr/bin
	dosym ../../opt/${MY_PN}/${MY_PN} /usr/bin/${MY_PN}

	# Install icon if exists
	if [[ -f resources/app/resources/linux/code.png ]]; then
		newicon resources/app/resources/linux/code.png ${MY_PN}.png
	fi

	# Create and install desktop entry
	make_desktop_entry \
		"${MY_PN}" \
		"Antigravity" \
		"${MY_PN}" \
		"Development;IDE;TextEditor;" \
		"MimeType=text/plain;inode/directory;\nStartupWMClass=Antigravity"
}

pkg_postinst() {
	xdg_pkg_postinst
	
	elog "Antigravity has been installed to /opt/${MY_PN}"
	elog "Configuration will be stored in ~/.config/Antigravity"
}

pkg_postrm() {
	xdg_pkg_postrm
}