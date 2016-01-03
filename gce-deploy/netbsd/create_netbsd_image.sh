#!/bin/bash
# Copyright 2014 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -eux

ANITA_VERSION=1.38
ARCH=amd64
RELEASE=7.0

BUILD_TIMESTAMP=$(date +%Y-%m-%d-%H%M)
BUILD_NAME="netbsd-${RELEASE}-${ARCH}-${BUILD_TIMESTAMP}-gce"
WORK_DIR=${BUILD_NAME}

# Download and build anita (automated NetBSD installer).
if ! [ -e anita-${ANITA_VERSION}.tar.gz ]; then
  curl -vO http://www.gson.org/netbsd/anita/download/anita-${ANITA_VERSION}.tar.gz
fi

tar xfz anita-${ANITA_VERSION}.tar.gz
cd anita-${ANITA_VERSION}
python setup.py install --user
cd ..

python mkvm.py ${ARCH} ${RELEASE} ${WORK_DIR}

reset

# GCE requires that the image be named disk.raw.
mv ${WORK_DIR}/wd0.img ${WORK_DIR}/disk.raw
echo "Archiving disk.raw (this may take a while)"

tar -C ${WORK_DIR} -Szcf ${BUILD_NAME}.tar.gz disk.raw
echo "Done. GCE image is ${BUILD_NAME}.tar.gz."
