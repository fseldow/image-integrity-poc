# !/bin/bash
set -euo pipefail

export SKIP_UUID="true"
export SKIP_ACR_KEYVAULT=true

echo Please input your alias as resource prefix:
read alias
export ALIAS=$alias
echo
echo Please input your subscription id:
read subscription
export SUBSCRIPTION_ID=$subscription

az login > /dev/null
source env.sh
bash cluster.sh
source policy.sh

echo
echo "##################################"
echo "Summary:"
echo "##################################"
echo "cluster id: /subscriptions/${SUBSCRIPTION_ID}/resourcegroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_NAME}"
echo "you could run the following command to fetch the cluster kubeconfig"
echo "az aks get-credentials -g ${RESOURCE_GROUP} -n ${AKS_NAME} --subscription ${SUBSCRIPTION_ID}"
echo
echo "policy initiative name: [Image Integrity] Ensuring AKS application using signed images"
echo "initiative id: ${INITIATIVE_ID}"
echo "please assign the initiative to your resource group, e.g."
echo "az policy assignment create \\"
echo "    --policy-set-definition ${INITIATIVE_ID} \\"
echo "    --subscription ${SUBSCRIPTION_ID} \\"
echo "    --resource-group ${RESOURCE_GROUP} \\"
echo "    --mi-system-assigned --location ${LOCATION} --name image-integrity-poc-assignment"
echo
echo storing env in ./output/base.env
mkdir -p ./output
bash store_env.sh ./output/base.env
