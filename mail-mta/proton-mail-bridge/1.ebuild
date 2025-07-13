# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake desktop go-env go-module systemd xdg-utils

MY_PN="${PN/-mail/}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Serves Proton Mail to IMAP/SMTP clients"
HOMEPAGE="https://proton.me/mail/bridge https://github.com/ProtonMail/proton-bridge/"
SRC_URI="https://github.com/ProtonMail/${MY_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}"/${MY_P}

LICENSE="GPL-3+ Apache-2.0 BSD BSD-2 ISC LGPL-3+ MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gui"

# Network access required for downloading Go modules and running tests
PROPERTIES="test_network"
RESTRICT="test network-sandbox"

RDEPEND="
	app-crypt/libsecret
	gui? (
		>=dev-libs/protobuf-21.12:=
		dev-libs/re2:=
		>=dev-libs/sentry-native-0.6.5-r1
		dev-qt/qtbase:6=[gui,icu,widgets]
		dev-qt/qtdeclarative:6=[widgets]
		dev-qt/qtsvg:6=
		media-libs/mesa
		net-libs/grpc:=
	)
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-3.15.1-gui_gentoo.patch
)

DOCS=( "${S}"/{README,Changelog}.md )

# Go module configuration
go_module_setup() {
	# Set up Go environment
	go-env_set_compile_environment
	
	# Configure module proxy and checksum database
	export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
	export GOSUMDB="${GOSUMDB:-sum.golang.org}"
	
	# Use a persistent cache directory
	export GOMODCACHE="${T}/go-mod-cache"
	mkdir -p "${GOMODCACHE}" || die "Failed to create Go module cache"
	
	# Security settings
	export GOPRIVATE=""
	export GONOPROXY=""
	export GONOSUMDB=""
	
	# Performance settings
	export GOMAXPROCS="$(nproc)"
	
	# Enable module mode
	export GO111MODULE=on
}

go_module_download() {
	einfo "Downloading Go modules..."
	
	# Download dependencies with verbose output
	ego mod download -x || die "Failed to download Go modules"
	
	# Verify integrity
	ego mod verify || die "Module verification failed"
	
	# Create vendor directory for reproducible builds
	ego mod vendor || die "Failed to vendor modules"
	
	# Tidy up go.mod and go.sum
	ego mod tidy || die "Failed to tidy modules"
	
	einfo "Go modules downloaded successfully"
}

go_module_cache_info() {
	if [[ -d "${GOMODCACHE}" ]]; then
		local cache_size=$(du -sh "${GOMODCACHE}" | cut -f1)
		local module_count=$(find "${GOMODCACHE}" -name "go.mod" | wc -l)
		einfo "Go module cache: ${cache_size} (${module_count} modules)"
	fi
}

src_unpack() {
	default
	go_module_setup
}

src_prepare() {
	xdg_environment_reset
	default
	
	# Download Go modules
	go_module_download
	go_module_cache_info
	
	if use gui; then
		# prepare desktop file
		local desktopFilePath="${S}"/dist/${MY_PN}.desktop
		sed -i 's/protonmail/proton-mail/g' ${desktopFilePath} || die
		sed -i 's/Exec=proton-mail-bridge/Exec=proton-mail-bridge-gui/g' ${desktopFilePath} || die

		# build GUI
		local PATCHES=()
		BUILD_DIR="${WORKDIR}"/gui_build \
			CMAKE_USE_DIR="${S}"/internal/frontend/bridge-gui/bridge-gui \
			cmake_src_prepare
	fi
}

src_configure() {
	# Configure Go build environment with security hardening
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"
	
	# Build flags for reproducible builds
	local build_flags=(
		-buildmode=pie
		-mod=vendor
		-trimpath
		-ldflags="-linkmode=external -extldflags='${LDFLAGS}' -s -w"
	)
	
	export GOFLAGS="${build_flags[*]}"
	
	if use gui; then
		local mycmakeargs=(
			-DBRIDGE_APP_FULL_NAME="Proton Mail Bridge"
			-DBRIDGE_APP_VERSION="${PV}+git"
			-DBRIDGE_REPO_ROOT="${S}"
			-DBRIDGE_TAG="NOTAG"
			-DBRIDGE_VENDOR="Gentoo Linux"
			-DCMAKE_DISABLE_PRECOMPILE_HEADERS=OFF
		)
		BUILD_DIR="${WORKDIR}"/gui_build \
			CMAKE_USE_DIR="${S}"/internal/frontend/bridge-gui/bridge-gui \
			cmake_src_configure
	fi
}

src_compile() {
	# Build with enhanced flags
	emake -Onone build-nogui

	if use gui; then
		BUILD_DIR="${WORKDIR}"/gui_build \
			CMAKE_USE_DIR="${S}"/internal/frontend/bridge-gui/bridge-gui \
			cmake_src_compile
	fi
}

src_test() {
	# Ensure module cache is available for tests
	go_module_cache_info
	emake -Onone test
}

src_install() {
	exeinto /usr/bin
	newexe bridge ${PN}

	if use gui; then
		BUILD_DIR="${WORKDIR}"/gui_build \
			CMAKE_USE_DIR="${S}"/internal/frontend/bridge-gui/bridge-gui \
			cmake_src_install
		mv "${ED}"/usr/bin/bridge-gui "${ED}"/usr/bin/${PN}-gui || die
		newicon {"${S}"/dist/bridge,${PN}}.svg
		newmenu {dist/${MY_PN},${PN}}.desktop
	fi

	systemd_newuserunit "${FILESDIR}"/${PN}.service-r1 ${PN}.service

	einstalldocs
}