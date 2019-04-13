#/bin/bash

echo "Spawning GCloud instances"
gcloud deployment-manager deployments create sles-sap-deployment --config sles-sap.yaml > /dev/null 2> /dev/null
HA_MEMBER_INIT=$(gcloud compute instances describe sles-sap-ha-1 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')
HA_MEMBER_2=$(gcloud compute instances describe sles-sap-ha-2 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')
HA_MEMBER_3=$(gcloud compute instances describe sles-sap-ha-3 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')

HA_MEMBER_INIT_PUBLIC=$(gcloud compute instances describe sles-sap-ha-1 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
HA_MEMBER_2_PUBLIC=$(gcloud compute instances describe sles-sap-ha-2 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
HA_MEMBER_3_PUBLIC=$(gcloud compute instances describe sles-sap-ha-3 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Resetting SSH known hosts"
sudo rm ~/.ssh/known_hosts > /dev/null 2> /dev/null

echo "Installing sshpass for connecting to instances" 
sudo apt-get install -y epel > /dev/null 2> /dev/null
sudo apt-get install -y sshpass > /dev/null 2> /dev/null

echo "Completing initial server configuration"
sleep 30s

#TODO: Automate sshpass and ssh-copy-id for key based authentication when joining cluster

echo "Refreshing package repositories"
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC 'zypper ar http://download.opensuse.org/tumbleweed/repo/oss/ Tumbleweed; zypper --gpg-auto-import-keys ref; zypper in -y sshpass' > /dev/null 2> /dev/null
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_3_PUBLIC 'zypper ar http://download.opensuse.org/tumbleweed/repo/oss/ Tumbleweed; zypper --gpg-auto-import-keys ref; zypper in -y sshpass' > /dev/null 2> /dev/null

echo "Configuring cluster membership"
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC 'ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""' > /dev/null 2> /dev/null
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC "sshpass -p temppass ssh-copy-id -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no root@$HA_MEMBER_INIT" > /dev/null 2> /dev/null
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC "ha-cluster-join -qy -c $HA_MEMBER_INIT"
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_3_PUBLIC 'ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""' > /dev/null 2> /dev/null
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_3_PUBLIC "sshpass -p temppass ssh-copy-id -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no root@$HA_MEMBER_INIT" > /dev/null 2> /dev/null
sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_3_PUBLIC "ha-cluster-join -qy -c $HA_MEMBER_INIT"



sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_INIT_PUBLIC "crm status"

