# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Symlinks and syncs browser profile dirs to RAM"
HOMEPAGE="https://wiki.archlinux.org/index.php/Profile-sync-daemon"
SRC_URI="https://github.com/graysky2/profile-sync-daemon/archive/v${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="~amd64 ~x86"

LICENSE="MIT"
SLOT="0"
IUSE=""

RDEPEND="
	app-shells/bash
	net-misc/rsync[xattr]
	sys-auth/elogind"

PATCHES=(
	"${FILESDIR}/openrc-path.patch"
	"${FILESDIR}/bad-substitution-fix.patch"
)

src_install() {
	emake DESTDIR="${D}" COMPRESS_MAN=0 install
}
