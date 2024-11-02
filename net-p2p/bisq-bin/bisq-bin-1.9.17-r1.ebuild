# Copyright 2019-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="The decentralized bitcoin exchange (non-atomic, with arbitration)"
HOMEPAGE="https://bisq.network/ https://github.com/bisq-network/exchange/"
SRC_URI="https://bisq.network/downloads/v${PV}/Bisq-64bit-${PV}.deb"

S="${WORKDIR}"
LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="mirror strip"

DEPEND="
    dev-java/openjfx
    net-libs/libnet
    virtual/jre:*
    x11-libs/gtk+:3"

# Bundled java, and seems to mostly work without an old ffmpeg
QA_PREBUILT="opt/bisq/bin/Bisq opt/bisq/lib/libapplauncher.so opt/bisq/lib/runtime/*"
REQUIRES_EXCLUDE="libgstreamer-lite.so libavplugin-53.so libavplugin-54.so libavplugin-55.so libavplugin-56.so libavplugin-57.so libavplugin-ffmpeg-56.so libavplugin-ffmpeg-57.so"

src_compile() {
    :
}

src_install() {
    # Criar estrutura base do Bisq
    dodir /opt/bisq/bin
    dodir /opt/bisq/lib
    
    # Instalar o executável principal
    cp -a "${S}"/usr/lib/bisq/Bisq "${ED}"/opt/bisq/bin/ || die

    # Instalar bibliotecas e runtime
    cp -a "${S}"/usr/lib/bisq/lib/* "${ED}"/opt/bisq/lib/ || die
    cp -a "${S}"/usr/lib/bisq/runtime "${ED}"/opt/bisq/lib/ || die

    # Instalar arquivos de desktop e ícones
    domenu "${S}"/usr/share/applications/bisq-Bisq.desktop
    doicon "${S}"/usr/share/pixmaps/Bisq.png
}