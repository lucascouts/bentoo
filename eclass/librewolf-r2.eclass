# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: librewolf-r2.eclass
# @MAINTAINER:
# aidanharris
# @AUTHOR:
# aidanharris
# @BLURB:
# @DESCRIPTION: librewolf customisation/configuration

if [[ ! ${_LIBREWOLF_R2} ]]; then

inherit git-r3

librewolf-r1_src_configure() {
local _PN="LibreWolf"
[[ "${PN}" == "librewolf-nightly" ]] && _PN="${_PN}-Nightly"
# stolen from the AUR PKGBUILD with irrelevant options removed (here irrelvant means the feature is controlled via a useflag so there's no need to unconditionally enable/disable it here. Only the common options we want to always apply are listed here)
cat >> "${S}/.mozconfig" <<END
ac_add_options --enable-application=browser

ac_add_options --prefix=/usr
ac_add_options --enable-release
ac_add_options --enable-hardening
ac_add_options --enable-rust-simd

# Branding
ac_add_options --enable-update-channel=release
ac_add_options --with-app-name='${PN}'
ac_add_options --with-app-basename='${_PN}'
ac_add_options --with-branding=browser/branding/${PN}
ac_add_options --with-distribution-id=io.gitlab.${PN}
ac_add_options --with-unsigned-addon-scopes=app,system
ac_add_options --allow-addon-sideload
export MOZ_REQUIRE_SIGNING=

# Features
ac_add_options --disable-crashreporter
ac_add_options --disable-updater

# Disables crash reporting, telemetry and other data gathering tools
mk_add_options MOZ_CRASHREPORTER=0
mk_add_options MOZ_DATA_REPORTING=0
mk_add_options MOZ_SERVICES_HEALTHREPORT=0
mk_add_options MOZ_TELEMETRY_REPORTING=0
END

  # Remove some pre-installed addons that might be questionable
  eapply "${WORKDIR}/patches/remove_addons.patch"

  # Disable (some) megabar functionality
  # Adapted from https://github.com/WesleyBranton/userChrome.css-Customizations
  eapply "${WORKDIR}/patches/megabar.patch"

  # Disabling Pocket
  sed -i "s/'pocket'/#'pocket'/g" "${S}"/browser/components/moz.build

  eapply "${WORKDIR}/patches/context-menu.patch"

  # Remove mozilla vpn ads
  eapply "${WORKDIR}/patches/mozilla-vpn-ad.patch"

  # Prevent creation of '.mozilla' (Will need to be symlinked for some browser plugins)
  eapply "${WORKDIR}/patches/mozilla_dirs.patch"

  # this one only to remove an annoying error message:
  sed -i 's#SaveToPocket.init();#// SaveToPocket.init();#g' "${S}"/browser/components/BrowserGlue.jsm

  # Remove Internal Plugin Certificates
  _cert_sed='s#if (aCert.organizationalUnit == "Mozilla [[:alpha:]]\+") {\n'
  _cert_sed+='[[:blank:]]\+return AddonManager\.SIGNEDSTATE_[[:upper:]]\+;\n'
  _cert_sed+='[[:blank:]]\+}#'
  _cert_sed+='// NOTE: removed#g'
  sed -z "$_cert_sed" -i "${S}"/toolkit/mozapps/extensions/internal/XPIInstall.jsm

  # allow SearchEngines option in non-ESR builds
  sed -i 's#"enterprise_only": true,#"enterprise_only": false,#g' "${S}"/browser/components/enterprisepolicies/schemas/policies-schema.json

  _settings_services_sed='s#firefox.settings.services.mozilla.com#f.s.s.m.c.qjz9zk#g'

  # stop some undesired requests (https://gitlab.com/librewolf-community/browser/common/-/issues/10)
  sed "$_settings_services_sed" -i "${S}"/browser/components/newtab/data/content/activity-stream.bundle.js
  sed "$_settings_services_sed" -i "${S}"/modules/libpref/init/all.js
  sed "$_settings_services_sed" -i "${S}"/services/settings/Utils.jsm
  sed "$_settings_services_sed" -i "${S}"/toolkit/components/search/SearchUtils.jsm

  rm -f ${WORKDIR}/common/source_files/mozconfig
  cp -r ${WORKDIR}/common/source_files/* "${S}"/
  if [[ "$PN" == "librewolf-nightly" ]]
  then
	  # This makes it so librewolf-nightly can be installed alongside librewolf using a different profile so things don't conflict
	  mv "${S}/browser/branding/librewolf"  "${S}/browser/branding/librewolf-nightly"
	  eapply "${FILESDIR}/librewolf-nightly-branding.diff"
  fi
}

librewolf-r1_src_unpack() {
	if [[ "$PN" == "librewolf-nightly" ]]
	then
		mercurial_src_unpack
	fi

	git-r3_fetch "https://gitlab.com/librewolf-community/browser/common.git" \
				 "v${LIBREWOLF_PV}"
	git-r3_checkout "https://gitlab.com/librewolf-community/browser/common.git" \
					"${WORKDIR}/common"

	git-r3_fetch "https://gitlab.com/librewolf-community/settings.git"
	git-r3_checkout "https://gitlab.com/librewolf-community/settings.git" \
					"${WORKDIR}/settings"

	# Grab patches
	# pre-89 patches can be grabed from the 'linux' librewolf repository
	# after 89 patches were moved to 'common'
	patch_list=(
		"remove_addons.patch"
		"megabar.patch"
		"context-menu.patch"
		"mozilla-vpn-ad.patch"
		"mozilla_dirs.patch"
	)

	if ver_test -lt "89.0"; then
		git-r3_fetch "https://gitlab.com/librewolf-community/browser/linux.git" \
			"v${LIBREWOLF_PV}"
		git-r3_checkout "https://gitlab.com/librewolf-community/browser/linux.git" \
			"${WORKDIR}/linux"

		mkdir "${WORKDIR}/patches"

		for patch in ${patch_list[@]}; do
			cp "${WORKDIR}/linux/${patch}" "${WORKDIR}/patches"
		done
	else
		mkdir "${WORKDIR}/patches"
		for patch in ${patch_list[@]}; do
			cp "${WORKDIR}/common/patches/${patch}" "${WORKDIR}/patches"
		done
	fi
}

librewolf-r1_src_install() {
  local vendorjs="$ED/usr/$(get_libdir)/${PN}/browser/defaults/preferences/vendor.js"

  cat >> "$vendorjs" <<END
// Use system-provided dictionaries
pref("spellchecker.dictionary_path", "/usr/share/hunspell");

// Don't disable extensions in the application directory
// done in librewolf.cf
// pref("extensions.autoDisableScopes", 11);
END

  cp -r ${WORKDIR}/settings/* ${ED}/usr/$(get_libdir)/${PN}/

  local distini="$ED/usr/$(get_libdir)/${PN}/distribution/distribution.ini"
  install -Dvm644 /dev/stdin "$distini" <<END
[Global]
id=io.gitlab.${_pkgname}
version=1.0
about=LibreWolf

[Preferences]
app.distributor="LibreWolf Community"
app.distributor.channel=${PN}
app.partner.librewolf=${PN}
END
}

_LIBREWOLF_R2=1
fi
