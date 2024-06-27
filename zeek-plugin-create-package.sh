#!/bin/sh
#
# Helper script creating a tarball with a plugin's binary distribution. We'll
# also leave a MANIFEST in place with all files part of the tar ball.
#
# Called from ZeekPluginDynamic.cmake. Current directory is the plugin
# build directory.

if [ $# -ne 1 ]; then
    echo "usage: $(basename "$0") <canonical plugin name>"
    exit 1
fi

name=$1
shift

DIST=dist/${name}
mkdir -p "${DIST}"

# Copy files to be distributed to temporary location.
cp -RL __zeek_plugin__ lib scripts "${DIST}"

tgz=${name}-$( (test -e ../VERSION && head -1 ../VERSION) || echo 0.0).tar.gz

rm -f "${name}".tgz "${tgz}"

tar czf "dist/${tgz}" -C dist "${name}"

rm -rf "${DIST}"

ln -s "dist/${tgz}" "${name}.tgz"
