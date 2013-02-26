#!/bin/sh
#
# Install Ubuntu on a Galaxy Nexus. Only tested on Mac OS X so far.
#
# Based on http://forum.xda-developers.com/showthread.php?t=2160253

REPOSITORY_URL='http://dl-ssl.google.com/android/repository'
TOOLS_RELEASE='r16.0.1'

IMAGES_URL='http://cdimage.ubuntu.com/ubuntu-touch-preview/quantal/mwc-demo'
IMAGE_VERSION='quantal-preinstalled'
IMAGE_ARCH='armel'

WORKDIR="${HOME}/.ubuntu_fastflash"

set -u  # unset
set -e  # errexit

function get() {
  basename=$(basename $1)
  if [ ! -s "${basename}" ]; then
    curl -L -O "$1"

    big_enough=$(find ${basename} -size +8k)
    if [ -z "${big_enough}" ]; then
      echo "Incomplete download of $1:"
      cat ${basename}
      rm -f ${basename}
      exit 1
    fi
  fi
}

## main program flow ##

os=$(uname)
if [ $os == "Darwin" ]; then
  tool_os="macosx"
elif [ $os == "Linux" ]; then
  tool_os="linux"
else
  print "$distro is unsupported"
  exit 3
fi

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
echo "Using ${WORKDIR} as working directory."


tools_file="platform-tools_${TOOLS_RELEASE}-${tool_os}.zip"
get "${REPOSITORY_URL}/${tools_file}"
fastboot="./platform-tools/fastboot"
adb="./platform-tools/adb"

if [ ! -f "${fastboot}" ]; then

  unzip "${tools_file}"
fi

echo "**********************************************************************"
echo "Please enter fastboot on your device. On most devices, this works by"
echo "powering it off, then holding down both volume buttons plus the power"
echo "button at the same time for 10 seconds."
echo "**********************************************************************"
# This step is allowed to fail
${fastboot} oem unlock || echo "Hmm, hopefully this is unlocked already."

#device_type=$(${adb} devices -l | egrep -o 'device:[a-z]+' | cut -d: -f2)
device_type=$(${fastboot} getvar variant 2>&1 | grep "^variant:" | cut -d" " -f2)

if [ -z "${device_type}" ]; then
  echo "Unable to determine device family using ${fastboot} getvar variant"
  exit 4
fi
fastboot="./platform-tools/fastboot"
adb="./platform-tools/adb"

if [ ! -f "${fastboot}" ]; then
  unzip "${tools_file}"
fi


boot_file="${IMAGE_VERSION}-boot-${IMAGE_ARCH}+${device_type}.img"
recovery_file="${IMAGE_VERSION}-recovery-${IMAGE_ARCH}+${device_type}.img"
system_file="${IMAGE_VERSION}-system-${IMAGE_ARCH}+${device_type}.img"
main_file="${IMAGE_VERSION}-${IMAGE_ARCH}+${device_type}.zip"
phablet_file="${IMAGE_VERSION}-phablet-armhf.zip"



for file in ${boot_file} ${recovery_file} ${system_file} ${main_file} ${phablet_file}; do
  get "${IMAGES_URL}/${file}"
done


${fastboot} flash recovery ${recovery_file}
${fastboot} flash system ${system_file}
${fastboot} flash boot ${boot_file}
${fastboot} reboot-bootloader
sleep 3
echo "*********************************************************************"
echo "* Use the volume keys to choose RECOVERY and press the power button."
echo "  Then select INSTALL ZIP FROM SIDELOAD and press <ENTER> here."
echo "*********************************************************************"
# doesn't work here
#${adb} wait-for-device
read
sleep 5

${adb} sideload ${main_file}
sleep 20

echo "*********************************************************************"
echo "* Now select ADVANCED, then REBOOT RECOVERY."
echo "  Then select INSTALL ZIP FROM SIDELOAD and press <ENTER> here."
echo "*********************************************************************"
read
sleep 5
${adb} sideload "${phablet_file}"
echo "Waiting..."
sleep 30
echo "Once it is possible, select REBOOT SYSTEM NOW. You now have Ubuntu."

