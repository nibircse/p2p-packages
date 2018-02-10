#!/bin/bash

git clone --depth 1 https://github.com/hogliux/bomutils.git /tmp/bomutils
cd /tmp/bomutils
make
sudo make install
