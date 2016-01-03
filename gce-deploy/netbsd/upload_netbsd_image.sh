#!/bin/bash
#
# Upload a new NetBSD image for GCE.
#
# Example use:
#
# ./upload_netbsd_image.sh stromberg netbsd-7.0-amd64-2016-01-03-1128-gce
set -eux -o pipefail

# Name of storage bucket
readonly BUCKET=$1

# Name of .tar.gz archive path.
readonly ARCHIVE=$2


# Convert URL to image name.
function image_url_name() {
  basename $1 | cut -d. -f1-2 | tr "." "-" | tr "[A-Z]" "[a-z"
}


# Create a GCE image.
#
# Args:
#   - src_path: path a .tar.gz archive created by create_netbsd_images.sh.
#   - bucket: name of Google Storage bucket to store image in.
function create_image() {
  local bucket="$1"
  local src_path="$2"

  # Verify health of archive
  tar -ztvf "${src_path}" | grep "disk.raw" \
    || ( echo "${src_path} appears invalid"; return 1; )

  local dest_uri="gs://${bucket}/$(basename ${src_path})"
  gsutil cp "${src_path}" "${dest_uri}"

  local image_name=$(image_url_name "${src_path}")
  gcloud compute images create "${image_name}" --source-uri "${dest_uri}"
}

create_image "${BUCKET}" "${ARCHIVE}"
