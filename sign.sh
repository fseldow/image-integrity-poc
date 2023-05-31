# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-tutorial-sign-build-push
#!/bin/bash
set -euo pipefail

echo "####################################"
echo "Install notation and akv plugin"
echo "####################################"
curl -Lo notation.tar.gz https://github.com/notaryproject/notation/releases/download/v1.0.0-rc.4/notation_1.0.0-rc.4_linux_amd64.tar.gz
tar xvzf notation.tar.gz

alias notation=./notation

mkdir -p ~/.config/notation/plugins/azure-kv

curl -Lo notation-azure-kv.tar.gz \
    https://github.com/Azure/notation-azure-kv/releases/download/v0.6.0/notation-azure-kv_0.6.0_Linux_amd64.tar.gz
tar xvzf notation-azure-kv.tar.gz -C ~/.config/notation/plugins/azure-kv notation-azure-kv

echo "####################################"
echo "generate cert"
echo "####################################"
cat <<EOF > ./my_policy.json
{
    "issuerParameters": {
    "certificateTransparency": null,
    "name": "Self"
    },
    "x509CertificateProperties": {
    "ekus": [
        "1.3.6.1.5.5.7.3.3"
    ],
    "keyUsage": [
        "digitalSignature"
    ],
    "subject": "$CERT_SUBJECT",
    "validityInMonths": 12
    }
}
EOF
mkdir -p certs
# create cert
az keyvault certificate create -n $KEY_NAME --vault-name $AKV_NAME -p @my_policy.json
KEY_ID=$(az keyvault certificate show -n $KEY_NAME --vault-name $AKV_NAME --query 'kid' -o tsv)

# download cert
CERT_ID=$(az keyvault certificate show -n $KEY_NAME --vault-name $AKV_NAME --query 'id' -o tsv)
az keyvault certificate download --file $CERT_PATH --id $CERT_ID --encoding PEM

notation key add $KEY_NAME --plugin azure-kv --id $KEY_ID
STORE_TYPE="ca"
STORE_NAME="wabbit-networks.io"
notation cert add --type $STORE_TYPE --store $STORE_NAME $CERT_PATH

notation key ls
notation cert ls

echo "####################################"
echo "Build and sign image"
echo "####################################"
az acr build -r $ACR_NAME -t $IMAGE $IMAGE_SOURCE
export USER_NAME="00000000-0000-0000-0000-000000000000"
export PASSWORD=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken)
notation login -u $USER_NAME -p $PASSWORD $REGISTRY
notation sign --key $KEY_NAME $IMAGE
notation ls $IMAGE

echo "####################################"
echo "Clean up notation cli"
echo "####################################"
rm -f ./notation notation.tar.gz my_policy.json notation.tar.gz notation-azure-kv.tar.gz LICENSE