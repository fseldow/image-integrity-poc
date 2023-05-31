file_name=$1
cat << EOF > $file_name
export ALIAS=${ALIAS}
export SUBSCRIPTION_ID=${SUBSCRIPTION_ID}

export PREFIX=${PREFIX}

export LOCATION=${LOCATION}
export RESOURCE_GROUP=${RESOURCE_GROUP}
export AKS_NAME="${AKS_NAME}"

export ACR_NAME=${ACR_NAME}
export REGISTRY=${REGISTRY}
export REPO="${REPO}"
export IMAGE="${IMAGE}"

export AKV_NAME=${AKV_NAME}
export CERT_NAME=${CERT_NAME}
export KEY_NAME=${KEY_NAME}
export CERT_SUBJECT="${CERT_SUBJECT}"
export CERT_PATH="${CERT_PATH}"

export IDENTITY_PRINCIPAL_ID=${IDENTITY_PRINCIPAL_ID}
export IDENTITY_CLIENT_ID=${IDENTITY_CLIENT_ID}
export IDENTITY_RESOURCE_ID="${IDENTITY_RESOURCE_ID}"

export INITIATIVE_ID=${INITIATIVE_ID}
EOF