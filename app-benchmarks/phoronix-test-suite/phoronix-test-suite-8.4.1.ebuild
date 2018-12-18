# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit bash-completion-r1

DESCRIPTION="Phoronix's comprehensive, cross-platform testing and benchmark suite"
HOMEPAGE="https://www.phoronix-test-suite.com"
SRC_URI="https://github.com/phoronix-test-suite/phoronix-test-suite/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="dev-lang/php[cli,curl,gd,json,posix,pcntl,truetype,zip]"

HTML_DOCS=( "${S}"/documentation/. )

src_prepare() {
	sed -i -e "s,export PTS_DIR=\`pwd\`,export PTS_DIR=\"/usr/share/${PN}\"," \
		phoronix-test-suite

	default
}

src_configure() {
	:
}

src_compile() {
	:
}

src_install() {
	dodir /usr/share/${PN}
	insinto /usr/share/${PN}

	doman documentation/man-pages/phoronix-test-suite.1
	dodoc AUTHORS ChangeLog README.md
	einstalldocs
	doicon pts-core/static/images/phoronix-test-suite.png
	doicon pts-core/static/images/openbenchmarking.png
	domenu pts-core/static/phoronix-test-suite.desktop
	rm -f pts-core/static/phoronix-test-suite.desktop || die

	doins -r pts-core
	exeinto /usr/bin
	doexe phoronix-test-suite

	fperms a+x /usr/share/${PN}/pts-core/static/root-access.sh
	fperms a+x /usr/share/${PN}/pts-core/external-test-dependencies/scripts/install-gentoo-packages.sh

	newbashcomp pts-core/static/bash_completion ${PN}

	# Need to fix the cli-php config for downloading to work. Very naughty!
	local slots
	local slot
	if [[ "x${PHP_TARGETS}" == "x" ]] ; then
		ewarn
		ewarn "PHP_TARGETS seems empty, php.ini file can't be configured."
		ewarn "Make sure that PHP_TARGETS in /etc/make.conf is set."
		ewarn "phoronix-test-suite needs the 'allow_url_fopen' option set to \"On\""
		ewarn "for downloading to work properly."
		ewarn
	else
		for slot in ${PHP_TARGETS}; do
			slots+=" ${slot/-/.}"
		done
	fi
}
