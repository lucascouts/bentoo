# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 desktop multilib-build pax-utils systemd unpacker xdg

DESCRIPTION="Fortinet VPN client"
HOMEPAGE="https://www.fortinet.com/products/endpoint-security/forticlient"
SRC_URI="https://repo.fortinet.com/repo/$(ver_cut 1-2)/debian/pool/non-free/f/${PN}/${PN}_${PV}_amd64.deb"

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

QA_PREBUILT="opt/forticlient/fortitraylauncher
	opt/forticlient/update
	opt/forticlient/fctsched
	opt/forticlient/fortivpn
	opt/forticlient/scanunit
	opt/forticlient/fazlogupload
	opt/forticlient/vulscan
	opt/forticlient/update_tls
	opt/forticlient/fortitray
	opt/forticlient/confighandler
	opt/forticlient/vpn
	opt/forticlient/epctrl
	opt/forticlient/libav.so
	opt/forticlient/fmon
	opt/forticlient/fchelper"
QA_FLAGS_IGNORED="opt/forticlient/forticlient-cli
	opt/forticlient/libvcm.so
	opt/forticlient/ztproxy
	opt/forticlient/gui/FortiClient-linux-x64/libEGL.so
	opt/forticlient/gui/FortiClient-linux-x64/libvulkan.so
	opt/forticlient/gui/FortiClient-linux-x64/libvk_swiftshader.so
	opt/forticlient/gui/FortiClient-linux-x64/chrome-sandbox
	opt/forticlient/gui/FortiClient-linux-x64/FortiClient
	opt/forticlient/gui/FortiClient-linux-x64/libGLESv2.so
	opt/forticlient/gui/FortiClient-linux-x64/libffmpeg.so
	opt/forticlient/gui/FortiClient-linux-x64/FortiClient
	opt/forticlient/gui/FortiClient-linux-x64/libffmpeg.so
	opt/forticlient/gui/FortiClient-linux-x64/swiftshader/libEGL.so
	opt/forticlient/gui/FortiClient-linux-x64/swiftshader/libGLESv2.so"

S="${WORKDIR}"

src_install() {
	dobashcomp etc/bash_completion.d/{fct_cli_autocomplete,forticlient-completion}

	keepdir /var/lib/forticlient /etc/forticlient /opt/forticlient/{XMLs,quarantine} \
		/var/log/forticlient/{fmon,vcm}_log

	for size in 16x16 22x22 24x24 32x32 48x48 64x64 128x128 256x256 ; do
		newicon -s "${size}" usr/share/icons/hicolor/"${size}"/apps/forticlient.png \
			forticlient.png
	done

	dosym ../icons/hicolor/256x256/apps/forticlient.png \
		/usr/share/pixmaps/forticlient.png

	insinto /usr/share/polkit-1/actions
	doins usr/share/polkit-1/actions/org.fortinet.forti{client,tray}.policy

	domenu usr/share/applications/forticlient{,-register}.desktop \
		opt/forticlient/Fortitray.desktop

	exeinto /opt/forticlient
	doexe opt/forticlient/confighandler \
		opt/forticlient/epctrl \
		opt/forticlient/fazlogupload \
		opt/forticlient/fchelper \
		opt/forticlient/fctsched \
		opt/forticlient/fmon \
		opt/forticlient/forticlient-cli \
		opt/forticlient/fortitray \
		opt/forticlient/fortitraylauncher \
		opt/forticlient/fortivpn \
		opt/forticlient/vpn \
		opt/forticlient/libav.so \
		opt/forticlient/libvcm.so \
		opt/forticlient/scanunit \
		opt/forticlient/update \
		opt/forticlient/update_tls \
		opt/forticlient/vulscan \
		opt/forticlient/ztproxy

	insinto /opt/forticlient
	doins opt/forticlient/.config.db.init

	insinto /opt/forticlient/images
	doins -r opt/forticlient/images/.

	insinto /opt/forticlient/gui/FortiClient-linux-x64
	doins -r opt/forticlient/gui/FortiClient-linux-x64/.

	insinto /opt/forticlient/vcm_sig
	doins opt/forticlient/vcm_sig/vulns.dat

	insinto /opt/forticlient/vir_sig
	doins opt/forticlient/vir_sig/vir_high

	fperms +x /opt/forticlient/gui/FortiClient-linux-x64/swiftshader/libEGL.so \
		/opt/forticlient/gui/FortiClient-linux-x64/swiftshader/libGLESv2.so \
		/opt/forticlient/gui/FortiClient-linux-x64/FortiClient \
		/opt/forticlient/gui/FortiClient-linux-x64/chrome-sandbox \
		/opt/forticlient/gui/FortiClient-linux-x64/libEGL.so \
		/opt/forticlient/gui/FortiClient-linux-x64/libGLESv2.so \
		/opt/forticlient/gui/FortiClient-linux-x64/libffmpeg.so \
		/opt/forticlient/gui/FortiClient-linux-x64/libvk_swiftshader.so \
		/opt/forticlient/gui/FortiClient-linux-x64/libvulkan.so

	dodir /opt/bin
	dosym ../forticlient/gui/FortiClient-linux-x64/FortiClient opt/bin/FortiClient
	dosym ../forticlient/fortivpn opt/bin/fortivpn
	dosym ../../opt/forticlient/forticlient-cli  /usr/bin/forticlient

	systemd_dounit lib/systemd/system/forticlient.service

	pax-mark -m "${ED}"/opt/forticlient/gui/FortiClient-linux-x64/FortiClient
}
