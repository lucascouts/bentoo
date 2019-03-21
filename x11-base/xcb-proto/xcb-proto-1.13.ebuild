# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )
XORG_MULTILIB=yes
XORG_STATIC=no

inherit python-r1 xorg-2

DESCRIPTION="X C-language Bindings protocol headers"
HOMEPAGE="https://xcb.freedesktop.org/"
EGIT_REPO_URI="https://anongit.freedesktop.org/git/xcb/proto.git"
[[ ${PV} != 9999* ]] && \
	SRC_URI="https://xcb.freedesktop.org/dist/${P}.tar.bz2"

KEYWORDS="*"
IUSE=""

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	!<x11-proto/${P}-r1000
	dev-libs/libxml2"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_configure() {
	python_setup
	xorg-2_src_configure
}

multilib_src_configure() {
	autotools-utils_src_configure

	if multilib_is_native_abi; then
		python_foreach_impl autotools-utils_src_configure
	fi
}

multilib_src_compile() {
	default

	if multilib_is_native_abi; then
		python_foreach_impl autotools-utils_src_compile -C xcbgen \
			top_builddir="${BUILD_DIR}"
	fi
}

src_install() {
	xorg-2_src_install

	# pkg-config file hardcodes python sitedir, bug 486512
	sed -i -e '/pythondir/s:=.*$:=/dev/null:' \
		"${ED}"/usr/lib*/pkgconfig/xcb-proto.pc || die
}

multilib_src_install() {
	default

	if multilib_is_native_abi; then
		python_foreach_impl autotools-utils_src_install -C xcbgen \
			top_builddir="${BUILD_DIR}"
	fi
}
