# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A QR code shared library used by OpenCV."
HOMEPAGE="https://github.com/dlbeer/quirc"

LICENSE="AS-IS"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

GITHUB_REPO="$PN"
GITHUB_USER="dlbeer"
GITHUB_TAG="v${PV}"
SRC_URI="https://www.github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/${GITHUB_TAG} -> ${PN}-${GITHUB_TAG}.tar.gz"

PATCHES=(
	"${FILESDIR}/quirc-1.0-link.patch"
)

src_unpack() {
	unpack ${A}
	mv "${WORKDIR}/${GITHUB_USER}-${PN}"-??????? "${S}" || die
}

src_compile() {
	export CFLAGS="-fPIC $CFLAGS"
	emake libquirc.so || die
}

src_install() {
	dolib.so ${S}/libquirc.so.1.0
	dosym libquirc.so.1.0 /usr/$(get_libdir)/libquirc.so.1
	dosym libquirc.so.1 /usr/$(get_libdir)/libquirc.so
	insinto /usr/include
	doins ${S}/lib/quirc.h
}
