# Distributed under the terms of the GNU General Public License v2
EAPI=6

inherit multilib-minimal

DESCRIPTION="x11-proto/xcb-proto package stub (provided by xcb-proto)."

KEYWORDS="*"

SLOT="0"

RDEPEND="=x11-base/xcb-proto-1.13[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

multilib_src_configure() { return 0; }
src_configure() { return 0; }
multilib_src_compile() { return 0; }
src_compile() { return 0; }
multilib_src_install() { return 0; }
src_install() { return 0; }

