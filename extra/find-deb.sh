#!/bin/bash

topdir=$1
newfile=$2

filename=`ls $1 | grep .deb | tr -d '\n'`
if [ -e $filename ]; then
    mv $topdir/$filename $newfile
    exit $?
fi
exit 1
