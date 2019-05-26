# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: deadbeef-plugins.eclass
# @MAINTAINER:
# Roman Kuzmitsky <damex.pp@gmail.com>
# @BLURB: Eclass for automating deadbeef player plugins installation.
# @DESCRIPTION:
# This eclass makes trivial deadbeef plugin ebuilds possible.
# Many things that would normally be done manually is automated.

if [[ "${EAPI}" -lt 6 ]] ; then
	die "EAPI=${EAPI} is not supported"
fi

inherit eutils

: ${SLOT:=0}

RDEPEND+=" media-sound/deadbeef:0"
DEPEND+=" media-sound/deadbeef:0"

RESTRICT+=" mirror"

if [[ "${DEADBEEF_GUI}" == "yes" ]] ; then
	IUSE+=" +gtk2 gtk3"
	REQUIRED_USE="|| ( gtk2 gtk3 )"
	GUI_DEPEND="gtk2? ( media-sound/deadbeef:0[gtk2] )
		gtk3? ( media-sound/deadbeef:0[gtk3] )"
	RDEPEND+=" ${GUI_DEPEND}"
	DEPEND+=" ${GUI_DEPEND}"
fi

EXPORT_FUNCTIONS "src_install"

# @FUNCTION: deadbeef-plugins_src_install
# @DESCRIPTION:
# Looking for a *.so deadbeef plugins and installs found plugins to corresponding deadbeef directory.
deadbeef-plugins_src_install() {
	local plugins="$(find "${WORKDIR}" -name "*.so" -type f)"
	for plugin in ${plugins} ; do
		insinto "/usr/$(get_libdir)/deadbeef"
		doins "${plugin}"
	done
}
