#/bin/bash

# This script will decrypt GPG private keys based on a project

project=$1

if [ -z "$project" ]; then
    echo "Project was not specified"
    exit 11
fi

if [ "$project" == "p2p" ]; then
    echo "Decrypting using p2p"
elif [ "$project" == "cc" ]; then
    echo "Decrypting using cc"
else
    echo "Project is not supported: $project"
    exit 12
fi