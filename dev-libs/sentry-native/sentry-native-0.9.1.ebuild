# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Sentry SDK for C, C++ and native applications"
HOMEPAGE="https://sentry.io/ https://github.com/getsentry/sentry-native"
SRC_URI="https://github.com/getsentry/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+breakpad +curl test"
RESTRICT="!test? ( test )"

RDEPEND="
	breakpad? ( dev-util/breakpad )
	curl? (
		net-misc/curl
		sys-libs/zlib
	)
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local mycmakeargs=(
		-DSENTRY_BUILD_EXAMPLES=OFF
		-DSENTRY_BACKEND=$(usex breakpad "breakpad" "inproc")
		-DSENTRY_BUILD_TESTS=$(usex test)
		-DSENTRY_TRANSPORT=$(usex curl "curl" "none")
		-DSENTRY_TRANSPORT_COMPRESSION=$(usex curl)
	)
	# Avoid "not used by the project" warnings when USE=-breakpad
	if use breakpad; then
		mycmakeargs+=( -DSENTRY_BREAKPAD_SYSTEM=ON )
	fi

	cmake_src_configure
}
