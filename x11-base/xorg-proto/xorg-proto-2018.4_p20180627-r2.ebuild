# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit meson multilib-minimal

DESCRIPTION="X.Org combined protocol headers"
HOMEPAGE="https://cgit.freedesktop.org/xorg/proto/xorgproto/"
if [ "${PV}" = "${PV%_p*}" ] ; then
	SRC_URI="https://xorg.freedesktop.org/archive/individual/proto/xorgproto-${PV}.tar.gz"
	KEYWORDS="*"
else
	inherit git-r3
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/xorg/proto/xorgproto"
	PVCD="${PV#*_p}"
	if [ ${PVCD} -ge 19700101 ] && [ ${PVCD} -lt 30000000 ] ; then # Not y3k compliant, sorry!
		PVCDY="${PVCD%????}"
		PVCDMD="${PVCD#????}"
		PVCDM="${PVCDMD%??}"
		PVCDD="${PVCDMD#??}"
		EGIT_COMMIT_DATE="${PVCDY}-${PVCDM}-${PVCDD}"
		KEYWORDS="*"
	else
		# Keyword mask live builds without datestamp.
		KEYWORDS=""
	fi
fi

LICENSE="GPL-2 MIT"
SLOT="0"
IUSE="legacy"


multilib_src_configure() {
	local emesonargs=(
		--datadir="${EPREFIX}/usr/share"
		-Dlegacy=$(usex legacy true false)
	)
	meson_src_configure
}

multilib_src_compile() {
	meson_src_compile 
}

multilib_src_install() {
	meson_src_install
}

multilib_src_install_all() {
	DOCS=(
		AUTHORS
		PM_spec
		README
		$(set +f; echo COPYING-*)
		$(set +f; echo *.txt | grep -v meson.txt)
	)
	einstalldocs
}

LEGACY_BLOCKS="
	!<x11-proto/evieproto-1.1.1-r1001
	!<x11-proto/fontcacheproto-0.1.3-r1001
	!<x11-proto/lg3dproto-5.0-r1001
	!<x11-proto/printproto-1.0.5-r1001
	!<x11-proto/xcalibrateproto-0.1.0-r1001
	!<x11-proto/xf86rushproto-1.2.2-r1001"
RDEPEND="legacy? ( ${LEGACY_BLOCKS} )
	!<x11-proto/applewmproto-1.4.2-r1001
	!<x11-proto/bigreqsproto-1.1.2-r1001
	!<x11-proto/compositeproto-0.4.2-r1001
	!<x11-proto/damageproto-1.2.1-r1001
	!<x11-proto/dmxproto-2.3.1-r1001
	!<x11-proto/dri2proto-2.8-r1001
	!<x11-proto/dri3proto-1.2-r1001
	!<x11-proto/fixesproto-5.0-r1001
	!<x11-proto/fontsproto-2.1.3-r1001
	!<x11-proto/glproto-1.4.17-r1001
	!<x11-proto/inputproto-2.3.2-r1001
	!<x11-proto/kbproto-1.0.7-r1001
	!<x11-proto/presentproto-1.2-r1001
	!<x11-proto/randrproto-1.6.0-r1001
	!<x11-proto/recordproto-1.14.2-r1001
	!<x11-proto/renderproto-0.11.1-r1001
	!<x11-proto/resourceproto-1.2.0-r1001
	!<x11-proto/scrnsaverproto-1.2.2-r1001
	!<x11-proto/trapproto-3.4.3-r1001
	!<x11-proto/videoproto-2.3.3-r1001
	!<x11-proto/windowswmproto-1.0.4-r1001
	!<x11-proto/xcmiscproto-1.2.2-r1001
	!<x11-proto/xextproto-7.3.0-r1001
	!<x11-proto/xf86bigfontproto-1.2.0-r1001
	!<x11-proto/xf86dgaproto-2.1-r1001
	!<x11-proto/xf86driproto-2.1.1-r1001
	!<x11-proto/xf86miscproto-0.9.3-r1001
	!<x11-proto/xf86vidmodeproto-2.3.1-r1001
	!<x11-proto/xineramaproto-1.2.1-r1001
	!<x11-proto/xproto-7.0.32-r1001
	!<x11-proto/xproxymngproto-1.0.3-r1001"
LEGACY_DEPS="
	=x11-proto/evieproto-1.1.1-r1001
	=x11-proto/fontcacheproto-0.1.3-r1001
	=x11-proto/lg3dproto-5.0-r1001
	=x11-proto/printproto-1.0.5-r1001
	=x11-proto/xcalibrateproto-0.1.0-r1001
	=x11-proto/xf86rushproto-1.2.2-r1001"
PDEPEND="legacy? ( ${LEGACY_DEPS} )
	=x11-proto/applewmproto-1.4.2-r1001
	=x11-proto/bigreqsproto-1.1.2-r1001
	=x11-proto/compositeproto-0.4.2-r1001
	=x11-proto/damageproto-1.2.1-r1001
	=x11-proto/dmxproto-2.3.1-r1001
	=x11-proto/dri2proto-2.8-r1001
	=x11-proto/dri3proto-1.2-r1001
	=x11-proto/fixesproto-5.0-r1001
	=x11-proto/fontsproto-2.1.3-r1001
	=x11-proto/glproto-1.4.17-r1001
	=x11-proto/inputproto-2.3.2-r1001
	=x11-proto/kbproto-1.0.7-r1001
	=x11-proto/presentproto-1.2-r1001
	=x11-proto/randrproto-1.6.0-r1001
	=x11-proto/recordproto-1.14.2-r1001
	=x11-proto/renderproto-0.11.1-r1001
	=x11-proto/resourceproto-1.2.0-r1001
	=x11-proto/scrnsaverproto-1.2.2-r1001
	=x11-proto/trapproto-3.4.3-r1001
	=x11-proto/videoproto-2.3.3-r1001
	=x11-proto/windowswmproto-1.0.4-r1001
	=x11-proto/xcmiscproto-1.2.2-r1001
	=x11-proto/xextproto-7.3.0-r1001
	=x11-proto/xf86bigfontproto-1.2.0-r1001
	=x11-proto/xf86dgaproto-2.1-r1001
	=x11-proto/xf86driproto-2.1.1-r1001
	=x11-proto/xf86miscproto-0.9.3-r1001
	=x11-proto/xf86vidmodeproto-2.3.1-r1001
	=x11-proto/xineramaproto-1.2.1-r1001
	=x11-proto/xproto-7.0.32-r1001
	=x11-proto/xproxymngproto-1.0.3-r1001"
