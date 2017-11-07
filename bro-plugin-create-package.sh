#! /bin/sh
#
# Helper script creating a tarball with a plugin's binary distribution. We'll
# also leave a MANIFEST in place with all files part of the tar ball.
#
# Called from BroPluginDynamic.cmake. Current directory is the plugin
# build directory.

if [ $# = 0 ]; then
    echo "usage: `basename $0` <canonical plugin name> [<additional files to include into binary distribution>]"
    exit 1
fi

name=$1
shift
addl=$@

# Copy additional distribution files into build directory.
for i in ${addl}; do
    if [ -e ../$i ]; then
        dir=`dirname $i`
        mkdir -p ${dir}
        cp -p ../$i ${dir}
    fi
done

tgz=${name}-`(test -e ../VERSION && cat ../VERSION | head -1) || echo 0.0`.tar.gz

rm -f MANIFEST ${name} ${name}.tgz ${tgz}

for i in __bro_plugin__ lib scripts ${addl}; do
    test -e $i && find -L $i -type f | sed "s%^%${name}/%g" >>MANIFEST
done

ln -s . ${name}
mkdir -p dist

flag="-T"
test `uname` = "OpenBSD" && flag="-I"
tar czf dist/${tgz} ${flag} MANIFEST

ln -s dist/${tgz} ${name}.tgz
rm -f ${name}
