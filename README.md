# Deploying rhosp13 with octavia
# What is **Octavia**
~~~
~~~

# Phase-I - Login to the Undercloud node as a **root** user and perform below steps.

### Setting up hostname:
~~~
hostnamectl set-hostname undercloud-0-13.example.local
hostnamectl set-hostname --transient undercloud-0-13.example.local
echo "127.0.0.1 undercloud-0-13.example.local undercloud-0-13" >> /etc/hosts
~~~

### Add stack user: [Will need this for performing all admin task]

~~~
useradd stack
echo stack | passwd --stdin stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
~~~

### Provide access details for registering the system with RedHat CDN, [Helps in downloading the RPM's]

~~~
#echo  -e "\033[42;5m Enter Your RHN Username \033[0m"
username=
#echo  -e "\033[42;5m Enter Your RHN Password \033[0m"
#read -s password
password=
~~~

### Registering the nodes with RH CDN

~~~
subscription-manager register  --username $username  --password $password --force
subscription-manager list --available --all --matches="Red Hat OpenStack" > /tmp/sub.txt
pool=$(cat  /tmp/sub.txt | egrep -i "Employee SKU|pool"| awk {'print $3'} | tail -1)
subscription-manager attach --pool="$pool"
~~~

### Enable repository;

~~~
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
~~~

~~~
subscription-manager repos --disable=*
for i in $(cat rhosp13.txt) ; do subscription-manager repos --enable=$i ; done
~~~

### Before we do deployment, lets **update** te **OS**

~~~
yum update -y
~~~

### Once the **OS** is udated, **reboot** the **Undercloud/Director** node.

~~~
reboot
~~~

# Phase-II - Login as a **stack** use and perform below steps.

### install the **python-tripleoclient** and **ceph-ansible** package
~~~
sudo yum install -y python-tripleoclient
sudo yum install -y ceph-ansible
~~~

### Create the **undercloud.conf** file in the stack user's home directory and add the following content
~~~
[DEFAULT]
local_interface = eth1
local_ip = 192.168.24.1/24
undercloud_public_host = 192.168.24.2
undercloud_admin_host = 192.168.24.3
undercloud_ntp_servers=clock.redhat.com
[ctlplane-subnet]
local_subnet = ctlplane-subnet
cidr = 192.168.24.0/24
dhcp_start = 192.168.24.5
dhcp_end = 192.168.24.24
gateway = 192.168.24.1
inspection_iprange = 192.168.24.100,192.168.24.120
masquerade = true
~~~

### Install the undercloud
~~~
openstack undercloud install
~~~
# Phase-III - Login as a **stack** user and use the **stackrc** as source, perform below steps.
### Install the director images
~~~
mkdir images
cd images/
sudo yum install rhosp-director-images rhosp-director-images-ipa
~~~
### Decompress the overcloud images
~~~
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0.tar; do tar -xvf $i; done
~~~

### Upload the overcloud full images
~~~
openstack overcloud image upload --image-path /home/stack/images/
~~~
### Verify the overcloud images
~~~
openstack image list
~~~

### To retrieve the MAC address, run the following subscription
~~~
for i in $(virsh list --all| egrep -v under | awk {'print $2'} | awk 'NR>2'); do echo $i ;  virsh domiflist $i | egrep -i brbm | awk {'print $5'} ; done > 1.txt ; sed 'N;s/\n/ /'  1.txt > 2.txt ; awk '{printf "%-30s|%-18s|%-20s\n",$1,$2,$3}' 2.txt > 3.txt ; clear ; cat 3.txt
~~~

~~~
overcloud-ceph-0              |52:54:00:e0:99:c5 |                    
overcloud-ceph-1              |52:54:00:32:80:4d |                    
overcloud-ceph-2              |52:54:00:9d:c0:66 |                    
overcloud-compute-0           |52:54:00:40:99:cd |                    
overcloud-compute-1           |52:54:00:b1:e0:78 |                    
overcloud-controller-0        |52:54:00:11:7f:e3 |                    
overcloud-controller-1        |52:54:00:83:7c:fa |                    
overcloud-controller-2        |52:54:00:59:e6:e9 |  
~~~

### Prepare the instackenv.json file, which will be used to introspect the overcloud nodes
~~~
{
"nodes": [
{
"pm_user": "admin",
"mac": ["52:54:00:65:98:4c"],
"pm_type": "pxe_ipmitool",
"pm_port": "6230",
"pm_password": "redhat",
"pm_addr": "192.168.24.250",
"capabilities" : "node:ctrl-0,boot_option:local",
"name": "overcloud-controller-0"
},

{
"pm_user": "admin",
"mac": ["52:54:00:ae:09:57"],
"pm_type": "pxe_ipmitool",
"pm_port": "6231",
"pm_password": "redhat",
"pm_addr": "192.168.24.250",
"capabilities" : "node:cmpt-0,boot_option:local",
"name": "overcloud-compute-0"
},
{
"pm_user": "admin",
"mac": ["52:54:00:94:de:cd"],
"pm_type": "pxe_ipmitool",
"pm_port": "6232",
"pm_password": "redhat",
"pm_addr": "192.168.24.250",
"capabilities" : "node:ceph-0,boot_option:local",
"name": "ceph-0"
}
]
}
~~~

### Import the instackenv.json file
~~~
openstack overcloud node import ~/instackenv.json
~~~
### Check the status of the overcloud nodes, it should be in **manageable** mode
~~~
openstack baremetal node list
~~~
### Set the first disk of **Ceph node** as root disk
~~~
for i in $(openstack baremetal node list -c UUID -c Name -f value | grep -i ceph | awk {'print $1'}) ; do openstack baremetal node set --property root_device='{"name":"/dev/vda"}'  $i ; done
~~~
### Verify if the disk set as root disk
~~~
openstack baremetal node show 119a6878-77a3-4d2f-909a-24a5d7304d9f --fit
management_interface   | None
~~~

### Introspect the nodes
~~~
openstack overcloud node introspect --all-manageable --provide
~~~
### Check the status of the overcloud nodes, it should be in **available** mode
~~~
openstack baremetal node list
~~~
### Copy the templates
~~~
mkdir templates
cd /home/stack/templates
cp -r /usr/share/openstack-tripleo-heat-templates/ .
~~~
### Change the network_data.yaml and roles_data.yaml

### Render the network_data.yaml and roles-data.yaml
~~~
mkdir /home/stack/templates/rendered
cd /home/stack/templates/openstack-tripleo-heat-templates
./tools/process-templates.py -r roles_data.yaml -n network_data.yaml -o /home/stack/templates/rendered  
~~~

### Change the network-envirnmenet.yaml and roles_data file as per requirement

### Create temlates directory
~~~
mkdir /home/stack/templates/extra/
touch /home/stack/templates/extra/overcloud_images.yaml
touch /home/stack/templates/extra/local_registry_images.yaml
~~~

### Preparing containers

~~~
openstack overcloud container image prepare \
--namespace=registry.access.redhat.com/rhosp13 \
--push-destination=192.168.24.1:8787 \
--prefix=openstack- \
--tag-from-label {version}-{release} \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
--set ceph_namespace=registry.access.redhat.com/rhceph \
--set ceph_image=rhceph-3-rhel7 \
--output-env-file=/home/stack/templates/extra/overcloud_images.yaml \
--output-images-file /home/stack/templates/extra/local_registry_images.yaml
~~~
### Uploading the containers

~~~
sudo openstack overcloud container image upload \
--config-file /home/stack/templates/extra/local_registry_images.yaml --verbose
~~~

### Deployment subscription
~~~
cat v1_deploy.sh
#!/bin/bash
time openstack overcloud deploy --templates /home/stack/templates/rendered/ \
-r /home/stack/templates/rendered/roles_data.yaml \
-e /home/stack/templates/rendered/environments/network-environment.yaml \
-e /home/stack/templates/rendered/environments/network-isolation.yaml \
-e /home/stack/templates/extra/overcloud_images.yaml \
-e /home/stack/templates/rendered/environments/ceph-ansible/ceph-ansible.yaml \
-e /home/stack/templates/storage/storageinfo.yaml \
-e /home/stack/templates/extra/scheduler_hints_env.yaml \
-e /home/stack/templates/extra/node-info.yaml \
--libvirt-type qemu --timeout 120 --debug
~~~
