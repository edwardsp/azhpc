#!/bin/bash

account=$1
database=$2
collection=$3
key=$4
jsonFile=$5

date_now="$(date -u +%a,\ %d\ %b\ %Y\ %H:%M:%S\ GMT)"
text="post\ndocs\ndbs/$database/colls/$collection\n$(echo "$date_now" | tr '[:upper:]' '[:lower:]')\n\n"
signature="$(echo -ne "$text" | openssl dgst -sha256 -hmac "$(echo "$key" | base64 --decode)" -binary | base64)"
auth_token="$(echo -n "type=master&ver=1.0&sig=$signature" | jq -s -R -r @uri)"

curl -s \
        -H "x-ms-version: 2015-12-16" \
        -H "x-ms-date: $date_now" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: $auth_token" \
        -X POST \
        --data "@$jsonFile" \
        https://$account.documents.azure.com:443/dbs/$database/colls/$collection/docs \
        | jq

