# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )
inherit desktop distutils-r1 xdg

DESCRIPTION="Share files, host websites, and chat with friends using the Tor network."
HOMEPAGE="https://onionshare.org/ https://github.com/micahflee/onionshare"
SRC_URI="https://github.com/micahflee/onionshare/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=""
RDEPEND="www-servers/onionshare-cli[${PYTHON_USEDEP}]
	dev-python/colorama[${PYTHON_USEDEP}]
	dev-python/psutil[${PYTHON_USEDEP}]
	>=dev-python/pyside2-5.15.2[gui,widgets,${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]"
BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

RESTRICT="test"

DOCS=(../../CHANGELOG.md ../../README.md)

S=${WORKDIR}/${P}/desktop/src

python_install() {
	distutils-r1_python_install

	domenu org.onionshare.OnionShare.desktop
	doicon -s scalable org.onionshare.OnionShare.svg

	insinto /usr/share/metainfo
	doins org.onionshare.OnionShare.appdata.xml
}
