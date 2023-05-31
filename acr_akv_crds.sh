# !/bin/bash
set -euo pipefail

echo "Loading environment variables stored before"
source ./output/full.env

az policy assignment create \
    --policy-set-definition ${INITIATIVE_ID} \
    --subscription ${SUBSCRIPTION_ID} \
    --resource-group ${RESOURCE_GROUP} \
    --mi-system-assigned --location ${LOCATION} --name image-integrity-poc-assignment > /dev/null

export TENANT_ID=$(az account show --query tenantId -o tsv)

cat <<EOF | kubectl apply -f -
apiVersion: config.ratify.deislabs.io/v1beta1
kind: CertificateStore
metadata:
  name: certstore-akv
spec:
  provider: azurekeyvault
  parameters:
    vaultURI: https://${AKV_NAME}.vault.azure.net/
    certificates:  |
      array:
        - |
          certificateName: ${KEY_NAME}
    clientID: ${IDENTITY_CLIENT_ID}
    tenantID: ${TENANT_ID}
---
apiVersion: config.ratify.deislabs.io/v1beta1
kind: Store
metadata:
  name: store-oras-workloadidentity
spec:
  name: oras
  parameters: 
    authProvider:
      name: azureWorkloadIdentity
      clientID: ${IDENTITY_CLIENT_ID}
---
apiVersion: config.ratify.deislabs.io/v1beta1
kind: Verifier
metadata:
  name: verifier-notary
spec:
  name: notaryv2
  artifactTypes: application/vnd.cncf.notary.signature
  parameters:
    verificationCertStores:
      certs:
        - certstore-akv
    trustPolicyDoc:
      version: "1.0"
      trustPolicies:
        - name: default
          registryScopes:
            - "*"
          signatureVerification:
            level: strict
          trustStores:
            - ca:certs
          trustedIdentities:
            - "*"
EOF
