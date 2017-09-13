#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

paramsFile=$1
echo "Reading parameters from: $paramsFile"
source $paramsFile
required_envvars githubUser githubBranch resource_group vmSku vmssName computeNodeImage instanceCount rsaPublicKey

benchmarkScript=$2
echo "Benchmark script: $benchmarkScript"
source $benchmarkScript

scriptname=$(basename "$0")
scriptname="${scriptname%.*}"
paramsname=$(basename "$paramsFile")
paramsname="${paramsname%.*}"
benchmarkname=$(basename "$benchmarkScript")
benchmarkname="${benchmarkname%.*}"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
LOGDIR=${scriptname}_${paramsname}_${benchmarkname}_${timestamp}
mkdir $LOGDIR
cp $paramsFile $LOGDIR

source "$DIR/telemetry.sh"

function clear_up {
	execute "delete_resource_group" az group delete --name "$resource_group" --yes
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
kpi.create_root $(get_log "create_resource_group")

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
    --template-uri "https://raw.githubusercontent.com/$githubUser/azhpc/$githubBranch/azuredeploy.json" \
    --parameters "$parameters"
kpi.update_environment $(get_log "deploy_azhpc")

public_ip=$(az network public-ip list --resource-group "$resource_group" --query [0].dnsSettings.fqdn | sed 's/"//g')

execute "get_hosts" ssh hpcuser@${public_ip} nmapForHosts
working_hosts=$(sed -n "s/.*sshin=\([^;]*\).*/\1/p" $(get_log "get_hosts"))
retry=1
while [ "$retry" -lt "6" -a "$working_hosts" -ne "$instanceCount" ]; do
        sleep 60
        execute "get_hosts_retry_$retry" ssh hpcuser@${public_ip} nmapForHosts
        working_hosts=$(sed -n "s/.*sshin=\([^;]*\).*/\1/p" $(get_log "get_hosts_retry_$retry"))
        let retry=$retry+1
done

if [ "$working_hosts" -ne "$instanceCount" ]; then
        echo "Error: all hosts are not accessible with ssh."
        clear_up
fi

execute "show_bad_nodes" ssh hpcuser@${public_ip} testForBadNodes

# run the benchmark function
run_benchmark

clear_up
