# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 go-module
MY_PV=${PV/_/-}

# update this on every bump
GIT_COMMIT=980b85681696fbd95927fd8ded8f6d91bdca95b0

DESCRIPTION="the command line binary for docker"
HOMEPAGE="https://www.docker.com/"
SRC_URI="https://github.com/docker/cli/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/cli-${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~x86"
IUSE="hardened selinux"

# Add build dependencies for man page generation
BDEPEND="
	>=dev-lang/go-1.21
	dev-go/go-md2man
"

RDEPEND="selinux? ( sec-policy/selinux-docker )"

RESTRICT="installsources strip test"

src_unpack() {
	default
	cd "${S}"
	ln -s vendor.mod go.mod
	ln -s vendor.sum go.sum
}

src_prepare() {
	default
	sed -i 's@dockerd\?\.exe@@g' contrib/completion/bash/docker || die
	
	# Ensure man directory exists
	mkdir -p man || die "Failed to create man directory"
}

src_compile() {
	export DISABLE_WARN_OUTSIDE_CONTAINER=1
	# setup CFLAGS and LDFLAGS for separate build target
	# see https://github.com/tianon/docker-overlay/pull/10
	CGO_CFLAGS+=" -I${ESYSROOT}/usr/include"
	CGO_LDFLAGS+=" -L${ESYSROOT}/usr/$(get_libdir)"
		emake \
		LDFLAGS="$(usex hardened '-extldflags -fno-PIC' '')" \
		VERSION="${PV}" \
		GITCOMMIT="${GIT_COMMIT}" \
		dynbinary

	# Generate man pages
	einfo "Generating man pages..."
	emake \
		VERSION="${PV}" \
		GITCOMMIT="${GIT_COMMIT}" \
		manpages || die "Failed to generate man pages"
	
	# Verify man pages were generated
	if [[ ! -d man/man1 ]] || [[ -z "$(find man -name '*.1' -type f)" ]]; then
		die "Man pages were not generated successfully"
	fi
	
	einfo "Man pages generated successfully in man/ directory"
}

src_install() {
	dobin build/docker
	doman man/man?/*
	dobashcomp contrib/completion/bash/docker
	bashcomp_alias docker dockerd
	insinto /usr/share/fish/vendor_completions.d/
	doins contrib/completion/fish/docker.fish
	insinto /usr/share/zsh/site-functions
	doins contrib/completion/zsh/_*
}

pkg_postinst() {
	has_version "app-containers/docker-buildx" && return
	ewarn "the 'docker build' command is deprecated and will be removed in a"
	ewarn "future release. If you need this functionality, install"
	ewarn "app-containers/docker-buildx."
	ewarn
	elog "Man pages were generated during build process."
}
