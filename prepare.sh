# !/bin/bash
set -euo pipefail

echo Please input your alias as resource prefix:
read alias
export ALIAS=$alias

echo Please input your subscription id:
read subscription
export SUBSCRIPTION_ID=$subscription

source env.sh
bash sign.sh
bash cluster.sh
source policy.sh

echo
echo "policy initiative name: [Image Integrity] Ensuring AKS application using signed images"
echo "initiative id: ${INITIATIVE_ID}"
echo "please assign the initiative to your resource group"

echo store some env in ./output/full.env
mkdir -p ./output
bash store_env.sh ./output/full.env