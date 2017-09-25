my_uid=$(uuidgen | cut -c1-6)

githubUser=$(git config --get remote.origin.url | cut -d'/' -f4)
githubBranch=$(git status | sed -n 's/[# ]*On branch \([^ ]\+\)/\1/p')

resource_group=SETNAME-azhpc-${my_uid}
location="North Central US"
vmSku=Standard_H16r
vmssName=az${my_uid}
computeNodeImage=CentOS-HPC_7.1
instanceCount=4
rsaPublicKey=$(cat ~/.ssh/id_rsa.pub)

numberOfNodesToTest="8 16"
processesPerNode=16
podKey=

azLogin=
azPassword=
azTenant=

rootLogDir='.'

logToStorage=false
logStorageAccountName=
logStorageContainerName=
logStoragePath=
logStorageSasKey=
cosmos_account=
cosmos_database=
cosmos_collection=
cosmos_key=
