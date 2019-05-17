# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )
inherit cmake-utils python-any-r1


if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/KhronosGroup/OpenCL-CLHPP.git"
	inherit git-r3
else
	case "${PV}" in
		20190207) EGIT_COMMIT="acd6972bc65845aa28bd9f670dec84cbf8b760f3"
	esac
	
	KEYWORDS="~amd64"
	if [ -n "${EGIT_COMMIT}" ] ; then
		SRC_URI="https://github.com/KhronosGroup/OpenCL-CLHPP/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
		S="${WORKDIR}/OpenCL-CLHPP-${EGIT_COMMIT}"
	else
		SRC_URI="https://github.com/KhronosGroup/OpenCL-CLHPP/archive/v${PV}.tar.gz -> ${P}.tar.gz"
		S="${WORKDIR}/OpenCL-CLHPP-${PV}"
	fi
fi

DESCRIPTION="OpenCL Host API C++ bindings."
HOMEPAGE="https://github.com/KhronosGroup/OpenCL-CLHPP"

LICENSE="Apache-2.0"
SLOT="0"

IUSE="doc"

# Old packaging will cause file collisions
RDEPEND="
	>=dev-util/opencl-headers-${PV}
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
"

RDEPEND="${RDEPEND}
	!<app-eselect/eselect-opencl-1.2.0
"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_DOCS=$(usex doc OFF ON)
		-DBUILD_EXAMPLES=OFF
		-DBUILD_TESTS=OFF
		-DOPENCL_INCLUDE_DIR=${EPREFIX}/usr/include/CL
	)

	cmake-utils_src_configure
}
