set -euo pipefail

# it is a temp solution for POC to directly use kubelet identity.
echo 
echo "Creating aks cluster"
az aks create -g ${RESOURCE_GROUP} -n ${AKS_NAME} \
    -k 1.26 \
    --enable-addons azure-policy \
    --enable-oidc-issuer --enable-workload-identity \
    --generate-ssh-keys > /dev/null
az aks get-credentials -g ${RESOURCE_GROUP} -n ${AKS_NAME}

kubectl cluster-info

echo
echo "Install ratify via helm local chart"
helm install ratify ./charts/ratify \
    --atomic \
    --namespace gatekeeper-system

echo
echo "Ensuring msi bind with ratify service account"
FEDERATED_IDENTITY_CREDENTIAL_NAME=ratify-federation
USER_ASSIGNED_IDENTITY_NAME=myidentity
AKS_OIDC_ISSUER="$(az aks show -n "${AKS_NAME}" -g "${RESOURCE_GROUP}" --query "oidcIssuerProfile.issuerUrl" -otsv)"
SERVICE_ACCOUNT_NAMESPACE="gatekeeper-system"
SERVICE_ACCOUNT_NAME="ratify-admin"

az identity federated-credential create --name ${FEDERATED_IDENTITY_CREDENTIAL_NAME} --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --audience api://AzureADTokenExchange