#!/bin/bash

workspace_id=$LOG_ANALYTICS_WORKSPACE_ID
key=$LOG_ANALYTICS_KEY

logName=$1

if [ -d /proc/fs/lustre/mdt ]; then
    content=$(lmtmetric -m mdt | jq --slurp --raw-input '
        split(";") |
        {
            "hostname":.[1],
            "loadavg":$loadavg|tonumber,
            "cpu":.[2]|tonumber,
            "memory":.[3]|tonumber,
            "uuid":.[4],
            "filesfree":.[5]|tonumber,
            "filestotal":.[6]|tonumber,
            "kbytesfree":.[7]|tonumber,
            "kbytestotal":.[8]|tonumber,
            "recov_str":.[9]
        }
        ' --arg loadavg $(cut -f1 -d' ' /proc/loadavg)
    )
else
    content=$(lmtmetric -m ost | jq --slurp --raw-input '
        split(";")
        |
        {
            "hostname":.[1],
            "loadavg":$loadavg|tonumber,
            "cpu":.[2]|tonumber,
            "memory":.[3]|tonumber,
            "uuid":.[4],
            "filesfree":.[5]|tonumber,
            "filestotal":.[6]|tonumber,
            "kbytesfree":.[7]|tonumber,
            "kbytestotal":.[8]|tonumber,
            "read_bytes":.[9]|tonumber,
            "write_bytes":.[10]|tonumber,
            "iops":.[11]|tonumber,
            "num_exports":.[12]|tonumber,
            "lock_count":.[13]|tonumber,
            "grant_rate":.[14]|tonumber,
            "cancel_rate":.[15]|tonumber,
            "connect":.[16]|tonumber,
            "reconnect":.[17]|tonumber,
            "recov_str":.[18]
        }
        ' --arg loadavg $(cut -f1 -d' ' /proc/loadavg)
    )
fi

content_len=${#content}

rfc1123date="$(date -u +%a,\ %d\ %b\ %Y\ %H:%M:%S\ GMT)"

string_to_hash="POST\n${content_len}\napplication/json\nx-ms-date:${rfc1123date}\n/api/logs"
utf8_to_hash=$(echo -n "$string_to_hash" | iconv -t utf8)

signature="$(echo -ne "$utf8_to_hash" | openssl dgst -sha256 -hmac "$(echo "$key" | base64 --decode)" -binary | base64)"
auth_token="SharedKey $workspace_id:$signature"

curl -s -S \
    -H "Content-Type: application/json" \
    -H "Log-Type: $logName" \
    -H "Authorization: $auth_token" \
    -H "x-ms-date: $rfc1123date" \
    -X POST \
    --data "$content" \
    https://$workspace_id.ods.opinsights.azure.com/api/logs?api-version=2016-04-01
