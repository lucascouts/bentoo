# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit check-reqs systemd tmpfiles

DESCRIPTION="Get up and running with large language models locally"
HOMEPAGE="https://ollama.com/"

# GitHub releases provide pre-built binaries for multiple architectures
SRC_URI="
	amd64? (
		!rocm? ( https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-amd64.tgz -> ${P}-amd64.tgz )
		rocm? ( https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-amd64-rocm.tgz -> ${P}-rocm.tgz )
	)
	arm64? ( https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-arm64.tgz -> ${P}-arm64.tgz )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="cuda rocm systemd"

# ROCm is only available on amd64
REQUIRED_USE="
	rocm? ( amd64 )
	cuda? ( amd64 )
"

# Binary redistribution is permitted under MIT license
# We restrict mirroring to respect upstream's distribution preferences
# Strip is restricted because these are pre-built binaries
RESTRICT="mirror strip"

# Temporary directory for extraction
S="${WORKDIR}"

# Disk space check - Ollama models can be large
CHECKREQS_DISK_BUILD="4G"

# All files are pre-built binaries, skip QA checks
QA_PREBUILT="*"

# Runtime dependencies only - these are pre-built binaries
RDEPEND="
	acct-group/ollama
	acct-user/ollama
	cuda? ( dev-util/nvidia-cuda-toolkit )
	rocm? (
		dev-libs/rocm-opencl-runtime
		sci-libs/clblast
	)
"

# No build-time dependencies for binary package
DEPEND=""

# systemd only needed if USE flag is enabled
BDEPEND="systemd? ( sys-apps/systemd )"

pkg_pretend() {
	# Check disk space requirements early
	check-reqs_pkg_pretend

	# Warn about experimental GPU support
	if use rocm; then
		ewarn ""
		ewarn "ROCm (AMD GPU) support is experimental and may not work on all hardware."
		ewarn "Supported AMD GPUs: Radeon RX 6000 series and newer, or Radeon VII."
		ewarn ""
		ewarn "If you encounter issues, please refer to:"
		ewarn "  https://rocm.docs.amd.com/projects/install-on-linux/en/latest/"
		ewarn ""
	fi

	if use cuda; then
		ewarn ""
		ewarn "CUDA (NVIDIA GPU) support requires compatible NVIDIA drivers."
		ewarn "Minimum compute capability: 6.0 (Pascal architecture and newer)."
		ewarn ""
	fi
}

pkg_setup() {
	# Verify disk space requirements
	check-reqs_pkg_setup
}

src_unpack() {
	# Unpack the appropriate tarball based on architecture and USE flags
	# ROCm variant takes precedence over standard amd64 build
	if use amd64; then
		if use rocm; then
			unpack "${P}-rocm.tgz"
		else
			unpack "${P}-amd64.tgz"
		fi
	elif use arm64; then
		unpack "${P}-arm64.tgz"
	fi
}

src_prepare() {
	# Apply any user patches if present
	default
}

src_install() {
	# Install the main binary
	exeinto /opt/ollama/bin
	doexe bin/ollama

	# Install bundled libraries
	# These are required for GPU acceleration and may not match system libraries
	insinto /opt/ollama/lib
	doins -r lib/*

	# Create convenience symlink in standard PATH
	dosym -r /opt/ollama/bin/ollama /usr/bin/ollama

	# Install systemd service file
	if use systemd; then
		systemd_dounit "${FILESDIR}"/ollama.service
		# Install systemd-tmpfiles configuration
		dotmpfiles "${FILESDIR}"/ollama.conf
	fi

	# Install OpenRC init script
	newinitd "${FILESDIR}"/ollama.initd ollama
	newconfd "${FILESDIR}"/ollama.confd ollama

	# Create state directory for models and configuration
	keepdir /var/lib/ollama
	fowners ollama:ollama /var/lib/ollama
	fperms 0750 /var/lib/ollama

	# Create log directory
	keepdir /var/log/ollama
	fowners ollama:ollama /var/log/ollama
	fperms 0750 /var/log/ollama

	# Install documentation
	dodoc "${FILESDIR}"/README.gentoo
}

pkg_preinst() {
	# Preserve any existing models and configuration
	if [[ -d "${EROOT}"/var/lib/ollama ]]; then
		einfo "Preserving existing Ollama data in /var/lib/ollama"
	fi
}

pkg_postinst() {
	# Rebuild systemd-tmpfiles if systemd is running
	if use systemd; then
		tmpfiles_process ollama.conf
	fi

	elog ""
	elog "Ollama has been installed successfully!"
	elog ""
	elog "Quick Start Guide:"
	elog "=================="
	elog ""
	elog "1. Start the Ollama service:"
	
	if use systemd; then
		elog "   systemctl enable --now ollama"
		elog ""
		elog "   Or run manually:"
		elog "   systemctl start ollama"
	else
		elog "   rc-service ollama start"
		elog "   rc-update add ollama default  # Enable at boot"
		elog ""
		elog "   Or run manually:"
		elog "   ollama serve"
	fi
	
	elog ""
	elog "2. Download and run a model:"
	elog "   ollama run llama3.2:3b"
	elog ""
	elog "3. List available models:"
	elog "   ollama list"
	elog ""
	elog "4. Browse the model library:"
	elog "   https://ollama.com/library"
	elog ""
	
	if use cuda; then
		elog "NVIDIA CUDA Support:"
		elog "  - CUDA toolkit detected"
		elog "  - Ollama will automatically use NVIDIA GPUs"
		elog "  - Set CUDA_VISIBLE_DEVICES to control GPU selection"
		elog ""
	fi
	
	if use rocm; then
		elog "AMD ROCm Support:"
		elog "  - ROCm libraries detected"
		elog "  - Set HSA_OVERRIDE_GFX_VERSION if needed for your GPU"
		elog "  - Example: HSA_OVERRIDE_GFX_VERSION=10.3.0 for Radeon RX 6000"
		elog ""
	fi
	
	elog "Configuration:"
	elog "  - Models are stored in: /var/lib/ollama"
	elog "  - Logs are written to: /var/log/ollama"
	elog "  - Default API endpoint: http://localhost:11434"
	elog ""
	elog "Environment Variables:"
	elog "  OLLAMA_HOST     - Bind address (default: 127.0.0.1:11434)"
	elog "  OLLAMA_MODELS   - Model storage path"
	elog "  OLLAMA_KEEP_ALIVE - Model memory retention time"
	elog "  OLLAMA_NUM_PARALLEL - Number of parallel requests"
	elog ""
	
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		elog "First-time Installation:"
		elog "  Add your user to the ollama group to access the service:"
		elog "    usermod -aG ollama YOUR_USERNAME"
		elog "  Then log out and back in for changes to take effect."
		elog ""
	fi
	
	elog "For more information:"
	elog "  - Documentation: https://github.com/ollama/ollama/tree/main/docs"
	elog "  - API reference: https://github.com/ollama/ollama/blob/main/docs/api.md"
	elog ""
}

pkg_postrm() {
	elog ""
	elog "Ollama has been removed."
	elog ""
	elog "Note: Models and configuration in /var/lib/ollama were preserved."
	elog "To completely remove Ollama data:"
	elog "  rm -rf /var/lib/ollama"
	elog ""
}
