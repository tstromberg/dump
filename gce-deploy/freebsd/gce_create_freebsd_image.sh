#!/bin/sh
#
# Create a new GCE image (FreeBSD) using images from https://brainhoard.com/
#
# Example use:
#
# ./gce_create_freebsd_image.sh stromberg http://gce-image.brainhoard.com/FreeBSD-11.0-CURRENT-151231.tar.gz

set -eux -o pipefail

# name of storage bucket
readonly BUCKET=$1

# See https://brainhoard.com/
readonly IMAGE_URL=$2

# Local cache
readonly DOWNLOAD_DIR="$HOME/Downloads"

# Convert URL to image name.
function image_url_name() {
  basename $1 | cut -d. -f1-2 | tr "." "-" | tr "[A-Z]" "[a-z"
}


# Create a GCE image.
function create_image() {
  local src_uri="$1"
  local bucket="$2"
  local image_name=$(image_url_name "${src_uri}")
  local base_name=$(basename ${src_uri})

  local dest_uri="gs://${bucket}/${base_name}"
  local local_path="${DOWNLOAD_DIR}/${base_name}"

  gsutil ls "${dest_uri}" && uploaded=1 || uploaded=0
  if [[ "${uploaded}" -eq 0 ]]; then
    if [[ ! -f "${local_path}" ]]; then
      curl "${src_uri}" > "${local_path}"
    fi
    gsutil cp "${local_path}" "${dest_uri}"
  fi

  gcloud compute images create "${image_name}" --source-uri "${dest_uri}"
}

create_image "${IMAGE_URL}" "${BUCKET}"
