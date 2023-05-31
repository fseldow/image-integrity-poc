#!/bin/bash
set -euo pipefail

export DEFINITION_NAME=${PREFIX}-notaryv2-verify
export INITIATIVE_NAME=${PREFIX}-ratify-initiative

content=$(cat policy/verifier_policy.json)

res=$(az policy definition create --name $DEFINITION_NAME --rules "$(echo "$content" | jq .properties.policyRule)" --params "$(echo "$content" | jq .properties.parameters)" --mode "Microsoft.Kubernetes.Data")
verification_definition_id=$(echo $res | jq .id)

initiative_content=$(cat policy/initiative.json)
initiative_content=$(echo $initiative_content | jq .policyDefinitions[1].policyDefinitionId=$verification_definition_id )
initiative_parameter=$(echo $initiative_content | jq .parameters)
initiative_definitions=$(echo $initiative_content | jq .policyDefinitions)

set_res=$(az policy set-definition create -n ${INITIATIVE_NAME} --definitions "${initiative_definitions}" --params "${initiative_parameter}" --display-name "[${PREFIX}][Image Integrity] Ensuring AKS application using signed images") 
export INITIATIVE_ID=$(echo $set_res | jq .id)
