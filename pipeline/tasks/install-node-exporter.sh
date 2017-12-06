#!/bin/bash
set -ex

TMPDIR=${TMPDIR:-/tmp}
TMPFILE=$(mktemp "$TMPDIR/runtime-config.XXXXXX")

root_dir=$(cd "$(dirname "$0")/.." && pwd)

source ${root_dir}/tasks/common.sh

echo "Creating SSH tunnel"
echo "$opsman_ssh_private_key" > opsman.key
chmod 0600 opsman.key
ssh -4 -D 5000 -NC ${opsman_ssh_user}@${opsman_url} -i opsman.key &
echo $! > ssh-tunnel.pid

export BOSH_ALL_PROXY=socks5://localhost:5000
login_to_director pcf-bosh-creds

echo "Uploading Node exporter Release..."
bosh2 upload-release https://bosh.io/d/github.com/cloudfoundry-community/node-exporter-boshrelease --sha1 a0018f96dd78525cae3687cfa1d9353aac7a0e02

node_exporter_version=$(cat node-exporter-release/version)
bosh2 -n update-runtime-config --name=node_exporter pcf-prometheus-git/runtime.yml -v node_exporter_version=${node_exporter_version}

kill $(cat ssh-tunnel.pid)
