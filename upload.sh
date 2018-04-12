#!/bin/bash

# This file will upload built artifact to CDN

file=$1
target=$2

ost=`uname -u`
os=

if [ "$ost" == "Linux" ]; then
    os="linux"
elif [ "$ost" == "Darwin" ]; then
    os="darwin"
else
    echo "Unsupported operating system: $ost"
    exit 10
fi

if [ -z "$file" ]; then
    echo "File was not specified"
    exit 11
fi

if [ -z "$target" ]; then
    echo "Target CDN was not specified"
    exit 12
fi

if [ "$target" != "master" ] && [ "$target" != "dev" ] && [ "$target" != "HEAD" ]; then
    echo "Specified target is unsupported: $target"
    exit 13
fi

if [ ! -e "$file" ]; then
    echo "File doesn't exists: $file"
    exit 14
fi


extract_id()
{
    if [ "$os" == "linux" ]; then
        id_src=$(echo $json | grep -Po '"id":".*?[^\\]"')
        id=${id_src:6:36}
    elif [ "$os" == "darwin" ]; then
        id_src=$(echo $json | grep -Po '"id":".*?[^\\]"')
        id=${id_src:6:36}
    else
        echo "Can't extract ID of a file: Unknown OS"
    fi
}

