# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CMAKE_IN_SOURCE_BUILD="1"

inherit cmake edo

DESCRIPTION="Library for freeswitch yuv graphics manipulation"
HOMEPAGE="https://chromium.googlesource.com/libyuv/libyuv"
SRC_URI="https://drive.google.com/uc?export=download&id=1qIqKQw7poIXJHYGLb0ME1ZUsnsGzd6Xj -> ${P}.tar.gz"
S="${WORKDIR}/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="media-libs/libjpeg-turbo:0="
BDEPEND="test? ( dev-cpp/gtest )"

src_prepare() {
	# cmake_minimum_required() should be called prior to
	# this top-level project(), do not install static, fix libdir,
	# install yuvconstants
	sed -i  -e '/CMAKE_MINIMUM_REQUIRED( VERSION 2.8.12 )/d' \
		-e '/PROJECT (/iCMAKE_MINIMUM_REQUIRED( VERSION 2.8.12 )' \
		-e "/DESTINATION/s| lib| $(get_libdir)|" \
		-e "/TARGETS \${ly_lib_static}/d" \
		-e "/INSTALL ( PROGRAMS/aINSTALL ( PROGRAMS \${CMAKE_BINARY_DIR}/yuvconstants                  DESTINATION bin )" \
		CMakeLists.txt || die "sed failed for CMakeLists.txt"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DUNIT_TEST="$(usex test)"
	)

	cmake_src_configure
}

src_test() {
	edo ./libyuv_unittest
}

src_install() {
	cmake_src_install

	insinto /usr/"$(get_libdir)"/pkgconfig
	newins - libyuv.pc < <(sed -e "/Version/s|%%VERSION%%|${PV}|" \
				-e "/libdir/s|%%LIBDIR%%|"$(get_libdir)"|" \
				"${FILESDIR}"/libyuv.pc \
				|| die "sed failed for libyuv.pc.in" )
	insinto /usr/"$(get_libdir)"/cmake/libyuv
	doins "${FILESDIR}"/libyuv-config.cmake
}