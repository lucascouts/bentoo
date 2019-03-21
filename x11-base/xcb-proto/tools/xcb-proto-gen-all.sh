#!/bin/sh

OUTDIR="../../x11-proto"
STUBREV="-r1000"

xp_manifest=""

for eb in xcb-proto-*.ebuild ; do
	leb="${eb}"
	ppkg="${eb/%.ebuild/}"
	ppkg="${ppkg##*/}"
	ppkgver="${ppkg#xcb-proto-}"
	xcbebpre="../../x11-libs/libxcb/libxcb-${ppkgver}"
	xcbeblst="$(echo $"{xcbebpre}"*.ebuild)"
	if [ "${xcbebpre}*.ebuild" = "${xcbeblst}" ] ; then
		echo "Matching library x11-libs/libxcb-${ppkgver}* does not exist! Bailing out!"
		exit 1
	fi
	proto="${ppkg}"
	protoname="xcb-proto"
	protover="${proto#${protoname}}"
	protodir="${OUTDIR}/${protoname}"
	mkdir -p "${protodir}"
	protoebuild="${protodir}/${proto}${STUBREV}.ebuild"
	printf -- "Writing stub ebuild '${protoebuild}.'\n"
	cat > "${protoebuild}" \
<<EOF
# Distributed under the terms of the GNU General Public License v2
EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit python-r1 multilib-minimal

DESCRIPTION="x11-proto/xcb-proto package stub (provided by ${ppkg%-${ppkgver}})."

KEYWORDS="*"

SLOT="0"

RDEPEND="=x11-base/${ppkg}[\${MULTILIB_USEDEP}]"
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

ebuild "${leb}" manifest
