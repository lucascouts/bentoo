# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg bash-completion-r1

BUILD_ID="202508150626"
MY_PN="kiro"

DESCRIPTION="AI IDE that helps you do your best work by turning ideas into production code"
HOMEPAGE="https://kiro.dev/"
SRC_URI="https://prod.download.desktop.kiro.dev/releases/${BUILD_ID}--distro-linux-x64-deb/${BUILD_ID}-distro-linux-x64.deb -> ${MY_PN}-${PV}.deb"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="wayland"

RESTRICT="mirror strip bindist"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.5.3
	app-crypt/libsecret
	>=dev-libs/expat-2.1_beta3
	>=dev-libs/glib-2.37.3:2
	>=dev-libs/nspr-4.9
	>=dev-libs/nss-3.26
	>=media-libs/alsa-lib-1.0.17
	>=media-libs/mesa-17.1.0[gbm(+)]
	>=net-misc/curl-7.0.0
	>=net-print/cups-1.6.0
	>=sys-apps/dbus-1.9.14
	>=sys-apps/util-linux-2.25
	>=x11-libs/cairo-1.6.0
	>=x11-libs/gtk+-3.9.10:3[wayland?]
	>=x11-libs/libdrm-2.4.75
	>=x11-libs/libX11-1.4.99.1
	>=x11-libs/libxcb-1.9.2
	>=x11-libs/libXcomposite-0.4.4
	>=x11-libs/libXdamage-1.1
	x11-libs/libXext
	x11-libs/libXfixes
	>=x11-libs/libxkbcommon-0.5.0
	>=x11-libs/libxkbfile-1.1.0
	x11-libs/libXrandr
	>=x11-libs/pango-1.14.0
	>=x11-misc/xdg-utils-1.0.2
	wayland? ( dev-libs/wayland )
	media-libs/vulkan-loader
"

# QA overrides específicos
QA_PREBUILT="
	opt/kiro/kiro
	opt/kiro/chrome_crashpad_handler
	opt/kiro/chrome-sandbox
	opt/kiro/lib*.so*
"

# Ignorar binários ARM64 nas extensões
QA_PRESTRIPPED="opt/kiro/resources/app/extensions/.*"

S="${WORKDIR}"

src_unpack() {
	unpack_deb ${A}
}

src_prepare() {
	default
	
	# Configurar permissões do chrome-sandbox
	if [[ -f usr/share/kiro/chrome-sandbox ]]; then
		chmod 4755 usr/share/kiro/chrome-sandbox || die
	fi
	
	# Remover arquivos Debian
	rm -rf DEBIAN/ || die
	
	# Remover binários ARM64 para evitar QA warnings
	find usr/share/kiro/resources/app/extensions -name "*arm64*" -type f -delete 2>/dev/null || true
	find usr/share/kiro/resources/app/extensions -name "*aarch64*" -type f -delete 2>/dev/null || true
}

src_install() {
	# Instalar aplicação
	insinto /opt/kiro
	doins -r usr/share/kiro/*
	
	# Tornar executáveis os binários
	fperms +x /opt/kiro/kiro
	fperms +x /opt/kiro/chrome_crashpad_handler
	fperms 4755 /opt/kiro/chrome-sandbox
	
	# Bibliotecas compartilhadas
	local lib
	for lib in usr/share/kiro/lib*.so*; do
		[[ -f "${lib}" ]] && fperms +x "/opt/kiro/${lib##*/}"
	done
	
	# Wrapper script
	exeinto /usr/bin
	newexe - kiro <<-'EOF'
		#!/bin/bash
		
		export ELECTRON_IS_DEV=0
		export ELECTRON_FORCE_IS_PACKAGED=true
		
		declare -a KIRO_ARGS
		
		KIRO_ARGS=(
			--no-sandbox
			--disable-gpu-sandbox
			--disable-software-rasterizer
			--enable-features=VaapiVideoDecoder
		)
		
		# Suporte Wayland
		if [[ -n "${WAYLAND_DISPLAY}" ]] && command -v wayland-scanner >/dev/null 2>&1; then
			KIRO_ARGS+=(
				--ozone-platform=wayland
				--enable-features=UseOzonePlatform
			)
		fi
		
		exec /opt/kiro/kiro "${KIRO_ARGS[@]}" "$@"
	EOF
	
	# Desktop entry - corrigir categorias inválidas
	if [[ -f usr/share/applications/kiro.desktop ]]; then
		sed -i \
			-e 's|/usr/share/kiro/bin/kiro|/usr/bin/kiro|g' \
			-e 's|Categories=.*|Categories=Development;IDE;TextEditor;|g' \
			usr/share/applications/kiro.desktop || die
		domenu usr/share/applications/kiro.desktop
	fi
	
	# URL handler
	if [[ -f usr/share/applications/kiro-url-handler.desktop ]]; then
		sed -i 's|/usr/share/kiro/bin/kiro|/usr/bin/kiro|g' usr/share/applications/kiro-url-handler.desktop || die
		domenu usr/share/applications/kiro-url-handler.desktop
	fi
	
	# Ícone
	if [[ -f usr/share/pixmaps/code-oss.png ]]; then
		newicon usr/share/pixmaps/code-oss.png kiro.png
	fi
	
	# MIME types
	if [[ -f usr/share/mime/packages/kiro-workspace.xml ]]; then
		insinto /usr/share/mime/packages
		doins usr/share/mime/packages/kiro-workspace.xml
	fi
	
	# AppData
	if [[ -f usr/share/appdata/kiro.appdata.xml ]]; then
		insinto /usr/share/metainfo
		newins usr/share/appdata/kiro.appdata.xml dev.kiro.kiro.appdata.xml
	fi
	
	# Shell completions - usar função correta
	if [[ -f usr/share/bash-completion/completions/kiro ]]; then
		dobashcomp usr/share/bash-completion/completions/kiro
	fi
	
	if [[ -f usr/share/zsh/vendor-completions/_kiro ]]; then
		insinto /usr/share/zsh/site-functions
		doins usr/share/zsh/vendor-completions/_kiro
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	
	elog "Kiro IDE ${PV} (build ${BUILD_ID}) instalado com sucesso!"
	elog ""
	elog "Para otimizar a experiência:"
	elog "  • Certifique-se de ter conexão estável para recursos de IA"
	elog "  • Para melhor performance GPU, instale drivers atualizados"
	elog ""
	elog "Configurações: ~/.config/kiro/"
	elog "Documentação: https://kiro.dev/"
	
	if ! groups "${USER}" 2>/dev/null | grep -q video; then
		ewarn "Usuário não está no grupo 'video'."
		ewarn "Execute: usermod -a -G video \${USER}"
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
}