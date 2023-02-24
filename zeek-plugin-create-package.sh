#!/bin/sh
#
# Helper script creating a tarball with a plugin's binary distribution. We'll
# also leave a MANIFEST in place with all files part of the tar ball.
#
# Called from ZeekPluginDynamic.cmake. Current directory is the plugin
# build directory.

if [ $# = 0 ]; then
    echo "usage: $(basename "$0") <canonical plugin name> [<additional files to include into binary distribution>]"
    exit 1
fi

name=$1
shift
addl=$*

DIST=dist/${name}
mkdir -p "${DIST}"

# Copy files to be distributed to temporary location.
cp -rL __bro_plugin__ lib scripts "${DIST}"
for i in ${addl}; do
    if [ -e "../$i" ]; then
        dir=$(dirname "$i")
        mkdir -p "${DIST}/${dir}"
        cp -p "../$i" "${DIST}/${dir}"
    fi
done

tgz=${name}-$( (test -e ../VERSION && head -1 ../VERSION) || echo 0.0).tar.gz

rm -f "${name}".tgz "${tgz}"

tar czf "dist/${tgz}" -C dist "${name}"

rm -rf "${DIST}"

ln -s "dist/${tgz}" "${name}.tgz"
