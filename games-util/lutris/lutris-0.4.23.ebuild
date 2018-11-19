# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

PYTHON_COMPAT=( python3_{4,5,6,7} )

inherit distutils-r1 gnome2-utils python-r1

DESCRIPTION="Lutris is an open source gaming platform for GNU/Linux."
HOMEPAGE="https://lutris.net/"

if [[ "${PV}" == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/lutris/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/lutris/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0/0.4"

DEPEND="
	dev-python/pygobject:3[${PYTHON_USEDEP}]
"
RDEPEND="
	${DEPEND}
	app-arch/cabextract
	dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/python-evdev[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	net-libs/libsoup
	sys-process/psmisc
	x11-apps/xrandr
	x11-apps/xgamma"

list_optional_dependencies() {
	local i package IFS
	local -a optional_packages_sorted_array \
			 optional_packages_array

	optional_packages_array=( "${@}" )
	# shellcheck disable=SC2068
	for i in ${!optional_packages_array[@]}; do
		has_version "${optional_packages_array[i]}" || continue
		unset -v 'optional_packages_array[i]'
	done
	# shellcheck disable=SC2207
	IFS=$'\n' optional_packages_sorted_array=( $(sort <<<"${optional_packages_array[*]}") )
	(( ${#optional_packages_sorted_array[@]} )) || return

	elog "Recommended additional packages:"
	# shellcheck disable=SC2068
	for package in ${optional_packages_sorted_array[@]}; do
		elog "  ${package}"
	done
}

python_install() {
	distutils-r1_python_install
}

src_prepare() {
	distutils-r1_src_prepare
}

src_compile() {
	distutils-r1_src_compile
}

src_install() {
	# README.rst contains list of optional deps
	DOCS=( AUTHORS README.rst INSTALL.rst )
	distutils-r1_src_install
}

pkg_preinst() {
	gnome2_icon_savelist
	gnome2_schemas_savelist
}

pkg_postinst() {
	local -a optional_packages_array=( "sys-apps/pciutils" )

	gnome2_icon_cache_update
	gnome2_schemas_update

	list_optional_dependencies "${optional_packages_array[@]}"

	elog "For a list of optional dependencies (runners) see:"
	elog "/usr/share/doc/${PF}/README.rst.bz2"
}

pkg_postrm() {
	gnome2_icon_cache_update
	gnome2_schemas_update
}
