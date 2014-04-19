#!/bin/sh
set -eux -o pipefail

cd ../spl
git pull
./configure --with-config=user || exit
make rpm-utils rpm-dkms || exit

cd ../zfs
git pull
./configure --with-config=user || exit
make rpm-utils rpm-dkms || exit

cd ..
find spl zfs -name "*.rpm" | xargs yum localinstall -y
