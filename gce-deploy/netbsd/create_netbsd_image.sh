#!/bin/bash
#
# Create a NetBSD image for GCE.
#
# Example use to build a NetBSD 7.0 image:
#
# ./create_netbsd_image.sh 7.0

set -eux -o pipefail

# NetBSD release version, such as "7.0"
readonly NETBSD_VERSION=$1

# Size of disk to create
readonly DISK_SIZE="4G"

# Anita, automated NetBSD Installation tool: http://www.gson.org/netbsd/anita/
readonly ANITA_URL="http://www.gson.org/netbsd/anita/download/anita-1.39.tar.gz"

# Architecture to build for.
readonly ARCH=amd64


# Run Anita.
#
# Args:
#   - netbsd_version: version of NetBSD we are building.
#   - work_dir: directory containing wd0.img file.
#
# Globals:
#   - ARCH - NetBSD architecture to build for.
#   - ANITA_URL - Path to Anita download.
#   - DISK_SIZE - size of disk to build.
function run_anita() {
  local netbsd_version="$1"
  local work_dir="$2"

  # Download and build anita (automated NetBSD installer)
  local anita_tarball="$(basename ${ANITA_URL})"
  local anita_dir=$(echo ${anita_tarball} | sed s/"\.tar\.gz"/""/)

  if [[ ! -e "${anita_dir}" ]]; then
    curl -vO "${ANITA_URL}" && tar xfz "${anita_tarball}"
    cd "${anita_dir}" && python setup.py install --user
    cd ..
  fi

  # Verify QEMU install
  qemu-system-x86_64 --version \
    || ( echo "QEMU must be installed in PATH."; return 2; )

  # Make the VM.
  python mkvm.py "${ARCH}" "${netbsd_version}" "${work_dir}" "${DISK_SIZE}" \
    || ( echo "Failed to build ${netbsd_version}"; return 3; )

  # Sometimes the display gets corrupt.
  reset

  echo "Successfully built NetBSD ${netbsd_version} image in ${work_dir}!"
}

# Archive the image created by Anita.
#
# Args:
#   - netbsd_version: version of NetBSD we are building.
#   - work_dir: directory containing wd0.img file.
function archive_image() {
  local netbsd_version="$1"
  local work_dir="$2"

  # The name of the image to build.
  local image_name="netbsd-${netbsd_version}-$(date +%Y-%m-%d-%H%M)"

  # GCE requires that the image be named disk.raw.
  mv ${work_dir}/wd0.img ${work_dir}/disk.raw

  tar -C ${work_dir} -Szcf ${image_name}.tar.gz disk.raw
  echo "Done. GCE image is ${image_name}.tar.gz."
}


# Main program flow.
# The name of our temporary directory to work in.
work_dir="${TMPDIR}/NetBSD-${NETBSD_VERSION}-${ARCH}"

run_anita "${NETBSD_VERSION}" "${work_dir}"
archive_image "${NETBSD_VERSION}" "${work_dir}"

