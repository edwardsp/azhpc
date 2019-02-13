#!/bin/bash

# variables to read in
resource_group=
location=
name=
vnet=
subnet=
nodes=

# automatic variables
user="$(whoami)"
key="$(<$HOME/.ssh/id_rsa.pub)"

# fixed variables
image="OpenLogic:CentOS:7.6:7.6.20181219"
sku=Standard_L8s_v2

# deploy vmss for all nodes
vmss_size=$(($nodes+1))
az vmss create \
    --resource-group $resource_group \
    --image "$image" \
    --name $name \
    --admin-username $user \
    --subnet $subnet \
    --vnet-name $vnet \
    --single-placement-group true \
    --accelerated-networking true \
    --ssh-key-value "$key" \
    --vm-sku $sku \
    --location $location \
    --instance-count $vmss_size \
    --lb ""

az vmss list-instances \
    --resource-group $resource_group \
    --name $name \
    --query [].osProfile.computerName \
    --output tsv \
    > ${name}_all_nodes.txt

head -n 1 ${name}_all_nodes.txt > ${name}_master_node.txt
tail -n $nodes ${name}_all_nodes.txt > ${name}_oss_nodes.txt

master_node=$(<${name}_master_node.txt)

cat <<EOF_OUTER >tmp_deploy_lustre_install_pkgs.sh
#!/bin/bash

cat << EOF >/etc/yum.repos.d/LustrePack.repo
[lustreserver]
name=lustreserver
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7.6.1810/server/
enabled=1
gpgcheck=0

[e2fs]
name=e2fs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
enabled=1
gpgcheck=0

[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7.6.1810/client/
enabled=1
gpgcheck=0
EOF

yum -y install kernel-3.10.0-957.el7_lustre.x86_64 lustre kmod-lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount e2fsprogs lustre-tests

reboot
EOF_OUTER
chmod +x tmp_deploy_lustre_install_pkgs.sh

for node in $(<${name}_all_nodes.txt); do
    scp tmp_deploy_lustre_install_pkgs.sh $node:.
done

WCOLL=${name}_all_nodes.txt pdsh chmod +x tmp_deploy_lustre_install_pkgs.sh
WCOLL=${name}_all_nodes.txt pdsh sudo ./tmp_deploy_lustre_install_pkgs.sh

echo "Waiting 2 minutes for nodes to come back after reboot"
sleep 120

WCOLL=${name}_master_node.txt pdsh sudo mkfs.lustre --fsname=LustreFS --mgs --mdt --backfstype=ldiskfs --reformat /dev/nvme0n1 --index 0
WCOLL=${name}_master_node.txt pdsh sudo mkdir /mnt/mgsmds
WCOLL=${name}_master_node.txt pdsh 'echo "/dev/nvme0n1 /mnt/mgsmds lustre noatime,nodiratime,nobarrier 0 2" | sudo tee -a /etc/fstab'
WCOLL=${name}_master_node.txt pdsh sudo mount -a

for node in $(<${name}_all_nodes.txt); do
    scp tmp_setup_master.sh $node:.
done

WCOLL=${name}_master_node.txt pdsh chmod +x ./tmp_setup_master.sh
WCOLL=${name}_master_node.txt pdsh sudo ./tmp_setup_master.sh

let N=0
for oss_node in $(<${name}_oss_nodes.txt); do

    ssh $oss_node sudo mkfs.lustre --fsname=LustreFS --backfstype=ldiskfs --reformat --ost --mgsnode=${master_node} --index=$N /dev/nvme0n1
    let N=N+1

done

WCOLL=${name}_oss_nodes.txt pdsh sudo mkdir /mnt/oss
WCOLL=${name}_oss_nodes.txt pdsh 'echo "/dev/nvme0n1 /mnt/oss lustre noatime,nodiratime,nobarrier 0 2" | sudo tee -a /etc/fstab'
WCOLL=${name}_oss_nodes.txt pdsh sudo mount -a

cat <<EOF_OUTER >tmp_start_lustre.sh
#!/bin/bash

cat << EOF > /etc/lnet.conf
net:
    - net type: tcp
      local NI(s):
        - nid: \$(hostname -I | sed 's/ //g')@tcp0
          interfaces:
              0: eth0
          tunables:
              peer_timeout: 180
              peer_credits: 128
              peer_buffer_credits: 0
              credits: 1024
EOF

chkconfig lnet on
chkconfig lustre --add
chkconfig lustre on
EOF_OUTER

for node in $(<${name}_all_nodes.txt); do
    scp tmp_start_lustre.sh $node:.
done

WCOLL=${name}_all_nodes.txt pdsh chmod +x ./tmp_start_lustre.sh
WCOLL=${name}_master_node.txt pdsh sudo ./tmp_start_lustre.sh
WCOLL=${name}_oss_nodes.txt pdsh sudo ./tmp_start_lustre.sh


