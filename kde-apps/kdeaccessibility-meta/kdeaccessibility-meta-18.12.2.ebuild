# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="kdeaccessibility - merge this to pull in all kdeaccessiblity-derived packages"
HOMEPAGE="https://www.kde.org/"

LICENSE="metapackage"
SLOT="5"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	>=kde-apps/kmag-${PV}:${SLOT}
	>=kde-apps/kmousetool-${PV}:${SLOT}
	>=kde-apps/kmouth-${PV}:${SLOT}
"