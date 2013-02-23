#!/bin/sh
#
# Install Ubuntu on a Galaxy Nexus. Only tested on Mac OS X so far.

FASTBOOT_URL='https://adb-fastboot-install.googlecode.com/files/Androidv4.zip'
TOOL_DIR='Android'

IMAGES_URL='http://cdimage.ubuntu.com/ubuntu-touch-preview/quantal/mwc-demo/'
IMAGE_VERSION='quanta1-preinstalled'
IMAGE_ARCH='armel'

WORKDIR="${HOME}/.ubuntu_fastflash"

# Galaxy Nexus: maguro
# Nexus 4: mako
# Nexus 7: grouper
# Nexus 10: manta
DEVICE_TYPE=${1:-maguro}

set -u  # unset
set -e  # errexit

function get() {
  # googlecode doesn't support resume. Check for non-zero existence instead.
  if [ ! -s "$(basename $1)" ]; then
    curl -O $1
  fi
}

## main program flow ##

os=$(uname)
if [ $os == "Darwin" ]; then
  tool_os="Mac"
elif [ $os == "Linux" ]; then
  tool_os=$os
else
  print "$distro is unsupported"
  exit 3
fi



mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
echo "Using ${WORKDIR} as working directory."

get "${FASTBOOT_URL}"

boot_file="${IMAGE_VERSION}-boot-${IMAGE_ARCH}+${DEVICE_TYPE}.img"
recovery_file="${IMAGE_VERSION}-recovery-${IMAGE_ARCH}+${DEVICE_TYPE}.img"
system_file="${IMAGE_VERSION}-system-${IMAGE_ARCH}+${DEVICE_TYPE}.img"
main_file="${IMAGE_VERSION}-${IMAGE_ARCH}+${DEVICE_TYPE}.img"
phablet_file="${IMAGE_VERSION}-phablet-armhf.zip"

for file in ${boot_file} ${recovery_file} ${system_file} ${main_file} ${phablet_file}; do
  get "${IMAGES_URL}/${file}"
done


fastboot_path="./${TOOL_DIR}/${tool_os}/fastboot_${tool_os}"
adb_path="./${TOOL_DIR}/${tool_os}/adb_${tool_os}"

if [ ! -f "${fastboot_path}" ]; then
  unzip "$(basename $FASTBOOT_URL)"
fi

echo "***************************************************************"
echo "Please enter fastboot on your device. On most devices, this works by"
echo "powering it off, then holding down both volume buttons plus the power"
echo "button at the same time for 10 seconds."
echo "***************************************************************"
# This step is allowed to fail
${fastboot_path} oem unlock || echo "Hmm, hopefully this is unlocked already."
# end allowed failure

${fastboot_path} flash recovery ${recovery_file}
${fastboot_path} flash system ${system_file}
${fastboot_path} flash boot ${boot_file}
${adb_path} sideload ${main_file}

echo "On the main menu, choose ADVANCED then REBOOT."
echo "Press <ENTER> to continue."

adb sideload "${phablet_file}"

echo "COMPLETED - Please restart your device!"

