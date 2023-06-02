export ALIAS=${ALIAS:-"alias"}
export SUBSCRIPTION_ID=${SUBSCRIPTION_ID:-""}

export SKIP_UUID=${SKIP_UUID:-false}
if [[ $SKIP_UUID == "true" ]]; then
    uuid=""
    export PREFIX=$ALIAS
else
    uuid=$(uuidgen)
    export PREFIX=$ALIAS-${uuid:0:3}
fi
export PREFIX=$(echo $PREFIX | tr '[:upper:]' '[:lower:]')
export SKIP_ACR_KEYVAULT=${SKIP_ACR_KEYVAULT:-false}

export LOCATION="eastus"
export RESOURCE_GROUP="${PREFIX}-ratify-rg"
export AKS_NAME="${PREFIX}-ratify-cluster"

export ACR_NAME=$(echo "$ALIAS${uuid:0:3}acr" | tr '[:upper:]' '[:lower:]')
export REGISTRY=$ACR_NAME.azurecr.io
export REPO=${REGISTRY}/net-monitor
export IMAGE=${REPO}:v1
export IMAGE_SOURCE=https://github.com/wabbit-networks/net-monitor.git#main

export AKV_NAME="${PREFIX}-ratify-kv"
export CERT_NAME="${PREFIX}-cert"
export KEY_NAME=${PREFIX}-wabbit-networks-io
export CERT_SUBJECT="CN=wabbit-networks.io,O=Notary,L=Seattle,ST=WA,C=US"
export CERT_PATH=./certs/${KEY_NAME}.pem

az account set -s ${SUBSCRIPTION_ID} > /dev/null
az feature register -n EnableWorkloadIdentityPreview --namespace Microsoft.ContainerService > /dev/null
is_external_data_source_registered=$(az feature show --namespace Microsoft.ContainerService -n AKS-AzurePolicyExternalData --query properties.state -o tsv)
if [[ $is_external_data_source_registered != "Registered" ]]; then
    echo "AKS-AzurePolicyExternalData feature flag not registered, please check 'feature flag registeration' in readme" >>/dev/stderr
    exit 1
fi

echo creating resource group ${RESOURCE_GROUP}
az group create -n ${RESOURCE_GROUP} -l ${LOCATION} > /dev/null
az tag create --resource-id /subscriptions/${SUBSCRIPTION_ID}/resourcegroups/${RESOURCE_GROUP} --tags ratify=helm > /dev/null

if [[ $SKIP_ACR_KEYVAULT == "false" ]]; then
    echo creating ACR
    az acr create -n ${ACR_NAME} -g ${RESOURCE_GROUP} --sku Premium > /dev/null
    az acr update -n ${ACR_NAME} --anonymous-pull-enabled false > /dev/null

    echo creating keyvault
    az keyvault create -n $AKV_NAME -g ${RESOURCE_GROUP} > /dev/null
fi

echo
echo "Creating msi and assign its permission to the akv and acr"
az identity create --name myIdentity --resource-group ${RESOURCE_GROUP} > /dev/null
export IDENTITY_PRINCIPAL_ID=$(az identity show --name myIdentity --resource-group ${RESOURCE_GROUP} --query 'principalId' -o tsv)
export IDENTITY_CLIENT_ID=$(az identity show --name myIdentity --resource-group ${RESOURCE_GROUP} --query 'clientId' -o tsv)
export IDENTITY_RESOURCE_ID=$(az identity show --name myIdentity --resource-group ${RESOURCE_GROUP} --query 'id' -o tsv)
# assign permission to acr and keyvault
if [[ $SKIP_ACR_KEYVAULT == "false" ]]; then
    sleep 60
    az keyvault set-policy -n ${AKV_NAME} --certificate-permissions get --object-id  ${IDENTITY_PRINCIPAL_ID} > /dev/null
    az role assignment create --assignee ${IDENTITY_PRINCIPAL_ID} --role "Acrpull" --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}" > /dev/null
fi
