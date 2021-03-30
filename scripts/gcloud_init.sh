#!/bin/bash

container=sdk_gcp
gcp_sdk_path=google-cloud-sdk
gcp_sdk_archive=google-cloud-sdk-326.0.0-linux-x86_64.tar.gz
sa_key=/keys/brim-lab.json
podman_cmd="podman run -v /home/rodrigobrim/Documents/keys/:/keys -v ./:/root ${container}" 

# Install google cloud SDK
if [ ! -f ${gcp_sdk_path}/bin/gcloud ]
then
  curl -OL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${gcp_sdk_archive}
  tar xvzf ${gcp_sdk_archive}
  ${gcp_sdk_path}/install.sh --quiet
  rm -rf ${gcp_sdk_archive}
fi

# Get service account email
sa_email=`${podman_cmd} cat ${sa_key} | grep client_email | awk '{print $2}' | cut -d'"' -f2`

# Check if gcloud is authenticated
${podman_cmd} gcloud auth list 2>&1| grep ${sa_email} >/dev/null 2>&1
if [ $? -ne 0 ]
then
  # Do authenticate
  ${podman_cmd} gcloud auth activate-service-account --key-file=${sa_key}
fi
