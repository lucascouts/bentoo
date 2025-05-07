# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 desktop multilib-build pax-utils systemd unpacker xdg

DESCRIPTION="Fortinet VPN client"
HOMEPAGE="https://www.fortinet.com/products/endpoint-security/forticlient"
SRC_URI="https://distfiles.obentoo.org/${P}.deb"

LICENSE="Fortinet"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="appindicator"
RESTRICT="bindist mirror"

RDEPEND="app-accessibility/at-spi2-atk:2[${MULTILIB_USEDEP}]
	app-crypt/libsecret:0[${MULTILIB_USEDEP}]
	dev-libs/atk:0[${MULTILIB_USEDEP}]
	dev-libs/expat:0[${MULTILIB_USEDEP}]
	dev-libs/glib:2[${MULTILIB_USEDEP}]
	dev-libs/nspr:0[${MULTILIB_USEDEP}]
	dev-libs/nss:0[${MULTILIB_USEDEP}]
	media-libs/alsa-lib:0[${MULTILIB_USEDEP}]
	media-libs/libglvnd:0[${MULTILIB_USEDEP}]
	net-print/cups:0[${MULTILIB_USEDEP}]
	sys-apps/dbus:0[${MULTILIB_USEDEP}]
	sys-apps/util-linux:0[${MULTILIB_USEDEP}]
	sys-libs/zlib:0[${MULTILIB_USEDEP}]
	x11-libs/cairo:0[${MULTILIB_USEDEP}]
	x11-libs/gdk-pixbuf:2[${MULTILIB_USEDEP}]
	x11-libs/gtk+:3[${MULTILIB_USEDEP}]
	x11-libs/libnotify:0[${MULTILIB_USEDEP}]
	x11-libs/libX11:0[${MULTILIB_USEDEP}]
	x11-libs/libxcb:0[${MULTILIB_USEDEP}]
	x11-libs/libXcomposite:0[${MULTILIB_USEDEP}]
	x11-libs/libXcursor:0[${MULTILIB_USEDEP}]
	x11-libs/libXdamage:0[${MULTILIB_USEDEP}]
	x11-libs/libXext:0[${MULTILIB_USEDEP}]
	x11-libs/libXfixes:0[${MULTILIB_USEDEP}]
	x11-libs/libXi:0[${MULTILIB_USEDEP}]
	x11-libs/libXrandr:0[${MULTILIB_USEDEP}]
	x11-libs/libXrender:0[${MULTILIB_USEDEP}]
	x11-libs/libXScrnSaver:0[${MULTILIB_USEDEP}]
	x11-libs/libXtst:0[${MULTILIB_USEDEP}]
	x11-libs/pango:0[${MULTILIB_USEDEP}]
	appindicator? ( dev-libs/libayatana-appindicator )"

# Updated for the new file structure
QA_PREBUILT="opt/forticlient/fortitray
	opt/forticlient/fortitraylauncher
	opt/forticlient/fctsched
	opt/forticlient/fortivpn
	opt/forticlient/fctdns
	opt/forticlient/iked
	opt/forticlient/firewall
	opt/forticlient/vpn
	opt/forticlient/forticlient-cli
	opt/forticlient/confighandler
	opt/forticlient/update
	opt/forticlient/tpm2/bin/tpm2
	opt/forticlient/tpm2/lib/pkcs11.so
	opt/forticlient/legacy.so"

QA_FLAGS_IGNORED="opt/forticlient/gui/FortiClient
	opt/forticlient/gui/chrome-sandbox
	opt/forticlient/gui/chrome_crashpad_handler
	opt/forticlient/gui/libEGL.so
	opt/forticlient/gui/libGLESv2.so
	opt/forticlient/gui/libffmpeg.so
	opt/forticlient/gui/libvk_swiftshader.so
	opt/forticlient/gui/libvulkan.so.1"

S="${WORKDIR}"

src_install() {
	# Install bash completions if present in the package
	if [ -d "etc/bash_completion.d" ]; then
		dobashcomp etc/bash_completion.d/fct_cli_autocomplete etc/bash_completion.d/forticlient-completion
	fi

	# Create necessary directories
	keepdir /var/lib/forticlient /etc/forticlient
	
	# Install icons
	for size in 16x16 22x22 24x24 32x32 48x48 64x64 128x128 256x256 ; do
		newicon -s "${size}" usr/share/icons/hicolor/"${size}"/apps/forticlient.png \
			forticlient.png
	done

	# Create symlink to pixmaps
	dosym ../icons/hicolor/256x256/apps/forticlient.png \
		/usr/share/pixmaps/forticlient.png

	# Install polkit policies
	insinto /usr/share/polkit-1/actions
	doins usr/share/polkit-1/actions/org.fortinet.forti{client,tray}.policy

	# Install desktop files
	domenu usr/share/applications/forticlient{,-register}.desktop \
		opt/forticlient/Fortitray.desktop

	# Install scripts
	exeinto /opt/forticlient
	doexe opt/forticlient/start-fortitray-launcher.sh \
		opt/forticlient/unlock-gui.sh \
		opt/forticlient/stop-forticlient.sh

	# Install binaries
	doexe opt/forticlient/confighandler \
		opt/forticlient/fctdns \
		opt/forticlient/update \
		opt/forticlient/fctsched \
		opt/forticlient/iked \
		opt/forticlient/firewall \
		opt/forticlient/fortitray \
		opt/forticlient/vpn \
		opt/forticlient/forticlient-cli \
		opt/forticlient/fortivpn \
		opt/forticlient/fortitraylauncher \
		opt/forticlient/legacy.so

	# Install .config.db.init
	insinto /opt/forticlient
	doins opt/forticlient/.config.db.init opt/forticlient/.acl opt/forticlient/exe.manifest

	# Install images directory
	insinto /opt/forticlient/images
	doins -r opt/forticlient/images/.

	# Install tpm2 files
	insinto /opt/forticlient/tpm2/etc/tpm2-tss/fapi-profiles
	doins opt/forticlient/tpm2/etc/tpm2-tss/fapi-profiles/*.json
	
	exeinto /opt/forticlient/tpm2/bin
	doexe opt/forticlient/tpm2/bin/tpm2
	
	exeinto /opt/forticlient/tpm2/lib
	doexe opt/forticlient/tpm2/lib/pkcs11.so

	# Install GUI files
	insinto /opt/forticlient/gui
	doins opt/forticlient/gui/chrome_100_percent.pak \
		opt/forticlient/gui/icudtl.dat \
		opt/forticlient/gui/vk_swiftshader_icd.json \
		opt/forticlient/gui/snapshot_blob.bin \
		opt/forticlient/gui/LICENSES.chromium.html \
		opt/forticlient/gui/resources.pak \
		opt/forticlient/gui/v8_context_snapshot.bin \
		opt/forticlient/gui/version \
		opt/forticlient/gui/LICENSE \
		opt/forticlient/gui/chrome_200_percent.pak

	# Install GUI resources
	insinto /opt/forticlient/gui/resources
	doins -r opt/forticlient/gui/resources/.

	# Install GUI locale files
	insinto /opt/forticlient/gui/locales
	doins opt/forticlient/gui/locales/*.pak

	# Install GUI executables with executable permissions
	exeinto /opt/forticlient/gui
	doexe opt/forticlient/gui/chrome-sandbox \
		opt/forticlient/gui/chrome_crashpad_handler \
		opt/forticlient/gui/libvk_swiftshader.so \
		opt/forticlient/gui/libEGL.so \
		opt/forticlient/gui/libvulkan.so.1 \
		opt/forticlient/gui/libGLESv2.so \
		opt/forticlient/gui/libffmpeg.so \
		opt/forticlient/gui/FortiClient

	# Create symlinks for binaries
	dodir /opt/bin
	dosym ../forticlient/gui/FortiClient /opt/bin/FortiClient
	dosym ../forticlient/fortivpn /opt/bin/fortivpn
	dosym ../../opt/forticlient/forticlient-cli /usr/bin/forticlient

	# Install systemd service file
	systemd_dounit lib/systemd/system/forticlient.service

	# Mark FortiClient executable with PaX flags for security
	pax-mark -m "${ED}"/opt/forticlient/gui/FortiClient
}