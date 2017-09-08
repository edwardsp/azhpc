my_uid=$(uuidgen | cut -c1-6)

githubUser=$(git config --get remote.origin.url | cut -d'/' -f4)
githubBranch=$(git status | head -n1 | cut -d' ' -f3)

resource_group=azhpc-${my_uid}
location="North Central US"
vmSku=Standard_H16r
vmssName=az${my_uid}
computeNodeImage=CentOS-HPC_7.1
instanceCount=16
rsaPublicKey=$(cat ~/.ssh/id_rsa.pub)

numberOfNodesToTest=(8 16)
processesPerNode=16
podKey=
