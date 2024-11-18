# Copyright 2019-2024 Gentoo Authors
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

QA_PREBUILT="
    opt/bisq/bin/Bisq
    opt/bisq/lib/runtime/*
    opt/bisq/lib/libapplauncher.so"

REQUIRES_EXCLUDE="
    libgstreamer-lite.so
    libavplugin-53.so
    libavplugin-54.so
    libavplugin-55.so
    libavplugin-56.so
    libavplugin-57.so
    libavplugin-ffmpeg-56.so
    libavplugin-ffmpeg-57.so"

src_compile() {
    :
}

src_install() {
    dodir /opt/bisq

    cp -r "${S}"/opt/bisq/* "${ED}"/opt/bisq/ || die
    
    if [[ ! -d "${ED}"/opt/bisq/bin ]]; then
        dodir /opt/bisq/bin
        mv "${ED}"/opt/bin/Bisq "${ED}"/opt/bisq/bin/ || die
    fi

    dosym ../../opt/bisq/bin/Bisq /usr/bin/bisq

    domenu "${S}"/opt/bisq/lib/bisq-Bisq.desktop
    doicon "${S}"/opt/bisq/lib/Bisq.png
}