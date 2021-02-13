#!/bin/bash
### RHOSP-13 
hostnamectl set-hostname undercloud-0-13.example.local
hostnamectl set-hostname --transient undercloud-0-13.example.local
echo "127.0.0.1 undercloud-0-13.example.local undercloud-0-13" >> /etc/hosts


useradd stack
echo stack | passwd --stdin stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack


echo  -e "\033[42;5m Enter Your RHN Username \033[0m"
read username 
echo  -e "\033[42;5m Enter Your RHN Password \033[0m"
read -s password 

subscription-manager register  --username $username  --password $password --force 
subscription-manager list --available --all --matches="Red Hat OpenStack" > sub.txt
pool=$(cat  sub.txt | egrep -i "Employee SKU|pool"| awk {'print $3'} | tail -1)
subscription-manager attach --pool="$pool"


echo  rhel-7-server-rpms > rhosp13.txt
echo  rhel-7-server-extras-rpms  >> rhosp13.txt
echo  rhel-7-server-rh-common-rpms  >> rhosp13.txt
echo  rhel-7-server-satellite-tools-6.3-rpms  >> rhosp13.txt
echo  rhel-ha-for-rhel-7-server-rpms   >> rhosp13.txt
echo  rhel-7-server-openstack-13-rpms   >> rhosp13.txt
echo  rhel-7-server-rhceph-3-osd-rpms   >> rhosp13.txt 
echo  rhel-7-server-rhceph-3-mon-rpms   >> rhosp13.txt 
echo  rhel-7-server-rhceph-3-tools-rpms   >> rhosp13.txt 
echo  rhel-7-server-openstack-13-deployment-tools-rpms   >> rhosp13.txt 
echo  rhel-7-server-nfv-rpms    >> rhosp13.txt

subscription-manager repos --disable=*
for i in $(cat rhosp13.txt) ; do subscription-manager repos --enable=$i ; done



