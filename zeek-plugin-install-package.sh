#! /bin/sh
#
# Helper script to install the tarball with a plugin's binary distribution.
#
# Called from ZeekPluginDynamic.cmake. Current directory is the plugin
# build directory.

if [ $# != 2 ]; then
    echo "usage: $(basename $0) <canonical plugin name> <destination directory>"
    exit 1
fi

dst=$2

if [ ! -d "${dst}" ]; then
    echo "Warning: ${dst} does not exist; has Zeek been installed?"
    mkdir -p ${dst}
fi

name=$1
tgz=$(pwd)/$name.tgz

(cd ${dst} && rm -rf "${name}" && tar xzf ${tgz})
