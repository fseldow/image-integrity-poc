#!/bin/bash
set -euo pipefail

export VERIFICATION_NAME="[${PREFIX}]Azure Kubernetes clusters should only deploy Notation signed images"
export DINE_NAME="[${PREFIX}]Deploy Image Integrity on Azure Kubernetes Service"
export INITIATIVE_NAME="[${PREFIX}]Use Image Integrity to ensure only trusted images are deployed"

verifier_content=$(cat policy/verifier_policy.json)
dine_content=$(cat policy/dine_policy.json)

res=$(az policy definition create --name "${PREFIX}-ii-verification" --display-name "$VERIFICATION_NAME" --rules "$(echo "$verifier_content" | jq .properties.policyRule)" --params "$(echo "$verifier_content" | jq .properties.parameters)" --mode "Microsoft.Kubernetes.Data")
verification_definition_id=$(echo $res | jq .id)

res=$(az policy definition create --name "${PREFIX}-ii-dine" --display-name "$DINE_NAME" --rules "$(echo "$dine_content" | jq .properties.policyRule)" --params "$(echo "$dine_content" | jq .properties.parameters)")
dine_definition_id=$(echo $res | jq .id)

initiative_content=$(cat policy/initiative.json)
initiative_content=$(echo $initiative_content | jq .policyDefinitions[0].policyDefinitionId=$dine_definition_id )
initiative_content=$(echo $initiative_content | jq .policyDefinitions[1].policyDefinitionId=$verification_definition_id )
initiative_parameter=$(echo $initiative_content | jq .parameters)
initiative_definitions=$(echo $initiative_content | jq .policyDefinitions)

set_res=$(az policy set-definition create -n "${PREFIX}-ii-initiative" --definitions "${initiative_definitions}" --params "${initiative_parameter}" --display-name "${INITIATIVE_NAME}") 
export INITIATIVE_ID=$(echo $set_res | jq .id)
echo ${INITIATIVE_ID}
