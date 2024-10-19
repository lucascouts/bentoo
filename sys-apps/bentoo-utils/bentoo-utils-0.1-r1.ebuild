# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1

DESCRIPTION="Utility for managing Git operations for the Bentoo project"
HOMEPAGE="https://github.com/lucascouts/bentoo-utils"
SRC_URI="https://github.com/lucascouts/bentoo-utils/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-lang/python[${PYTHON_USEDEP}]
	dev-vcs/git
"

DEPEND="
	${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

python_install_all() {
	distutils-r1_python_install_all

	# Ensure the .bentoo directory and config file are created
	keepdir /home/.bentoo
	insinto /home/.bentoo
	newins "${FILESDIR}/config.json.example" config.json

	# Create a wrapper script in /usr/bin
	cat > "${T}"/bentoo <<-EOF
		#!/bin/sh
		exec python -m overlay.main "\$@"
	EOF
	dobin "${T}"/bentoo
}

pkg_postinst() {
	elog "The bentoo utility has been installed."
	elog "You can use it by running 'bentoo overlay repo [add|status|commit|push]'"
	elog "Make sure to configure your overlay path in /home/.bentoo/config.json"
}