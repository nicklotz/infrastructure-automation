#/bin/bash

gcloud deployment-manager deployments create sles-sap-deployment --config sles-sap.yaml
HA_MEMBER_INIT=$(gcloud compute instances describe sles-sap-ha-1 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')
HA_MEMBER_2=$(gcloud compute instances describe sles-sap-ha-2 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')
HA_MEMBER_3=$(gcloud compute instances describe sles-sap-ha-3 --zone=us-east1-b --format='get(networkInterfaces[0].networkIP)')

HA_MEMBER_INIT_PUBLIC=$(gcloud compute instances describe sles-sap-ha-1 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
HA_MEMBER_2_PUBLIC=$(gcloud compute instances describe sles-sap-ha-2 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
HA_MEMBER_3_PUBLIC=$(gcloud compute instances describe sles-sap-ha-3 --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Resetting SSH known hosts"
sudo rm ~/.ssh/known_hosts > /dev/null

echo "Installing sshpass"
sudo apt-get install -y epel > /dev/null
sudo apt-get install -y sshpass > /dev/null

echo "Pausing 30 seconds to allow servers to complete configuration"
sleep 30s

#TODO: Automate sshpass and ssh-copy-id for key based authentication when joining cluster

sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC 'zypper ar http://download.opensuse.org/tumbleweed/repo/oss/ Tumbleweed; zypper --gpg-auto-import-keys ref; zypper in -y sshpass'
#sshpass -p "temppass" ssh -o StrictHostKeyChecking=no root@$HA_MEMBER_2_PUBLIC "echo y $HA_MEMBER_INIT temppass $HA_MEMBER_2 | ha-cluster-join"
