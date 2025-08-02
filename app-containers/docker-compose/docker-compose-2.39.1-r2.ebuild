# Copyright 2018-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit eapi9-ver go-env go-module
MY_PV=${PV/_/-}

DESCRIPTION="Multi-container orchestration for Docker"
HOMEPAGE="https://github.com/docker/compose"
SRC_URI="https://github.com/docker/compose/archive/v${MY_PV}.tar.gz -> ${P}.gh.tar.gz"

S="${WORKDIR}/compose-${MY_PV}"

LICENSE="Apache-2.0"
SLOT="2"
KEYWORDS="~amd64 ~arm64"

# Add network dependencies for Go module fetching
BDEPEND="
	>=dev-lang/go-1.21
	net-misc/wget
	net-misc/curl
	dev-vcs/git
"

RDEPEND="app-containers/docker-cli"

# Tests require Internet access and we need network access for Go modules
PROPERTIES="test_network"
RESTRICT="network-sandbox strip"

src_unpack() {
	default
	go-env_set_compile_environment
}

src_prepare() {
	default
	
	# Initialize Go modules and download dependencies
	einfo "Initializing Go modules and downloading dependencies..."
	
	# Set Go environment variables for proper module handling
	export GO111MODULE=on
	export GOPROXY="https://proxy.golang.org,direct"
	export GOSUMDB="sum.golang.org"
	export GOFLAGS="-buildvcs=false"
	
	# Download and verify Go modules
	go mod download -x || die "Failed to download Go modules"
	go mod verify || die "Failed to verify Go modules"
	
	# Vendor the dependencies locally for build reproducibility
	go mod vendor || die "Failed to vendor Go modules"
	
	# do not strip
	sed -i -e 's/-s -w//' Makefile || die
}

src_configure() {
	# Set Go build environment
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"
	
	# Use vendored modules for build reproducibility
	export GOFLAGS="${GOFLAGS} -mod=vendor"
}

src_compile() {
	# Ensure Go modules are available during compilation
	export GOFLAGS="${GOFLAGS} -mod=vendor"
	
	# Build with proper Go flags for Gentoo
	emake VERSION=v${PV} GOFLAGS="-buildmode=pie -mod=vendor ${GOFLAGS}"
}

src_test() {
	# Use vendored modules for testing
	export GOFLAGS="${GOFLAGS} -mod=vendor"
	emake test
}

src_install() {
	exeinto /usr/libexec/docker/cli-plugins
	doexe bin/build/docker-compose
	dodoc README.md
}

pkg_postinst() {
	ver_replacing -ge 2 && return
	ewarn
	ewarn "docker-compose 2.x is a sub command of docker"
	ewarn "Use 'docker compose' from the command line instead of"
	ewarn "'docker-compose'"
	ewarn "If you need to keep 1.x around, please run the following"
	ewarn "command before your next --depclean"
	ewarn "# emerge --noreplace docker-compose:0"
	ewarn
	elog "Go dependencies were fetched during build process."
}