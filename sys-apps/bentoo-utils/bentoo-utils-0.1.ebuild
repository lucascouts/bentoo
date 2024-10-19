 
# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1

DESCRIPTION="Utility for managing Git operations for the Bentoo project"
HOMEPAGE="https://github.com/lucascouts/bentoo-utils"
SRC_URI="https://github.com/lucascouts/bentoo-utils/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
  dev-lang/python
	dev-vcs/git
"

DEPEND="
	${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

python_install_all() {
	distutils-r1_python_install_all

	# Install the bentoo shell script
	exeinto /usr/bin
	doexe "${FILESDIR}/bentoo"
}

pkg_postinst() {
	elog "The bentoo utility has been installed."
	elog "You can use it by running 'bentoo overlay [add|status|commit|set-user]'"
}