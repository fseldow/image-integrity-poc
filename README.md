# Before ALL
## Limitations:
- It will not include mutation policy for now.
- During the ratify installation via helm. The chart will not include ratify crds (definition will be included). So by default all pods will be denied since there are no verifier existed.
- Make sure you are Owner Role instead of Contributor role of the sub. The contributor do not have full permission to assign policy.
- Since the steps include azure key vault operations, you need to run in allowed devices, it means linux devbox is not supported. Please use WSL or MAC
- The AKS cluster must be 1.26+ (no need to pay extra attention if you create the cluster by script)

## feature flag registeration
- contact Anlan Du / Martha Amirzadeh to register the external data feature of azure policy addon

## Basic tools
- az cli
- kubectl
- helm
- jq
- docker (optional)

# Quick Start Steps
## Cluster and policy only
The scenario is that you have your own acr or keyvault or any sign images.  
You only need aks cluster with ratify installed and the policy definition in your sub.  
`docker run -it fseldow/image-integrity-poc:v1`

If you do not have docker, please run `bash prepare_cluster_only.sh` instead

### verify via `wabbitnetworks.azurecr.io/test/notary-image:signed`
- Assign your policy initative to your resource group. It can be done by portal by search policy with name `ratify-initiative` or you can use the azcli command that will finally print in the above script.
- Fetch the kubeconfig of your cluster. The cluster should be under a resource group named `xxx-ratify-rg`. Or you can follow the azcli instruction at the script output.
- `kubectl apply -f crds-base/certstore.yaml`
- `kubectl apply -f crds-base/store.yaml`
- `kubectl apply -f crds-base/verifier.yaml`
- Wait for 30min - 1 hour for azure policy to take effect
- `kubectl run demo --image=wabbitnetworks.azurecr.io/test/notary-image:signed` should created
- `kubectl run demo1 --image=wabbitnetworks.azurecr.io/test/notary-image:unsigned` should get deny information
- cleanup the ratify crds when you want to play with other scenario
- `kubectl delete store --all`
- `kubectl delete certificateStore --all`
- `kubectl delete verifier --all`

## Prepare full resources.
`az login`  
`source prepare.sh`  
This script will include the following steps to create an AKS cluster with ratify and workload identity and some signed images
1. create rg
1. create private acr
1. create keyvault
1. sign image via cert in keyvault and push to acr
1. create aks cluster
1. create a msi
1. create federated credentials to make sure workload identity can work when you need
1. deploy ratify via local helm chart (without crds and mutation)
1. create the custom policy initiative definition in your sub

`source acr_akv_crds.sh` to assign the policy initiative and ratify crds  
wait for 30min - 1hour for azure policy to take effect

### verify
- `kubectl run demo-acr --image ${IMAGE}` should be able to created. If you unexpected the terminal exit, please run `source ./output/full.env` to refetch the environment value.
- `kubectl run demo-block --image busybox` should be denied
- cleanup the ratify crds when you want to play with other scenario
- `kubectl delete store --all`
- `kubectl delete certificateStore --all`
- `kubectl delete verifier --all`