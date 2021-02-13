#!/bin/bash


sudo yum install -y python-tripleoclient

echo -e "[DEFAULT]
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
#TODO(skatlapa): add param to override masq" > ~/undercloud.conf


openstack undercloud install

source /home/stack/stackrc
openstack network list


