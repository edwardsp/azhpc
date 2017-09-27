#!/bin/sh

SRC_RG=azcathpcrg
SRC_AZURE_STORAGE_ACCOUNT=$1
TGT_AZURE_STORAGE_ACCOUNT=$2

# Get a storage key for the storage account
SRC_STORAGE_KEY=$(az storage account keys list -g $SRC_RG -n $SRC_AZURE_STORAGE_ACCOUNT --query "[?keyName=='key1'] | [0].value" -o tsv)
echo $SRC_AZURE_STORAGE_ACCOUNT, $STORAGE_KEY
# Get a storage key for the storage account
TGT_STORAGE_KEY=$(az storage account keys list -g $SRC_RG -n $TGT_AZURE_STORAGE_ACCOUNT --query "[?keyName=='key1'] | [0].value" -o tsv)
echo $TGT_AZURE_STORAGE_ACCOUNT, $TGT_STORAGE_KEY

for i in `az storage container list --account-name $SRC_AZURE_STORAGE_ACCOUNT --account-key $SRC_STORAGE_KEY --output table | awk '{print $1}'| sed '1,2d' | sed '/^$/d'` ; do
    if (az storage container exists \
         --name $i \
         --account-name $TGT_AZURE_STORAGE_ACCOUNT \
         --account-key $TGT_STORAGE_KEY >/dev/null ); then

         az storage container create \
            --name $i \
            --account-name $TGT_AZURE_STORAGE_ACCOUNT \
            --account-key $TGT_STORAGE_KEY
         echo "container name: $i is created..."
    fi

    for j in `az storage blob list --container-name $i --account-name $SRC_AZURE_STORAGE_ACCOUNT --account-key $SRC_STORAGE_KEY --output table | awk '{print $1}'| sed '1,2d' | sed '/^$/d'` ; do
       echo "blob name: $j found "

       if   ( az storage blob copy start \
         --source-account-key $SRC_STORAGE_KEY \
         --source-account-name $SRC_AZURE_STORAGE_ACCOUNT \
         --source-container $i \
         --source-blob $j \
         --account-name $TGT_AZURE_STORAGE_ACCOUNT \
         --account-key $TGT_STORAGE_KEY \
         --destination-blob $j \
         --destination-container $i  ); then

         echo "Files $j inside the $i have been copied..."
       else
         echo "Unable to copy the files $j inside the  $i." && exit 1
       fi
    done
done

