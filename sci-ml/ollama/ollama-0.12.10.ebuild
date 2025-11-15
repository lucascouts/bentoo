# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# ROCm support for >=5.5, but we define 6.2 due to eclass requirements
ROCM_VERSION="6.2"

# Inherit eclasses in logical order: hardware-specific -> build system -> utilities
inherit cuda rocm
inherit cmake
inherit flag-o-matic go-module linux-info systemd toolchain-funcs

DESCRIPTION="Get up and running with Llama 3, Mistral, Gemma, and other language models"
HOMEPAGE="https://ollama.com"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ollama/ollama.git"
else
	SRC_URI="
		https://github.com/ollama/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
		https://github.com/gentoo-golang-dist/${PN}/releases/download/v${PV}/${P}-deps.tar.xz
	"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0"

# Define CPU instruction set flags for x86_64 optimization variants
X86_CPU_FLAGS=(
	sse4_2       # Streaming SIMD Extensions 4.2
	avx          # Advanced Vector Extensions
	f16c         # Half-precision floating point conversion
	avx2         # Advanced Vector Extensions 2
	bmi2         # Bit Manipulation Instruction Set 2
	fma3         # Fused Multiply-Add 3
	avx512f      # AVX-512 Foundation
	avx512vbmi   # AVX-512 Vector Byte Manipulation Instructions
	avx512_vnni  # AVX-512 Vector Neural Network Instructions
	avx_vnni     # AVX Vector Neural Network Instructions
)

CPU_FLAGS=( "${X86_CPU_FLAGS[@]/#/cpu_flags_x86_}" )
IUSE="blas ${CPU_FLAGS[*]} cuda mkl rocm vulkan"

RESTRICT="test"

# Common dependencies shared across DEPEND/RDEPEND
COMMON_DEPEND="
	blas? (
		!mkl? (
			virtual/blas
		)
		mkl? (
			sci-libs/mkl
		)
	)
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
	rocm? (
		>=dev-util/hip-${ROCM_VERSION}:=
		>=sci-libs/hipBLAS-${ROCM_VERSION}:=[${ROCM_USEDEP}]
		>=sci-libs/rocBLAS-${ROCM_VERSION}:=[${ROCM_USEDEP}]
	)
"

# Build-time dependencies
DEPEND="
	${COMMON_DEPEND}
	>=dev-lang/go-1.23.4
"

# Build-time only dependencies (headers, tools that don't need to be installed)
BDEPEND="
	vulkan? (
		dev-util/vulkan-headers
		media-libs/shaderc
	)
"

# Runtime dependencies
RDEPEND="
	${COMMON_DEPEND}
	acct-group/${PN}
	>=acct-user/${PN}-3[cuda?]
"

PATCHES=(
	"${FILESDIR}/${PN}-9999-use-GNUInstallDirs.patch"
)

# Pre-merge checks and warnings
pkg_pretend() {
	if use amd64; then
		# Check for incomplete CPU flag combinations that would skip optimized variants
		if use cpu_flags_x86_f16c && use cpu_flags_x86_avx2 && use cpu_flags_x86_fma3 && ! use cpu_flags_x86_bmi2; then
			ewarn ""
			ewarn "CPU_FLAGS_X86: bmi2 not enabled."
			ewarn "  This will skip building the following optimized CPU backends:"
			ewarn "    - haswell   (Haswell/Broadwell CPUs)"
			ewarn "    - skylakex  (Skylake-X/Cascade Lake CPUs)"
			ewarn "    - icelake   (Ice Lake CPUs)"
			ewarn "    - alderlake (Alder Lake CPUs)"
			ewarn ""
			
			# Auto-detect if the running CPU actually supports bmi2
			if grep -q bmi2 /proc/cpuinfo 2>/dev/null; then
				ewarn "NOTE: bmi2 instruction set detected in /proc/cpuinfo"
				ewarn "      Consider enabling cpu_flags_x86_bmi2 for better performance"
				ewarn ""
			fi
		fi
	fi
}

# Setup phase - validate system configuration for hardware acceleration
pkg_setup() {
	# Verify kernel configuration for ROCm/HIP support
	if use rocm; then
		linux-info_pkg_setup
		
		if linux_config_exists; then
			# HSA_AMD_SVM is required for ROCm shared virtual memory
			if ! linux_chkconfig_present HSA_AMD_SVM; then
				ewarn ""
				ewarn "Kernel configuration issue detected:"
				ewarn "  CONFIG_HSA_AMD_SVM is not enabled"
				ewarn ""
				ewarn "To use ROCm/HIP hardware acceleration, you need to enable"
				ewarn "HSA_AMD_SVM in your kernel configuration."
				ewarn ""
				ewarn "Required kernel option:"
				ewarn "  Device Drivers ->"
				ewarn "    GPU drivers -> "
				ewarn "      AMD GPU -> "
				ewarn "        HSA kernel driver for AMD GPU support (CONFIG_HSA_AMD)"
				ewarn "          Enable SVM support (CONFIG_HSA_AMD_SVM)"
				ewarn ""
			fi
		fi
	fi
}

# Unpack sources and handle go module dependencies
src_unpack() {
	# ROCm requires special flag handling to avoid LTO issues (bug #963401)
	if use rocm; then
		# Strip unsupported compiler flags before compilation
		strip-unsupported-flags
		# Test and apply only valid HIPCXX flags
		export CXXFLAGS="$(test-flags-HIPCXX "${CXXFLAGS}")"
	fi

	if [[ "${PV}" == *9999* ]]; then
		# Live ebuild: clone git repo and vendor go modules
		git-r3_src_unpack
		go-module_live_vendor
	else
		# Release ebuild: extract tarball with pre-vendored go modules
		go-module_src_unpack
	fi
}

# Prepare sources: apply patches and configure build system
src_prepare() {
	cmake_src_prepare

	# Disable ccache as it can cause issues with CUDA/ROCm compilation
	# Remove problematic pre-include directives that bundle headers
	sed \
		-e "/set(GGML_CCACHE/s/ON/OFF/g" \
		-e "/PRE_INCLUDE_REGEXES.*cu/d" \
		-e "/PRE_INCLUDE_REGEXES.*hip/d" \
		-i CMakeLists.txt || die "Failed to patch CMakeLists.txt"

	# Remove hardcoded -O3 optimization flag to respect user's CFLAGS
	sed \
		-e "s/ -O3//g" \
		-i ml/backend/ggml/ggml/src/ggml-cpu/cpu.go \
		|| die "Failed to remove hardcoded -O3 flag"

	# Fix library installation paths to respect get_libdir (lib vs lib64)
	# This ensures proper multilib support
	sed \
		-e "s/\"..\", \"lib\"/\"..\", \"$(get_libdir)\"/" \
		-e "s#\"lib/ollama\"#\"$(get_libdir)/ollama\"#" \
		-i \
			ml/backend/ggml/ggml/src/ggml.go \
			ml/path.go \
		|| die "Failed to fix library paths"

	# Conditionally disable CPU backend variants based on instruction set support
	# This prevents building variants that can't run on the target CPU
	if use amd64; then
		# SSE 4.2 only (Nehalem and later, 2008+)
		if ! use cpu_flags_x86_sse4_2; then
			sed -e "/ggml_add_cpu_backend_variant(sse42/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
		
		# SSE4.2 + AVX (Sandy Bridge, 2011+)
		if ! use cpu_flags_x86_sse4_2 || ! use cpu_flags_x86_avx; then
			sed -e "/ggml_add_cpu_backend_variant(sandybridge/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
		
		# Haswell instruction set (Haswell/Broadwell, 2013+)
		# Requires: SSE4.2, AVX, F16C, AVX2, BMI2, FMA3
		if ! use cpu_flags_x86_sse4_2 || \
		   ! use cpu_flags_x86_avx || \
		   ! use cpu_flags_x86_f16c || \
		   ! use cpu_flags_x86_avx2 || \
		   ! use cpu_flags_x86_bmi2 || \
		   ! use cpu_flags_x86_fma3; then
			sed -e "/ggml_add_cpu_backend_variant(haswell/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
		
		# Skylake-X instruction set (Skylake-X/Cascade Lake, 2017+)
		# Adds: AVX-512F
		if ! use cpu_flags_x86_sse4_2 || \
		   ! use cpu_flags_x86_avx || \
		   ! use cpu_flags_x86_f16c || \
		   ! use cpu_flags_x86_avx2 || \
		   ! use cpu_flags_x86_bmi2 || \
		   ! use cpu_flags_x86_fma3 || \
		   ! use cpu_flags_x86_avx512f; then
			sed -e "/ggml_add_cpu_backend_variant(skylakex/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
		
		# Ice Lake instruction set (Ice Lake, 2019+)
		# Adds: AVX512_VBMI, AVX512_VNNI
		if ! use cpu_flags_x86_sse4_2 || \
		   ! use cpu_flags_x86_avx || \
		   ! use cpu_flags_x86_f16c || \
		   ! use cpu_flags_x86_avx2 || \
		   ! use cpu_flags_x86_bmi2 || \
		   ! use cpu_flags_x86_fma3 || \
		   ! use cpu_flags_x86_avx512f || \
		   ! use cpu_flags_x86_avx512vbmi || \
		   ! use cpu_flags_x86_avx512_vnni; then
			sed -e "/ggml_add_cpu_backend_variant(icelake/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
		
		# Alder Lake instruction set (Alder Lake, 2021+)
		# Uses AVX_VNNI instead of AVX-512
		if ! use cpu_flags_x86_sse4_2 || \
		   ! use cpu_flags_x86_avx || \
		   ! use cpu_flags_x86_f16c || \
		   ! use cpu_flags_x86_avx2 || \
		   ! use cpu_flags_x86_bmi2 || \
		   ! use cpu_flags_x86_fma3 || \
		   ! use cpu_flags_x86_avx_vnni; then
			sed -e "/ggml_add_cpu_backend_variant(alderlake/s/^/# /" \
				-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
		fi
	fi

	# CUDA-specific preparation
	if use cuda; then
		cuda_src_prepare
	fi

	# ROCm-specific preparation
	if use rocm; then
		# Workaround: --hip-version flag causes compilation failures
		# The flag gets passed but isn't recognized, triggering -Werror
		# Nuclear option: strip all -Werror flags from go module files
		find "${S}" -name "*.go" -exec sed -i "s/ -Werror / /g" {} + \
			|| die "Failed to strip -Werror flags for ROCm build"
	fi
}

# Configure build system with appropriate backends and optimizations
src_configure() {
	local mycmakeargs=(
		# Disable ccache to avoid caching issues with CUDA/ROCm
		-DGGML_CCACHE="no"
		
		# Enable BLAS acceleration if requested
		-DGGML_BLAS="$(usex blas)"
		
		# Vulkan support for GPU acceleration
		"$(cmake_use_find_package vulkan Vulkan)"
	)

	# Configure BLAS vendor
	if use blas; then
		if use mkl; then
			mycmakeargs+=(
				-DGGML_BLAS_VENDOR="Intel"
			)
		else
			mycmakeargs+=(
				-DGGML_BLAS_VENDOR="Generic"
			)
		fi
	fi

	# CUDA configuration
	if use cuda; then
		# Set CUDA host compiler to GCC from cuda eclass
		local -x CUDAHOSTCXX CUDAHOSTLD
		CUDAHOSTCXX="$(cuda_gccdir)"
		CUDAHOSTLD="$(tc-getCXX)"

		# Add sandbox exceptions for CUDA device access
		cuda_add_sandbox -w
		addpredict "/dev/char/"
	else
		# Explicitly disable CUDA if not enabled
		mycmakeargs+=(
			-DCMAKE_CUDA_COMPILER="NOTFOUND"
		)
	fi

	# ROCm/HIP configuration
	if use rocm; then
		mycmakeargs+=(
			# Set target GPU architectures from AMDGPU_TARGETS
			-DCMAKE_HIP_ARCHITECTURES="$(get_amdgpu_flags)"
			-DCMAKE_HIP_PLATFORM="amd"
			# Ollama requires explicit AMDGPU_TARGETS (doesn't honor CMAKE_HIP_ARCHITECTURES)
			-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		)

		# Set HIP installation path
		local -x HIP_PATH="${ESYSROOT}/usr"
		
		# Validate AMDGPU_TARGETS is set
		check_amdgpu
	else
		# Explicitly disable HIP if ROCm not enabled
		mycmakeargs+=(
			-DCMAKE_HIP_COMPILER="NOTFOUND"
		)
	fi

	cmake_src_configure
}

# Compile the ollama binary and native backends
src_compile() {
	# Determine version string for embedding in binary
	local VERSION
	if [[ "${PV}" == *9999* ]]; then
		# Live ebuild: try to get git version, fallback to PVR
		if [[ -d "${S}/.git" ]]; then
			VERSION="$(
				git -C "${S}" describe --tags --first-parent --abbrev=7 --long --dirty --always 2>/dev/null \
				| sed -e "s/^v//g"
			)" || VERSION="${PVR}"
		else
			VERSION="${PVR}"
		fi
	else
		# Release ebuild: use Package Version-Revision
		VERSION="${PVR}"
	fi

	# Build Go binary with version information embedded
	local EXTRA_GOFLAGS_LD=(
		# Inject version information into binary
		"-X=github.com/ollama/ollama/version.Version=${VERSION}"
		"-X=github.com/ollama/ollama/server.mode=release"
	)
	GOFLAGS+=" '-ldflags=${EXTRA_GOFLAGS_LD[*]}'"

	# Build Go binary
	ego build

	# Build native C++/CUDA/ROCm backends
	cmake_src_compile
}

# Install compiled files and system integration
src_install() {
	# Install ollama binary
	dobin ollama

	# Install native libraries and backends
	cmake_src_install

	# Install OpenRC init script and configuration
	newinitd "${FILESDIR}/ollama.init" "${PN}"
	newconfd "${FILESDIR}/ollama.confd" "${PN}"

	# Install systemd service unit
	systemd_dounit "${FILESDIR}/ollama.service"
}

# Pre-installation setup: create directories with correct permissions
pkg_preinst() {
	# Create log directory with restricted permissions
	keepdir /var/log/ollama
	fperms 750 /var/log/ollama
	fowners "${PN}:${PN}" /var/log/ollama
}

# Post-installation messages and information
pkg_postinst() {
	# Show quick start guide only on fresh install
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		einfo ""
		einfo "Quick Start Guide:"
		einfo "  1. Start the ollama service:"
		einfo "     OpenRC:  rc-service ollama start"
		einfo "     systemd: systemctl start ollama"
		einfo ""
		einfo "  2. Pull and run a model:"
		einfo "     ollama run llama3:70b"
		einfo ""
		einfo "Browse available models at: https://ollama.com/library"
		einfo ""
	fi

	# Important information for CUDA users
	if use cuda; then
		einfo ""
		einfo "CUDA Configuration:"
		einfo "  Users running ollama must be in the 'video' group to access GPU devices."
		einfo "  The ollama system user is automatically added to this group via"
		einfo "  acct-user/ollama[cuda]."
		einfo ""
		einfo "  To run ollama as your user:"
		einfo "    usermod -aG video <your-username>"
		einfo "    # Then log out and back in"
		einfo ""
	fi

	# Important information for ROCm users
	if use rocm; then
		einfo ""
		einfo "ROCm Configuration:"
		einfo "  Verify your GPU is detected:"
		einfo "    rocminfo"
		einfo ""
		einfo "  If you encounter issues, ensure:"
		einfo "    - HSA_AMD_SVM is enabled in your kernel (see warnings above)"
		einfo "    - Your GPU is supported: https://rocm.docs.amd.com/en/latest/release/gpu_os_support.html"
		einfo "    - ROCm runtime is properly configured"
		einfo ""
	fi
}