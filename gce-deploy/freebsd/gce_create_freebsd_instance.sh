#!/bin/sh
#
# Create a new GCE instance (FreeBSD)
#
# Example use:
#
# ./gce_create_freebsd_instance.sh <name>

set -eux -o pipefail

# name of instance
readonly NAME=$1

# GCE image name.
readonly IMAGE_NAME=$(gcloud compute images list  | egrep "freebsd.*READY" | tail -n1 | awk '{ print $1 }')

# zone
readonly ZONE="us-central1-f"


gcloud compute instances create "${NAME}" \
  --boot-disk-size 12GB \
  --image "${IMAGE_NAME}"\
  --machine-type f1-micro
  --zone "${ZONE}"

gcloud ssh '${NAME}"
