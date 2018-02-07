#!/bin/bash

os=$1
branch=$2
file=$3

# Verify all arguments were specified

if [ -z "$os" ]; then
    echo "OS not specified"
    exit 30
fi

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
    exit 22
fi

# Verify OS and set directory accordingly

if [ "$os" == "windows" ]; then
    location="/c/tmp/p2p-packages"
else
    location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [ "$location" != "/tmp/p2p-packages" ]; then
        echo "Wrong script location: $location"
        exit 1
    fi
fi

# ID of the file from Gorjun JSON response
extract_id()
{
    id_src=$(echo $json | grep -Po '"id":".*?[^\\]"')
    id=${id_src:6:36}
}

exitonfail()
{
    if [ $? -ne 0 ]; then
        exit 2
    fi
}

postfix=""
basename="subutai-p2p"

gpg_cmd="gpg"
outdir="/tmp"
if [ "$os" == "debian" ]; then
    postfix=".deb"
    gpg_cmd=/usr/bin/gpg
    outdir="/tmp"
elif [ "$os" == "darwin" ]; then
    postfix=".pkg"
    gpg_cmd=/usr/local/bin/gpg
    outdir="/tmp"
elif [ "$os" == "windows" ]; then
    postfix=".msi"
    gpg_cmd=gpg
    outdir="/c/tmp"
else
    echo "Unknown operating system"
    exit 1
fi

stage=
if [ "$branch" == "dev" ]; then
    newfile=$outdir/$basename-dev$postfix
    stage="dev"
elif [ "$branch" == "master" ]; then
    newfile=$outdir/$basename-master$postfix
    stage="master"
else 
    newfile=$outdir/$basename$postfix
fi
echo "Moving $file to $newfile"
mv $file $newfile
exitonfail

removeFile=`basename $newfile`
#$location/remove.sh $os $removeFile $gpg_cmd $outdir
exitonfail

cdnUrl=https://eu0.${stage}cdn.subut.ai:8338/kurjun/rest
USER=travis
EMAIL=travis@subut.ai

# Getting previous file ID

json=`curl -k -s -X GET $cdnUrl/raw/info?name=$removeFile`
echo "Received: $json"
extract_id
echo "Previous file ID is $id"

PUBLICKEY=$($gpg_cmd --armor --export $EMAIL)
curl -k "$cdnUrl/auth/token?user=$USER" -o $outdir/filetosign
exitonfail
rm -rf $outdir/filetosign.asc
echo "Signing"
$gpg_cmd --armor -u $EMAIL --clearsign $outdir/filetosign
echo "Getting token"
TOKEN=$(curl -k -s -Fmessage="`cat $outdir/filetosign.asc`" -Fuser=$USER "$cdnUrl/auth/token")

echo "Uploading new file"
curl -k -v -H "token: $TOKEN" -Ffile=@$newfile -Ftoken=$TOKEN "$cdnUrl/raw/upload"

echo "Removing previous"
if [ ! -z "$id" ]; then
    curl -k -s -X DELETE "$cdnUrl/raw/delete?id=$id&token=$TOKEN"
    exitonfail
fi
