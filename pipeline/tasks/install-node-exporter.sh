#!/bin/bash
set -ex

TMPDIR=${TMPDIR:-/tmp}
TMPFILE=$(mktemp "$TMPDIR/runtime-config.XXXXXX")

root_dir=$(cd "$(dirname "$0")/.." && pwd)

source ${root_dir}/tasks/common.sh

login_to_director pcf-bosh-creds

echo "Creating SSH tunnel"
echo "$opsman_ssh_private_key" > opsman.key

chmod 0600 opsman.key
ssh -oStrictHostKeyChecking=no -N \
    ${opsman_ssh_user}@${opsman_url} \
    -i opsman.key \
    -L 8080:${director_ip}:8443 &
echo $! > ssh-tunnel.pid

echo "Uploading Node exporter Release..."
bosh2 -n upload-release node-exporter-release/node-exporter-*.tgz

node_exporter_version=$(cat node-exporter-release/version)
bosh2 -n update-runtime-config --name=node_exporter pcf-prometheus-git/runtime.yml -v node_exporter_version=${node_exporter_version}

kill $(cat ssh-tunnel.pid)
