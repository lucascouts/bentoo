# Copyright 2020-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop pax-utils xdg wrapper

MY_PN="${PN/-bin/}"

DESCRIPTION="Supercharge your API workflow"
HOMEPAGE="https://www.postman.com/"
SRC_URI="https://dl.pstmn.io/download/latest/linux_64 -> postman-bin-${PV}.tar.gz"

S="${WORKDIR}/${MY_PN^}/app"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="pax-kernel"
RESTRICT="bindist mirror strip"

RDEPEND="
	x11-libs/gtk+
"

QA_FLAGS_IGNORED="CFLAGS LDFLAGS"

src_prepare() {
	mv _Postman Postman
	default
}

src_install() {
	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/Postman
	fperms 755 "${dir}"/postman

	make_wrapper "${PN}" "${dir}/Postman"
	newicon "resources/app/assets/icon.png" "${PN}.png"
	make_desktop_entry "${PN}" "Postman" "${PN}" "Development;IDE;"

	use pax-kernel && pax-mark m "${ED}/opt/${MY_PN}/${MY_PN^}"
}
