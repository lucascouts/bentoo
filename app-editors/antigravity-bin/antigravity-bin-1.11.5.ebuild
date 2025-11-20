# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop pax-utils xdg

MY_PN="${PN%-bin}"
MY_PV="${PV}-5234145629700096"

DESCRIPTION="Antigravity - Modern code editor built on Electron framework"
HOMEPAGE="https://antigravity.app"
SRC_URI="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/${MY_PN}/stable/${MY_PV}/linux-x64/Antigravity.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="system-ffmpeg system-electron wayland +seccomp"

# Electron runtime dependencies
RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[wayland?]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libxshmfence
	x11-libs/pango
	system-electron? (
		dev-util/electron
	)
	system-ffmpeg? (
		media-video/ffmpeg:=
	)
"

BDEPEND=""

S="${WORKDIR}/Antigravity"

QA_PREBUILT="
	opt/${MY_PN}/*.so
	opt/${MY_PN}/*.so.*
	opt/${MY_PN}/${MY_PN}
	opt/${MY_PN}/chrome-sandbox
	opt/${MY_PN}/chrome_crashpad_handler
	opt/${MY_PN}/libffmpeg.so
	opt/${MY_PN}/libEGL.so
	opt/${MY_PN}/libGLESv2.so
	opt/${MY_PN}/libvk_swiftshader.so
	opt/${MY_PN}/libvulkan.so.1
	opt/${MY_PN}/resources/app/node_modules*
"

pkg_pretend() {
	# Check for sufficient disk space
	CHECKREQS_DISK_BUILD="500M"
	CHECKREQS_DISK_USR="400M"
}

src_prepare() {
	default

	# Remove bundled libraries if using system versions
	if use system-ffmpeg; then
		rm -f libffmpeg.so || die "Failed to remove bundled ffmpeg"
	fi

	# Fix desktop file if it exists
	if [[ -f "${S}/resources/app/resources/linux/${MY_PN}.desktop" ]]; then
		sed -i \
			-e "s|Exec=.*|Exec=${EPREFIX}/opt/${MY_PN}/${MY_PN} %U|" \
			-e "s|Icon=.*|Icon=${MY_PN}|" \
			"${S}/resources/app/resources/linux/${MY_PN}.desktop" || die
	fi
}

src_install() {
	local destdir="/opt/${MY_PN}"

	# Install application files
	insinto "${destdir}"
	doins -r .

	# Set executable permissions
	fperms 755 "${destdir}/${MY_PN}"
	fperms 755 "${destdir}/chrome-sandbox"
	fperms 755 "${destdir}/chrome_crashpad_handler"
	fperms 755 "${destdir}/bin/${MY_PN}"
	
	# Chrome sandbox needs special permissions
	fperms 4755 "${destdir}/chrome-sandbox"

	# Install desktop entry
	local desktop_file="${S}/resources/app/resources/linux/${MY_PN}.desktop"
	if [[ -f "${desktop_file}" ]]; then
		domenu "${desktop_file}"
	else
		# Create a desktop entry if one doesn't exist
		make_desktop_entry \
			"${EPREFIX}/opt/${MY_PN}/${MY_PN}" \
			"Antigravity" \
			"${MY_PN}" \
			"Development;IDE;TextEditor;" \
			"StartupWMClass=Antigravity"
	fi

	# Install icons
	local icon="${S}/resources/app/resources/linux/code.png"
	if [[ -f "${icon}" ]]; then
		newicon "${icon}" "${MY_PN}.png"
	fi

	# Install additional icon sizes if available
	for size in 16 24 32 48 64 128 256 512; do
		if [[ -f "${S}/resources/app/out/vs/platform/antigravityCustomAppIcon/browser/media/${MY_PN}/${MY_PN}_${size}.png" ]]; then
			newicon -s ${size} \
				"${S}/resources/app/out/vs/platform/antigravityCustomAppIcon/browser/media/${MY_PN}/${MY_PN}_${size}.png" \
				"${MY_PN}.png"
		fi
	done

	# Create wrapper script
	make_wrapper "${MY_PN}" \
		"${EPREFIX}/opt/${MY_PN}/${MY_PN}" \
		"${EPREFIX}/opt/${MY_PN}" \
		"${EPREFIX}/opt/${MY_PN}:${EPREFIX}/usr/$(get_libdir)" \
		"/usr/bin"

	# Install bash completion
	if [[ -f "${S}/resources/completions/bash/${MY_PN}" ]]; then
		newbashcomp "${S}/resources/completions/bash/${MY_PN}" "${MY_PN}"
	fi

	# Install zsh completion
	if [[ -f "${S}/resources/completions/zsh/_${MY_PN}" ]]; then
		insinto /usr/share/zsh/site-functions
		newins "${S}/resources/completions/zsh/_${MY_PN}" "_${MY_PN}"
	fi

	# Apply PaX markings for hardened systems
	if use seccomp; then
		pax-mark -m "${ED}${destdir}/${MY_PN}"
		pax-mark -m "${ED}${destdir}/chrome-sandbox"
	else
		pax-mark -pm "${ED}${destdir}/${MY_PN}"
		pax-mark -pm "${ED}${destdir}/chrome-sandbox"
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Antigravity has been installed to /opt/${MY_PN}"
	elog ""
	elog "Configuration files are stored in:"
	elog "  ~/.config/Antigravity"
	elog ""
	if use wayland; then
		elog "For Wayland support, you may need to run with:"
		elog "  ${MY_PN} --enable-features=UseOzonePlatform --ozone-platform=wayland"
		elog ""
		elog "You can set this permanently by adding to ~/.config/electron-flags.conf:"
		elog "  --enable-features=UseOzonePlatform"
		elog "  --ozone-platform=wayland"
	fi
	if ! use system-ffmpeg; then
		ewarn "Using bundled ffmpeg library. Consider enabling system-ffmpeg USE flag"
		ewarn "for better system integration and security updates."
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
}