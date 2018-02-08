#!/bin/bash

location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
p2p_binary=$1
branch=$2
if [ ! -f "$p2p_binary" ]; then
    echo "Couldn't find specified file: $p2p_binary"
    exit 1
fi
chmod +x $p2p_binary
version_number=`$p2p_binary -v`

postfix=""
if [ "$branch" == "master" ]; then
    postfix="-master"
elif [ "$branch" == "dev" ]; then
    postfix="-dev"
elif [ "$branch" == "sysnet" ]; then
    postfix="-sysnet"
fi


# clean
rm -rf $location/flat
rm -rf $location/root
rm -f $location/*.pkg
# Copy files
mkdir -p $location/flat/Resources/en.lproj
mkdir -p $location/flat/base.pkg
mkdir -p $location/root/bin
mkdir -p $location/root/Library/LaunchDaemons
mkdir -p $location/root/etc/newsyslog.d
mkdir -p $location/root/Applications/SubutaiP2P.app/Contents/MacOS
mkdir -p $location/root/Applications/SubutaiP2P.app/Contents/PlugIns
mkdir -p $location/root/Applications/SubutaiP2P.app/Contents/Resources

cp $p2p_binary $location/root/Applications/SubutaiP2P.app/Contents/MacOS/SubutaiP2P
cp $p2p_binary $location/root/bin/p2p
cp $location/io.subutai.p2p.daemon.plist.tmpl $location/root/Library/LaunchDaemons/io.subutai.p2p.daemon.plist
cp $location/p2p.conf.tmpl $location/root/etc/newsyslog.d/p2p.conf

cp $location/PkgInfo.tmpl $location/root/Applications/SubutaiP2P.app/Contents/PkgInfo
cp $location/Info.plist.tmpl $location/root/Applications/SubutaiP2P.app/Contents/Info.plist

# Determine sizes and modify PackageInfo
rootfiles=`find $location/root | wc -l`
rootsize=`du -s $location/root | awk '{print $1}'`
mbsize=$(( ${rootsize%% *} / 1024 ))

echo "Size: $rootsize"
echo "MBSize: $mbsize"

cp $location/PackageInfo.tmpl $location/flat/base.pkg/PackageInfo
sed -i -e "s/{VERSION_PLACEHOLDER}/$version_number/g" $location/flat/base.pkg/PackageInfo
sed -i -e "s/{SIZE_PLACEHOLDER}/$mbsize/g" $location/flat/base.pkg/PackageInfo
sed -i -e "s/{FILES_PLACEHOLDER}/$rootfiles/g" $location/flat/base.pkg/PackageInfo

# modify Distribution
cp $location/Distribution.tmpl $location/flat/Distribution
sed -i -e "s/{VERSION_PLACEHOLDER}/$version_number/g" $location/flat/Distribution
sed -i -e "s/{SIZE_PLACEHOLDER}/$mbsize/g" $location/flat/Distribution

# Pack and bom
( cd $location/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $location/flat/base.pkg/Payload
( cd $location/scripts && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $location/flat/base.pkg/Scripts
mkbom -u 0 -g 80 $location/root $location/flat/base.pkg/Bom
( cd $location/flat && xar --compression none -cf "/tmp/p2p-packages/darwin/p2p.pkg" * )
