my_uid=$(uuidgen | cut -c1-6)

githubUser=$(git config --get remote.origin.url | cut -d'/' -f4)
githubBranch=$(git rev-parse --abbrev-ref HEAD)

resource_group=SETNAME-azhpc-${my_uid}
location="North Central US"
vmSku=Standard_H16r
vmssName=az${my_uid}
computeNodeImage=CentOS-HPC_7.1
instanceCount=4
processesPerNode=16
rsaPublicKey=$(cat ~/.ssh/id_rsa.pub)

numberOfNodesToTest="8 16"
podKey=

linpack_N=69120
linpack_P=1
linpack_Q=2
linpack_NB=192

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

# openfoam parameters
storageAccountName=paedwar
storageContainerName=azhpc
storageBenchmarkPath=benchmarks
storageBenchmarkName=motorbike82M
storageSasKey=
