#!/bin/sh

OUTDIR="../../x11-proto"
STUBREV="-r1001"

xp_manifest=""

for eb in xorg-proto-*.ebuild ; do
	
	ppkgr="${eb/%.ebuild/}"
	ppkgf="${ppkgr##*/}"
	ppkg="${ppkgf%-r*}"
	ppkgverf="${ppkg#xorg-proto-}"
	ppkgver="${ppkgverf%-r*}"
	
	# We only need to generate the manifest for xorg-proto once.
	[ -z "$xp_manifest" ] && ( ebuild "${eb}" manifest 2>&1 ) > /dev/null && xp_manifest="${eb}"
	ebuild "${eb}" clean unpack

	pushd ~portage/x11-base/${ppkgf}/work
		if [ -d "${ppkg}" ] ; then cd "${ppkg}"
		elif [ -d "xorgproto-${ppkgver}" ] ; then cd "xorgproto-${ppkgver}"
		else printf --  "Can't figure out location of sources for ${eb}, skipping!" ; continue ; fi
		if ! [ -e meson.build ] ; then printf -- "No meson.build file found for ${eb}, skipping!" ; continue ; fi
		pkgs="$(cat meson.build | sed -n '/^pcs = \[/,/^\]/ { s/'"'"',[[:space:]]*'"'"'/-/ ; s/'"'"'],//; s/.*\['"'"'// p};')"
		pkgs_legacy="$(cat meson.build | sed -n '/^[[:space:]]*legacy_pcs = \[/,/^[[:space:]]*\]/ { s/'"'"',[[:space:]]*'"'"'/-/ ; s/'"'"'],//; s/.*\['"'"'// p};')"
	popd

	for proto in ${pkgs} ${pkgs_legacy} ; do

		protoname="${proto%-[0-9]*}"
		protover="${proto#${protoname}}"
		protodir="${OUTDIR}/${protoname}"
		mkdir -p "${protodir}"
		protoebuild="${protodir}/${proto}${STUBREV}.ebuild"
		# If we've already created the stub, add the current xorg-proto as a provider and continue from the top.
		if [ -e "${protoebuild}" ] && ! grep -q "x11-base/${ppkgf}" "${protoebuild}" ; then
			printf -- "Adding ${ppkgf} as provider to ebuild '${protoebuild}'.\n"
			sed -e 's:RDEPEND=" || (:&\n\t=x11-base/'"${ppkgf}:" -i "${protoebuild}"
			continue
		fi
		printf -- "Writing stub ebuild '${protoebuild}.'\n"
		cat > "${protoebuild}" \
<<EOF
# Distributed under the terms of the GNU General Public License v2
EAPI=6

inherit multilib-minimal

DESCRIPTION="X.Org Protocol ${proto} package stub (provided by ${ppkg%-${ppkgver}})."

KEYWORDS="*"

SLOT="0"

RDEPEND=" || (
	=x11-base/${ppkgf}
)"
DEPEND="\${RDEPEND}"

S="\${WORKDIR}"

multilib_src_configure() { return 0; }
src_configure() { return 0; }
multilib_src_compile() { return 0; }
src_compile() { return 0; }
multilib_src_install() { return 0; }
src_install() { return 0; }

EOF

		ebuild "${protoebuild}" manifest
	done
	al=""
	a=""
	for pl in ${pkgs_legacy} ; do al="${al}${al:+ }x11-proto/${pl}${STUBREV}" ; done
	for p in ${pkgs} ; do a="${a}${a:+ }x11-proto/${p}${STUBREV}" ; done

	
	printf -- "\nUpdating '${eb}'.\n"
	sed -e '/LEGACY_BLOCKS="/,/"/ d ; /RDEPEND="/,/"/ d ' -i "${eb}"

	printf -- "LEGACY_BLOCKS=\"" >> "${eb}"
	for pl in ${al} ; do printf -- "\n\t!<${pl}" >> "${eb}" ; done
	printf -- '"\n' >> "${eb}"
	printf -- "RDEPEND=\"legacy? ( \${LEGACY_BLOCKS} )" >> "${eb}"
	for p in ${a} ; do printf -- "\n\t!<${p}" >> "${eb}" ; done
	printf -- '"\n' >> "${eb}"

	sed -e '/LEGACY_DEPS="/,/"/ d ; /PDEPEND="/,/"/ d ' -i "${eb}"
	printf -- "LEGACY_DEPS=\"" >> "${eb}"
	for pl in ${al} ; do printf -- "\n\t=${pl}" >> "${eb}" ; done
	printf -- '"\n' >> "${eb}"
	printf -- "PDEPEND=\"legacy? ( \${LEGACY_DEPS} )" >> "${eb}"
	for p in ${a} ; do printf -- "\n\t=${p}" >> "${eb}" ; done
	printf -- '"\n' >> "${eb}"

	ebuild "${eb}" manifest
done

