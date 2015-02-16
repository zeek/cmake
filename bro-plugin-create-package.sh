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

tgz=${name}-`(test -e ../VERSION && cat ../VERSION | head -1) || echo 0.0`.tar.gz

rm -f MANIFEST ${name} ${name}.tgz ${tgz}

for i in __bro_plugin__ lib scripts $@; do
    test -e $i && find -L $i -type f | sed "s%^%${name}/%g" >>MANIFEST
done

ln -s . ${name}
tar czf ${tgz} -T MANIFEST
ln -s ${tgz} ${name}.tgz
rm -f ${name}
