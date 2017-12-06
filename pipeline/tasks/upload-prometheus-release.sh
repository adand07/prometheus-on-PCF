#!/bin/bash
set -ex

root_dir=$(cd "$(dirname "$0")/.." && pwd)
source ${root_dir}/tasks/common.sh

echo "$opsman_ssh_private_key" > opsman.key
chmod 0600 opsman.key
ssh -oStrictHostKeyChecking=no \
    -4 -D 5000 -NC \
    ${opsman_ssh_user}@${opsman_url} \
    -i opsman.key &

echo $! > ssh-tunnel.pid

export BOSH_ALL_PROXY=socks5://localhost:5000
login_to_director pcf-bosh-creds

echo "Uploading prometheus Release..."
bosh2 upload-release https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease?v=20.0.0 --sha1 11a18875879a7712c67e6d30c4a069101ae77560
bosh2 upload-release https://bosh.io/d/github.com/cloudfoundry/postgres-release?v=21 --sha1 b37916b709fb45ac7de3e195456301cb01a1ae22

kill $(cat ssh-tunnel.pid)
