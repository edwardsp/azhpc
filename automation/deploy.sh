#!/bin/bash

echo "Reading parameters from: $1"
source $1

scriptname=$(basename "$0")
scriptname="${scriptname%.*}"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
LOGDIR=${scriptname}_${timestamp}
mkdir $LOGDIR

function execute {
	task=$1
	SECONDS=0
	echo -n "Executing: $2"
	for a in "${@:3}"; do
		echo -n " '$(echo -n $a | tr '\n' ' ')'"
	done
	$2 "${@:3}" 2>&1 | tee $LOGDIR/${task}.log
	duration=$SECONDS
	echo "$task $duration" | tee -a $LOGDIR/times.log
}

# assuming already logged in a the moment
# TODO: test to see if login is required
#az login

# make sure the resource group does not exist
if [ "$(az group exists --name $resource_group)" = "true" ]; then
	echo "Error: Resource group already exists"
	exit 1
fi

# create the resource group
execute "create_resource_group" az group create --name "$resource_group" --location "$location"

parameters=$(cat << EOF
{
	"vmSku": {
		"value": "$vmSku"
	},
	"vmssName": {
		"value": "$vmssName"
	},
	"computeNodeImage": {
		"value": "$computeNodeImage"
	},
	"instanceCount": {
		"value": $instanceCount
	},
	"rsaPublicKey": {
		"value": "$rsaPublicKey"
	}
}
EOF
)

# deploy azhpc
execute "deploy_azhpc" az group deployment create \
    --resource-group "$resource_group" \
    --template-uri "https://raw.githubusercontent.com/edwardsp/azhpc/master/azuredeploy.json" \
    --parameters "$parameters"

public_ip=$(az network public-ip list --resource-group "$resource_group" --query [0].dnsSettings.fqdn | sed 's/"//g')
execute "get_hosts" ssh hpcuser@${public_ip} nmapForHosts
execute "show_bad_nodes" ssh hpcuser@${public_ip} testForBadNodes

execute "delete_resource_group" az group delete --name "$resource_group" --yes

