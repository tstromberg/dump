#!/bin/bash
set -eux
archive=$1

if [[ ! -f "${archive}"  ]]; then
  echo "$archive does not exist"
  exit 1
fi

image_name=$(echo $archive | sed s/"-gce\.tar\.gz"/""/g | sed s/"\."/""/g)
gs_url="gs://stromberg/${archive}"

gsutil cp ${archive} ${gs_url}
gcloud compute images create ${image_name} --source-uri ${gs_url}
