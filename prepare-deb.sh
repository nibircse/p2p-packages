#!/bin/bash

# This file will accept branch and path to a deb file and will move
# this file and rename it to acceptable name

branch=$1
path=$2
output_dir=$3

echo "Preparing debian package $path for $branch"
# TODO: Resolve path from a value provided as an argument 
debfile=`ls /tmp/p2p-packages | grep .deb | head -1`

output_file=
if [ "$branch" == "HEAD" ]; then
    output_file=${output_dir}/subutai-p2p.deb
else
    output_file=${output_dir}/subutai-p2p-$branch.deb
fi

mv $debfile $output_file

echo "New debian package path: $output_file"