#!/bin/bash
set -ex

TMPDIR=${TMPDIR:-/tmp}
TMPFILE=$(mktemp "$TMPDIR/runtime-config.XXXXXX")

root_dir=$(cd "$(dirname "$0")/.." && pwd)

CREDS=${pcf-bosh-creds}

export BOSH_ENVIRONMENT="127.0.0.1"
export BOSH_CA_CERT=$(cat "$CREDS/bosh-ca.pem")
export BOSH_CLIENT=$(cat "$CREDS/bosh-username")
export BOSH_CLIENT_SECRET=$(cat "$CREDS/bosh-pass")

echo "Creating SSH tunnel"
echo "$opsman_ssh_private_key" > opsman.key

CURL="om --target https://${opsman_url} -k \
  --username ${pcf_opsman_admin_username} \
  --password ${pcf_opsman_admin_password} \
  curl"
director_id=$($CURL --path=/api/v0/deployed/products | jq -r '.[] | select (.type == "p-bosh") | .guid')

chmod 0600 opsman.key
ssh -oStrictHostKeyChecking=no -N \
    ${opsman_ssh_user}@${opsman_url} \
    -i opsman.key \
    -L 25555:${director_ip}:25555 \
    -L 4222:${director_ip}:4222 \
    -L 25250:${director_ip}:25250 \
    -L 25777:${director_ip}:25777 \
    &

echo $! > ssh-tunnel.pid

echo "Uploading Node exporter Release..."
bosh2 -n upload-release node-exporter-release/node-exporter-*.tgz

node_exporter_version=$(cat node-exporter-release/version)
bosh2 -n update-runtime-config --name=node_exporter pcf-prometheus-git/runtime.yml -v node_exporter_version=${node_exporter_version}

kill $(cat ssh-tunnel.pid)
