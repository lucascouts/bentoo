# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( {18..19} )
PYTHON_COMPAT=( python3_{10..13} )

inherit llvm-r1 meson python-any-r1

PN="mesa"
MY_PV="${PV/_/-}"

DESCRIPTION="mesa_clc tool used for building OpenCL C to SPIR-V"
HOMEPAGE="https://mesa3d.org/"

if [[ ${PV} == 9999 ]]; then
	S="${WORKDIR}/mesa_clc-${MY_PV}"
	EGIT_REPO_URI="https://gitlab.freedesktop.org/mesa/mesa.git"
	inherit git-r3
else
	GIT_COMMIT="d8782db3a48205f71c03feaf7ddfb092b8a523b2"
	S="${WORKDIR}/mesa-${GIT_COMMIT}"
	SRC_URI="https://gitlab.freedesktop.org/${PN}/${PN}/-/archive/${GIT_COMMIT}/mesa-${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="debug"

RDEPEND="
	dev-util/spirv-tools
	$(llvm_gen_dep '
		dev-util/spirv-llvm-translator:${LLVM_SLOT}
		llvm-core/clang:${LLVM_SLOT}=
		=llvm-core/libclc-${LLVM_SLOT}*
		llvm-core/llvm:${LLVM_SLOT}=
	')
"
DEPEND="${RDEPEND}
	dev-libs/expat
	>=sys-libs/zlib-1.2.8:=
	x11-libs/libdrm
"
BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_any_dep "
		>=dev-python/mako-0.8.0[\${PYTHON_USEDEP}]
		dev-python/packaging[\${PYTHON_USEDEP}]
		dev-python/pyyaml[\${PYTHON_USEDEP}]
	")
	virtual/pkgconfig
"

python_check_deps() {
	python_has_version -b ">=dev-python/mako-0.8.0[${PYTHON_USEDEP}]" &&
	python_has_version -b "dev-python/packaging[${PYTHON_USEDEP}]" &&
	python_has_version -b "dev-python/pyyaml[${PYTHON_USEDEP}]" || return 1
}

pkg_setup() {
	llvm-r1_pkg_setup
	python-any-r1_pkg_setup
}

src_configure() {
	PKG_CONFIG_PATH="$(get_llvm_prefix)/$(get_libdir)/pkgconfig"

	use debug && EMESON_BUILDTYPE=debug

	local emesonargs=(
		-Dllvm=enabled
		-Dshared-llvm=enabled
		-Dmesa-clc=enabled
		-Dinstall-mesa-clc=true

		-Dgallium-drivers=''
		-Dvulkan-drivers=''

		# Set platforms empty to avoid the default "auto" setting. If
		# platforms is empty meson.build will add surfaceless.
		-Dplatforms=''

		-Dglx=disabled
		-Dlibunwind=disabled
		-Dzstd=disabled

		-Db_ndebug=$(usex debug false true)
	)
	meson_src_configure
}

src_install() {
	dobin "${BUILD_DIR}"/src/compiler/clc/mesa_clc
	dobin "${BUILD_DIR}"/src/compiler/spirv/vtn_bindgen2
}
