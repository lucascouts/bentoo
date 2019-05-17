# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/KhronosGroup/OpenCL-Headers.git"
	inherit git-r3
else
	case "${PV}" in
		20190412) EGIT_COMMIT="745c724b4ac623b1c42044454cb867e537d3917e"
	esac
	
	KEYWORDS="~amd64"
	if [ -n "${EGIT_COMMIT}" ] ; then
		SRC_URI="https://github.com/KhronosGroup/OpenCL-Headers/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
		S="${WORKDIR}/OpenCL-Headers-${EGIT_COMMIT}"
	else
		SRC_URI="https://github.com/KhronosGroup/OpenCL-Headers/archive/v${PV}.tar.gz -> ${P}.tar.gz"
		S="${WORKDIR}/OpenCL-Headers-${PV}"
	fi
fi

DESCRIPTION="Unified OpenCL API Headers"
HOMEPAGE="https://github.com/KhronosGroup/OpenCL-Headers"

LICENSE="Apache-2.0"
SLOT="0"

# Old packaging will cause file collisions
RDEPEND="!<app-eselect/eselect-opencl-1.2.0"

src_install() {
	insinto /usr/include
	doins -r CL
}
