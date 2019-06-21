# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop xdg-utils

ELECTRON_SLOT="3.1"
ELECTRON_V="3.1.2"
MY_PV="${PV/_/-}"

DESCRIPTION="A hackable text editor for the 21st Century"
HOMEPAGE="https://atom.io"
SRC_URI="https://github.com/${PN}/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+audit"

DEPEND="
	dev-nodejs/apm
	>=net-libs/nodejs-8.12.0
"
RDEPEND="${DEPEND}
	>=dev-util/ctags-5.8
	>=dev-util/electron-bin-${ELECTRON_V}:${ELECTRON_SLOT}
	dev-vcs/git
	media-fonts/inconsolata
	x11-libs/libxkbfile
	!app-editors/atom-bin
	!sys-apps/apmd
"

PATCHES=(
	"${FILESDIR}/${PN}-apm-path-r0.patch"
	"${FILESDIR}/${PN}-fix-atom-sh-r0.patch"
	"${FILESDIR}/${PN}-fix-config-watcher-r1.patch"
	"${FILESDIR}/${PN}-use-system-electron-r1.patch"
	"${FILESDIR}/${PN}-use-system-apm-r0.patch"
	"${FILESDIR}/${PN}-fix-restart-r0.patch"
	"${FILESDIR}/${PN}-electron-3-r0.patch"
)

QA_PRESTRIPPED="usr/libexec/atom/node_modules/.*"

S="${WORKDIR}/${PN}-${MY_PV}"

pkg_pretend() {
	# shellcheck disable=SC2086
	if has network-sandbox ${FEATURES} && [[ "${MERGE_TYPE}" != binary ]]; then
		ewarn
		ewarn "${CATEGORY}/${PN} requires 'network-sandbox' to be disabled in FEATURES"
		ewarn
		die "[network-sandbox] is enabled in FEATURES"
	fi
}

src_prepare() {
	default

	sed "s|{{ATOM_PREFIX}}|${EPREFIX}|g" \
		-i atom.sh \
		-i src/config-schema.js \
		-i src/main-process/atom-application.js \
		-i src/module-cache.js \
		-i src/package-manager.js \
		-i src/task-bootstrap.js \
		-i static/index.js || die

	sed "s|{{ELECTRON_BIN}}|electron-${ELECTRON_SLOT}|g" \
		-i script/lib/generate-startup-snapshot.js || die

	sed "s|{{LIBDIR_PATH}}|${EPREFIX}/usr/$(get_libdir)|g" \
		-i src/package-manager.js || die

	# Fix license path
	sed "s|path.join(process.resourcesPath, 'LICENSE.md')|'${EPREFIX}/usr/share/licenses/atom/LICENSE.md'|g" \
		-i src/main-process/atom-application.js \
		-i src/workspace.js || die
}

src_compile() {
	# Fix for Electron 3
	npm install --package-lock-only @atom/nsfw@1.0.20 node-abi || die
	eaudit

	ATOM_RESOURCE_PATH="${PWD}" \
		npm_config_target=$(tail -c +2 "${EROOT}/opt/electron-${ELECTRON_SLOT}/version") \
		apm install || die

	# Use system ctags
	pushd node_modules/symbols-view > /dev/null || die
	eapply "${FILESDIR}/${PN}-symbols-view-use-system-ctags-r0.patch" || die
	rm -r vendor || die
	popd > /dev/null || die

	# Use system git
	pushd node_modules/dugite > /dev/null || die
	eapply "${FILESDIR}/${PN}-dugite-use-system-git-r0.patch" || die
	rm -r git || die
	popd > /dev/null || die

	# Fix tab close on middle click for Electron 3
	pushd node_modules/tabs > /dev/null || die
	eapply "${FILESDIR}/${PN}-fix-middle-click.patch" || die
	popd > /dev/null || die

	pushd script > /dev/null || die
	npm install || die
	eaudit
	./build || die
	popd > /dev/null || die

	pushd out/app > /dev/null || die
	eapply "${FILESDIR}/${PN}-marker-layer-r1.patch" || die
	popd > /dev/null || die

	# Compile LICENSE.md
	node -e "require('./script/lib/get-license-text')().then((licenseText) => require('fs').writeFileSync('${T}/LICENSE.md', licenseText))" || die

	# Remove useless stuff
	find out/app/node_modules \
		-name "*.a" -exec rm '{}' \; \
		-or -name "*.bat" -exec rm '{}' \; \
		-or -name "*.c" -exec rm '{}' \; \
		-or -name "*.cpp" -exec rm '{}' \; \
		-or -name ".eslint*" -exec rm '{}' \; \
		-or -name "*.markdown" -exec rm '{}' \; \
		-or -name "*.node" -exec chmod a-x '{}' \; \
		-or -name "AUTHORS*" -exec rm '{}' \; \
		-or -name "benchmark" -prune -exec rm -r '{}' \; \
		-or -name "CHANGE*" -exec rm '{}' \; \
		-or -name "CONTRIBUT*" -exec rm '{}' \; \
		-or -name "doc" -prune -exec rm -r '{}' \; \
		-or -name "html" -prune -exec rm -r '{}' \; \
		-or -name "ISSUE*" -exec rm '{}' \; \
		-or -name "Makefile*" -exec rm '{}' \; \
		-or -name "man" -prune -exec rm -r '{}' \; \
		-or -name "PULL*" -exec rm '{}' \; \
		-or -name "README*" -exec rm '{}' \; \
		-or -name "scripts" -prune -exec rm -r '{}' \; \
		-or -path "*/less/gradle" -prune -exec rm -r '{}' \; \
		-or -path "*/task-lists/src" -prune -exec rm -r '{}' \; || die
}

src_install() {
	insinto /usr/libexec/atom
	doins -r out/app/*
	doins out/startup.js

	newbin atom.sh atom
	exeinto /usr/libexec/atom
	newexe "${FILESDIR}/atom.js" atom
	sed "s|{{ELECTRON_PATH}}|$(command -v electron-${ELECTRON_SLOT})|" \
		-i "${ED}/usr/libexec/atom/atom" || die

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

	insinto /usr/share/licenses/atom
	doins "${T}"/LICENSE.md
}

eaudit() {
	if use audit && [[ $(npm --version) =~ 6.* ]]; then
		ebegin "Attempting to fix potential vulnerabilities"
		npm audit fix --package-lock-only
		eend $? || die
	fi
}

update_caches() {
	if type gtk-update-icon-cache &>/dev/null; then
		ebegin "Updating GTK icon cache"
		gtk-update-icon-cache "${EROOT}/usr/share/icons/hicolor"
		eend $? || die
	fi
	xdg_desktop_database_update
}

pkg_postrm() {
	update_caches
}

pkg_postinst() {
	update_caches
}
