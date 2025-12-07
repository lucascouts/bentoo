# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="CLI tools for Bentoo Linux distribution maintainers and developers"
HOMEPAGE="https://github.com/obentoo/bentoo-tools"
SRC_URI="https://github.com/obentoo/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="network-sandbox"

RDEPEND="dev-vcs/git"

src_unpack() {
	default
	cd "${S}" || die
	ego mod download
}

src_compile() {
	ego build -o ${PN} ./cmd/bentoo
}

src_install() {
	dobin ${PN}
	einstalldocs
}

pkg_postinst() {
	elog "bentoo-tools has been installed."
	elog ""
	elog "Available commands:"
	elog "  bentoo overlay status  - View pending changes"
	elog "  bentoo overlay add     - Stage changes"
	elog "  bentoo overlay commit  - Commit with auto-generated message"
	elog "  bentoo overlay push    - Push to remote"
	elog ""
	elog "Configuration: ~/.config/bentoo/config.yaml"
	elog ""
	elog "Example config.yaml:"
	elog "  overlay:"
	elog "    path: /var/db/repos/bentoo"
	elog "  git:"
	elog "    user: your_username"
	elog "    email: your_email@example.com"
}
