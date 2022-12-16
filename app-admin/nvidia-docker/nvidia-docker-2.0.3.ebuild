# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="NVIDIA Docker"
HOMEPAGE="https://github.com/NVIDIA/nvidia-docker"
SRC_URI="https://github.com/NVIDIA/nvidia-docker/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="NVIDIA CORPORATION"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
	app-emulation/docker
"
RDEPEND="${DEPEND}"

#src_compile() {
#        emake prefix="/usr"
#}

#src_install() {
#	emake prefix="${D}/usr" install
#}

src_compile() {
	true
}

src_install() {
	dobin ${PN}
	dodir /etc/docker
	insinto /etc/docker
	doins daemon.json
	fperms 644 /etc/docker/daemon.json
}

