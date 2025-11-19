# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit bash-completion-r1 chromium-2 desktop optfeature pax-utils xdg

DESCRIPTION="Google's Antigravity IDE - Next-generation code editor"
HOMEPAGE="https://antigravity.google/"

MY_PV="${PV%.*}-${PV##*.}"
SRC_URI="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${MY_PV}/linux-x64/Antigravity.tar.gz -> ${PN}-${MY_PV}.tar.gz"

LICENSE="MIT Google-TOS"
SLOT="0"
KEYWORDS="~amd64"
IUSE="libsecret wayland"
RESTRICT="bindist mirror strip"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret[crypt]
	app-misc/shared-mime-info
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libpng
	media-libs/mesa
	net-print/cups
	sys-apps/util-linux
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
	libsecret? ( app-crypt/libsecret )
	wayland? ( dev-libs/wayland )
"

QA_PREBUILT="
	opt/antigravity/antigravity
	opt/antigravity/chrome-sandbox
	opt/antigravity/chrome_crashpad_handler
	opt/antigravity/libEGL.so
	opt/antigravity/libGLESv2.so
	opt/antigravity/libffmpeg.so
	opt/antigravity/libvk_swiftshader.so
	opt/antigravity/libvulkan.so.1
"

S="${WORKDIR}/Antigravity"

src_prepare() {
	default

	# Remove unused language files
	pushd locales > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die
}

src_install() {
	local appdir="/opt/${PN}"

	# Install main application files
	insinto "${appdir}"
	doins chrome_100_percent.pak
	doins chrome_200_percent.pak
	doins icudtl.dat
	doins LICENSES.chromium.html
	doins resources.pak
	doins snapshot_blob.bin
	doins v8_context_snapshot.bin
	doins vk_swiftshader_icd.json

	# Install executables
	exeinto "${appdir}"
	doexe antigravity
	doexe chrome-sandbox
	doexe chrome_crashpad_handler
	
	# Shared libraries
	doexe libEGL.so
	doexe libGLESv2.so
	doexe libffmpeg.so
	doexe libvk_swiftshader.so
	doexe libvulkan.so.1

	# Resources, locales and bin directory
	insinto "${appdir}"
	doins -r resources
	doins -r locales
	
	if [[ -d bin ]]; then
		insinto "${appdir}/bin"
		doins -r bin/.
		fperms 0755 "${appdir}/bin/antigravity"
	fi

	# Permissions
	fperms 0755 "${appdir}"/antigravity
	fperms 0755 "${appdir}"/chrome_crashpad_handler
	fperms 4755 "${appdir}"/chrome-sandbox

	# Symlink to /usr/bin
	dosym "${appdir}/antigravity" /usr/bin/antigravity

	# Shell completions
	if [[ -f resources/completions/bash/antigravity ]]; then
		newbashcomp resources/completions/bash/antigravity antigravity
	fi
	if [[ -f resources/completions/zsh/_antigravity ]]; then
		insinto /usr/share/zsh/site-functions
		newins resources/completions/zsh/_antigravity _antigravity
	fi

	# Desktop file
	make_desktop_entry \
		"antigravity" \
		"Antigravity" \
		"antigravity" \
		"Development;IDE;TextEditor" \
		"GenericName=Text Editor\nComment=Code Editing. Redefined.\nStartupNotify=true\nStartupWMClass=antigravity"

	# Icon
	newicon resources/app/resources/linux/code.png antigravity.png

	# Documentation
	if [[ -f resources/app/LICENSE.txt ]]; then
		dodoc resources/app/LICENSE.txt
	fi
	if [[ -f resources/app/ThirdPartyNotices.txt ]]; then
		dodoc resources/app/ThirdPartyNotices.txt
	fi

	# PaX marking for JIT
	pax-mark -m "${ED}${appdir}"/antigravity
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Antigravity has been installed to ${EROOT}/opt/${PN}"
	elog ""
	elog "You may install additional extensions via the Extensions Marketplace."
	elog ""
	optfeature "GPU acceleration support" media-libs/mesa
	optfeature "Password storage" app-crypt/libsecret
	optfeature "Wayland support" dev-libs/wayland
	
	if ! use libsecret; then
		ewarn "Password storage requires libsecret USE flag enabled"
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
}