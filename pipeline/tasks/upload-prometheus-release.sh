#!/bin/bash
set -ex

export BOSH_CA_CERT=$external_bosh_ca_cert
export BOSH_ENVIRONMENT=$external_bosh_address
export BOSH_CLIENT=$external_bosh_client
export BOSH_CLIENT_SECRET=$external_bosh_client_secret

echo "Uploading prometheus Release..."
bosh2 upload-release https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease --sha1 11a18875879a7712c67e6d30c4a069101ae77560
