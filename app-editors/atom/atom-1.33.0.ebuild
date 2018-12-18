# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 )

inherit desktop python-single-r1 xdg-utils

ELECTRON_SLOT="2.0"
ELECTRON_V="2.0.11"
MY_PV="${PV/_/-}"
RSRC_DIR="out/${PN}-${MY_PV}-amd64/resources"

DESCRIPTION="A hackable text editor for the 21st Century"
HOMEPAGE="https://atom.io"
SRC_URI="https://github.com/${PN}/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="node-prune"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

CDEPEND="${PYTHON_DEPS}
	>net-libs/nodejs-6.0
"
RDEPEND="${CDEPEND}
	>=dev-util/ctags-5.8
	>=dev-util/electron-bin-${ELECTRON_V}:${ELECTRON_SLOT}
	media-fonts/inconsolata
	!app-editors/atom-bin
	!sys-apps/apmd
"
DEPEND="${CDEPEND}
	node-prune? ( >=dev-util/node-prune-1.0.2_pre20180704 )
"

NM_PATH="usr/libexec/atom/app.asar.unpacked/node_modules"
QA_PREBUILT="
	${NM_PATH}/dugite/git/bin/git
	${NM_PATH}/dugite/git/libexec/git-core/*
	${NM_PATH}/keytar/build/Release/keytar.node
	${NM_PATH}/tree-sitter/build/Release/tree_sitter_runtime_binding.node
	${NM_PATH}/tree-sitter-bash/build/Release/tree_sitter_bash_binding.node
	${NM_PATH}/tree-sitter-ruby/build/Release/tree_sitter_ruby_binding.node
	${NM_PATH/.asar.unpacked//apm}/keytar/build/Release/keytar.node
"

PATCHES=(
	"${FILESDIR}/${PN}-apm-path.patch"
	"${FILESDIR}/${PN}-fix-app-restart.patch"
	"${FILESDIR}/${PN}-fix-config-watcher-r1.patch"
	"${FILESDIR}/${PN}-unbundle-electron.patch"
)

S="${WORKDIR}/${PN}-${MY_PV}"

pkg_setup() {
	if [[ "${MERGE_TYPE}" != binary ]]; then
		# shellcheck disable=SC2086
		if has network-sandbox ${FEATURES}; then
			ewarn
			ewarn "${CATEGORY}/${PN} requires 'network-sandbox' to be disabled in FEATURES"
			ewarn
			die "[network-sandbox] is enabled in FEATURES"
		fi

		python-single-r1_pkg_setup
		npm config set python "${PYTHON}" || die
	fi
}

src_prepare() {
	local suffix
	suffix="$(get_install_suffix)"
	default

	# Make bootstrap process more verbose
	sed -i 's|node script/bootstrap|node script/bootstrap --no-quiet|g' \
		script/build || die

	# Fix path for "View License" in Help menu and active pane
	sed "s|path.join(process.resourcesPath, 'LICENSE.md')|'${EPREFIX}/usr/share/licenses/atom/LICENSE.md'|g" \
		-i src/main-process/atom-application.js \
		-i src/workspace.js || die

	sed -i \
		-e "/ATOM_HOME=/i export PYTHON=${PYTHON}\\n" \
		-e "s|{{ATOM_PATH}}|${EPREFIX}/opt/electron-${ELECTRON_SLOT}/electron|g" \
		-e "s|{{ATOM_RESOURCE_PATH}}|${EPREFIX}/usr/libexec/atom/app.asar|g" \
		-e "s|{{ATOM_PREFIX}}|${EPREFIX}|g" \
		atom.sh || die

	sed -i \
		-e "s|{{ATOM_PREFIX}}|${EPREFIX}|g" \
		-e "s|{{ATOM_SUFFIX}}|${suffix}|g" \
		src/config-schema.js || die
}

src_compile() {
	NO_UPDATE_NOTIFIER="" ./script/build --verbose || die "Failed to compile"

	pushd "${RSRC_DIR}" > /dev/null || die
	if use node-prune; then
		pushd app/apm > /dev/null || die
		node-prune || die
		popd > /dev/null || die

		pushd app.asar.unpacked > /dev/null || die
		node-prune || die
		popd > /dev/null || die
	fi

	# Make sure python-interceptor.sh use python2.*
	sed -i "s|exec python|exec ${PYTHON}|g" app/apm/bin/python-interceptor.sh || die

	pushd app.asar.unpacked/node_modules/symbols-view/vendor > /dev/null || die
	# Remove non-Linux vendored ctags binaries
	rm ctags-{darwin,win32.exe} || die
	# Replace vendored ctags with a symlink to system ctags
	rm ctags-linux || die
	ln -s "${EPREFIX}/usr/bin/ctags" ctags-linux || die
	popd > /dev/null || die

	# Remove redundant atom.png
	rm -r app.asar.unpacked/resources || die
	popd > /dev/null || die
}

src_install() {
	insinto /usr/libexec/atom
	doins -r "${RSRC_DIR}"/*

	# Install icons and desktop entry
	local size
	for size in 16 24 32 48 64 128 256 512; do
		newicon -s ${size} "resources/app-icons/stable/png/${size}.png" atom.png
	done
	# shellcheck disable=SC1117
	make_desktop_entry atom Atom atom \
		"GNOME;GTK;Utility;TextEditor;Development;" \
		"MimeType=text/plain;\nStartupNotify=true\nStartupWMClass=atom"
	sed -e "/^Exec/s/$/ %F/" -i "${ED}"/usr/share/applications/*.desktop || die

	# Fix permissions
	fperms +x /usr/libexec/atom/app/atom.sh
	fperms +x /usr/libexec/atom/app/apm/bin/apm
	fperms +x /usr/libexec/atom/app/apm/bin/node
	fperms +x /usr/libexec/atom/app/apm/bin/python-interceptor.sh
	fperms +x /usr/libexec/atom/app/apm/node_modules/npm/bin/node-gyp-bin/node-gyp
	# Symlink to /usr/bin
	dosym ../libexec/atom/app/atom.sh /usr/bin/atom
	dosym ../libexec/atom/app/apm/bin/apm /usr/bin/apm
	# Symlink LICENSE.md for "View License" in Help menu and About page
	dosym ../../../libexec/atom/LICENSE.md /usr/share/licenses/atom/LICENSE.md
}

# Return the installation suffix appropriate for the slot
get_install_suffix() {
	local slot=${SLOT%%/*}
	local suffix

	if [[ "${slot}" == "0" ]]; then
		suffix=""
	else
		suffix="-${slot}"
	fi

	echo "${suffix}"
}

update_caches() {
	if type gtk-update-icon-cache &>/dev/null; then
		ebegin "Updating GTK icon cache"
		gtk-update-icon-cache "${EROOT}/usr/share/icons/hicolor" || die
		eend $?
	fi
	xdg_desktop_database_update
}

pkg_postrm() {
	update_caches
}

pkg_postinst() {
	update_caches
}
