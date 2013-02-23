#!/bin/sh
#
# Reinstall Android on a Galaxy Nexus.
#
# Based on https://wiki.ubuntu.com/Touch/Install#Restoring_Android

DEVICE_NAME=$1

set -e
set -u

IMAGES_URL="https://developers.google.com/android/nexus/images"
WORKDIR="${HOME}/.ubuntu_fastflash"

function get() {
  if [ ! -s "$(basename $1)" ]; then
    curl -L -O $1
  fi
}

if [ -z "$DEVICE_NAME" ]; then
  echo "Please pass the firmware codename as an argument. See ${IMAGES_URL}"
  exit 1
fi

latest_url=$(curl -s ${IMAGES_URL} | egrep -o "https.*${DEVICE_NAME}.*tgz" | tail -1)

if [ -z "$latest_url" ]; then
  echo "Unable to find latest ${DEVICE_NAME} build on ${IMAGES_URL}"
  exit 2
fi

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
echo "Using ${WORKDIR} as working directory."

get $latest_url

firmware_file=$(basename ${latest_url})
firmware_dir=$(echo $firmware_file | cut -d- -f1-2)

if [ ! -d "${firmware_dir}" ]; then
  tar -zxvf ${firmware_file}
fi

export PATH=`pwd`/platform-tools:$PATH
cd $firmware_dir
source flash-all.sh

