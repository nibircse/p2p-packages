#!/bin/bash

file=$1
branch=$2
postfix=$3

osname=`uname -s`

# Verify all arguments were specified
echo "Deploying for $osname"

if [ -z "$branch" ]; then
    echo "Branch is not specified"
    exit 31
fi

if [ -z "$file" ]; then
    echo "Upload file not specified"
    exit 32
fi

# Verify that branch is correct

if [ "$branch" != "master" ] && [ "$branch" != "dev" ] && [ "$branch" != "HEAD" ]; then
    echo "Branch $branch is unsupported"
    echo 0
fi

# Verify OS and set directory accordingly

if [ "$osname" == "Darwin" ]; then
    expected_location="/tmp/p2p-packages"
elif [ "$osname" == "Linux" ]; then
    expected_location="/tmp/p2p-packages"
else
    expected_location="/c/tmp/p2p-packages"
fi

location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$location" != "$expected_location" ]; then
    echo "Wrong script location: $location"
    exit 1
fi

# ID of the file from Gorjun JSON response
extract_id()
{
    if [ "$osname" == "Linux" ]; then
        id_src=$(echo $json | grep -Po '"id":".*?[^\\]"')
        id=${id_src:6:36}
    else
        id=`echo $json | sed -e 's/^.*"id":"\([^"]*\)".*$/\1/'`
    fi
}

exitonfail()
{
    if [ $? -ne 0 ]; then
        exit 2
    fi
}

basename=`basename $file`

gpg_cmd="gpg"
outdir="/tmp"
stage=
if [ "$branch" == "dev" ]; then
    newfile=$outdir/$basename$postfix
    stage="dev"
elif [ "$branch" == "master" ]; then
    newfile=$outdir/$basename$postfix
    stage="master"
else 
    newfile=$outdir/$basename$postfix
fi

echo "Moving $file to $newfile"
mv $file $newfile
exitonfail

# TODO: Replace removeFile with basename
removeFile=`basename $newfile`

cdnUrl=https://eu0.${stage}cdn.subutai.io:8338/kurjun/rest
USER=travis
EMAIL=travis@subut.ai

# Getting previous file ID

json=`curl -k -s -X GET $cdnUrl/raw/info?name=$removeFile`
echo "Received: $json"
if [ "$json" != "Not Found" ]; then
    extract_id
    echo "Previous file ID is $id"
fi

PUBLICKEY=$($gpg_cmd --armor --export $EMAIL)
curl -k "$cdnUrl/auth/token?user=$USER" -o $outdir/filetosign
exitonfail
rm -rf $outdir/filetosign.asc
echo "Signing"
$gpg_cmd --armor -u $EMAIL --clearsign $outdir/filetosign
echo "Getting token"
TOKEN=$(curl -k -s -Fmessage="`cat $outdir/filetosign.asc`" -Fuser=$USER "$cdnUrl/auth/token")

ls -l /tmp
echo "Uploading new file"
curl -k -v -H "token: $TOKEN" -Ffile=@$newfile "$cdnUrl/raw/upload"

if [ ! -z "$id" ] && [ $? -eq 0 ]; then
    echo "Removing previous"
    curl -k -s -X DELETE "$cdnUrl/raw/delete?id=$id&token=$TOKEN"
    exitonfail
fi
