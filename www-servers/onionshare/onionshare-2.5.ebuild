# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{7..10} )
inherit desktop distutils-r1 xdg

DESCRIPTION="Share files, host websites, and chat with friends using the Tor network."
HOMEPAGE="https://onionshare.org/ https://github.com/onionshare/onionshare"
SRC_URI="https://github.com/onionshare/onionshare/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=""
RDEPEND="www-servers/onionshare-cli[${PYTHON_USEDEP}]
	dev-python/cx_Freeze[${PYTHON_USEDEP}]
	>=dev-python/pyside2-5.15.2[gui,widgets,${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]"
BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

RESTRICT="test"

DOCS=(../CHANGELOG.md ../README.md)

S=${WORKDIR}/${P}/desktop

python_install() {
	distutils-r1_python_install

	domenu org.onionshare.OnionShare.desktop
	doicon -s scalable org.onionshare.OnionShare.svg

	insinto /usr/share/metainfo
	doins org.onionshare.OnionShare.appdata.xml
}
