# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/zeux/volk.git"
	inherit git-r3
else
	EGIT_COMMIT="e3e9ea83916b7dfecb10cbc33814f1dcce80ed32"
	SRC_URI="https://github.com/zeux/volk/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc ~ppc64 ~riscv"
	S="${WORKDIR}"/${PN}-${EGIT_COMMIT}
fi

DESCRIPTION="Meta loader for Vulkan API"
HOMEPAGE="https://github.com/zeux/volk"

LICENSE="MIT"
SLOT="0"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="media-libs/vulkan-loader:=[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	dev-util/vulkan-headers
"

multilib_src_configure() {
	local mycmakeargs=(
		-DVOLK_INSTALL=on
	)
	cmake_src_configure
}
