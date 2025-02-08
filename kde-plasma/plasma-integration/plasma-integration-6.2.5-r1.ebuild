# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KF5MIN=5.115.0
KFMIN=6.6.0
QT5MIN=5.15.12
QTMIN=6.7.2
inherit ecm plasma.kde.org

DESCRIPTION="Qt Platform Theme integration plugins for the Plasma workspaces"

LICENSE="LGPL-2+"
SLOT="6"
KEYWORDS="amd64 arm64 ~loong ~ppc64 ~riscv ~x86"
IUSE="+qt6"

# requires running kde environment
RESTRICT="test"

# slot ops: qdbus*_p.h and Qt6::GuiPrivate for qtx11extras_p.h
COMMON_DEPEND="
	qt6? (
		dev-libs/wayland
		>=dev-qt/qtbase-${QTMIN}:6=[dbus,gui,widgets]
		>=dev-qt/qtdeclarative-${QTMIN}:6
		>=dev-qt/qtwayland-${QTMIN}:6
		>=kde-frameworks/kcolorscheme-${KFMIN}:6
		>=kde-frameworks/kcompletion-${KFMIN}:6
		>=kde-frameworks/kconfig-${KFMIN}:6
		>=kde-frameworks/kcoreaddons-${KFMIN}:6
		>=kde-frameworks/kguiaddons-${KFMIN}:6
		>=kde-frameworks/ki18n-${KFMIN}:6
		>=kde-frameworks/kiconthemes-${KFMIN}:6
		>=kde-frameworks/kio-${KFMIN}:6
		>=kde-frameworks/kjobwidgets-${KFMIN}:6
		>=kde-frameworks/knotifications-${KFMIN}:6
		>=kde-frameworks/kstatusnotifieritem-${KFMIN}:6
		>=kde-frameworks/kwindowsystem-${KFMIN}:6
		>=kde-frameworks/kxmlgui-${KFMIN}:6
		x11-libs/libXcursor
		x11-libs/libxcb
	)
"
DEPEND="${COMMON_DEPEND}
	>=dev-libs/plasma-wayland-protocols-1.14.0
"
RDEPEND="${COMMON_DEPEND}
	media-fonts/hack
	media-fonts/noto
	media-fonts/noto-emoji
"
PDEPEND="
	>=kde-plasma/xdg-desktop-portal-kde-${KDE_CATV}:6
"
BDEPEND="
	>=dev-qt/qtwayland-${QTMIN}:6
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_QT6=$(usex qt6)
	)
	ecm_src_configure
}
