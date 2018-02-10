#!/bin/bash

git clone --depth 1 https://github.com/mackyle/xar.git /tmp/xar
cd /tmp/xar/xar
./autogen.sh
./configure
make
sudo make install
