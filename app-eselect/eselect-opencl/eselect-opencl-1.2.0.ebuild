# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib

DESCRIPTION="Utility to change the OpenCL implementation being used"
HOMEPAGE="https://www.gentoo.org/"

# eselect module now provided in files/ dir.
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="
	>=app-admin/eselect-1.2.4
"

PDEPEND="
	>=dev-util/opencl-headers-20190412
	>=dev-util/opencl-clhpp-20190207
"
S="${FILESDIR}"

pkg_postinst() {
	local impl="$(eselect opencl show)"
	if [[ -n "${impl}"  && "${impl}" != '(none)' ]] ; then
		eselect opencl set "${impl}"
	fi
}

src_install() {
	insinto /usr/share/eselect/modules
	newins "opencl.eselect-${PV}" "opencl.eselect"
	#doman opencl.eselect.5
}
