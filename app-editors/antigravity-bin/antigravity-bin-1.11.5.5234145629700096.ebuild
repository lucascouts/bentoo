# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 desktop xdg

DESCRIPTION="Antigravity - Modern code editor built on Electron (binary release)"
HOMEPAGE="https://antigravity.app"

# Dynamic version calculation
MY_PV="${PV%.*}-${PV##*.}"
SRC_URI="
	amd64? ( https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${MY_PV}/linux-x64/Antigravity.tar.gz -> ${P}-amd64.tar.gz )
"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip test"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libpng:0
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
"

S="${WORKDIR}"

QA_PREBUILT="*"

src_install() {
	local destdir="/opt/antigravity"

	# Install application files
	insinto "${destdir}"
	doins -r .

	# Set executable permissions
	fperms 755 "${destdir}/antigravity"
	fperms 755 "${destdir}/bin/antigravity" 
	fperms 755 "${destdir}/chrome_crashpad_handler"
	fperms 4755 "${destdir}/chrome-sandbox"

	# Create symlink
	dosym "${destdir}/antigravity" /usr/bin/antigravity

	# Install completions if they exist
	if [[ -f resources/completions/bash/antigravity ]]; then
		newbashcomp resources/completions/bash/antigravity antigravity
	fi
	
	if [[ -f resources/completions/zsh/_antigravity ]]; then
		insinto /usr/share/zsh/site-functions
		newins resources/completions/zsh/_antigravity _antigravity
	fi

	# Install icon
	if [[ -f resources/app/resources/linux/code.png ]]; then
		newicon resources/app/resources/linux/code.png antigravity.png
	fi

	# Create desktop entry
	make_desktop_entry \
		"antigravity %F" \
		"Antigravity" \
		"antigravity" \
		"Development;IDE;TextEditor;" \
		"MimeType=text/plain;inode/directory;\nStartupWMClass=antigravity"

	# Install documentation
	if [[ -f resources/app/LICENSE.txt ]]; then
		dodoc resources/app/LICENSE.txt
	fi
	if [[ -f resources/app/ThirdPartyNotices.txt ]]; then
		dodoc resources/app/ThirdPartyNotices.txt
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	
	elog "Antigravity has been installed to /opt/antigravity"
	elog "Configuration will be stored in ~/.config/Antigravity"
}

pkg_postrm() {
	xdg_pkg_postrm
}