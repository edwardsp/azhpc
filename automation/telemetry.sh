#!/bin/bash
required_envvars LOGDIR
telemetry_file=$LOGDIR/telemetry.json

# retrieve azure subscription, location and resource group from the create resource group output
# $1 : log file
function kpi.create_root()
{
    logs=$1   

json=$(cat << EOF
{
    "id":"$(uuidgen)",
    "subscription":"$(jq '.id' $logs | awk -F[/] '{print $3}')",
    "location":$(jq '.location' $logs),
    "resourceGroup":$(jq '.name' $logs)
}
EOF
)

    echo $json > $telemetry_file
    
}

# retrieve vmsize, OS, instanceCount, provision status and time, timestamp from the deploy template output
# $1 : log file
function kpi.update_environment()
{
    logs=$1   
    vmSize=$(jq '.properties.parameters.vmSku.value' $logs)
    computeNodeImage=$(jq '.properties.parameters.computeNodeImage.value' $logs)
    instanceCount=$(jq '.properties.parameters.instanceCount.value' $logs)
    provisioningState=$(jq '.properties.provisioningState' $logs)
    deploymentTimestamp=$(jq '.properties.timestamp' $logs)

    jq '.vmSize=$vmSize' $telemetry_file > $telemetry_file
    jq '.computeNodeImage=$computeNodeImage' $telemetry_file > $telemetry_file
    jq '.instanceCount=$instanceCount' $telemetry_file > $telemetry_file
    jq '.provisioningState=$provisioningState' $telemetry_file > $telemetry_file
    jq '.deploymentTimestamp=$deploymentTimestamp' $telemetry_file > $telemetry_file
}


# append a json fragment to the telemetry 
# $1 : json fragment
function json.appendFragment()
{
    jsonfragment=$1
    
}