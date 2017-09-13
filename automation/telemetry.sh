#!/bin/bash
required_envvars LOGDIR
telemetry_file=$LOGDIR/telemetry.json

# retrieve azure environment from the create resource group output
# $1 : log file
function kpi.get_environment()
{
    logs = $(cat $1)
    kpi.create_root 
}

function kpi.create_root()
{
   
json=$(cat << EOF
{
    "id":"$(uuidgen)",
    "subscription":"$(jq '.id' $logs | awk -F[/] '{print $3}')",
    "location":"$(jq '.location' $logs)",
    "resourceGroup":"$(jq '.name' $logs)"
}
EOF
)

    cat $json > $telemetry_file
    
}