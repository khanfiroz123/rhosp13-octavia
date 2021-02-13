#!/bin/bash
time openstack overcloud deploy --templates /home/stack/templates/rendered/ \
-r /home/stack/templates/rendered/roles_data.yaml \
-e /home/stack/templates/rendered/environments/network-environment.yaml \
-e /home/stack/templates/rendered/environments/network-isolation.yaml \
-e /home/stack/overcloud_images.yaml \
-e /home/stack/templates/rendered/environments/ceph-ansible/ceph-ansible.yaml \
-e /home/stack/templates/storage/storageinfo.yaml \
-e /home/stack/templates/extra/scheduler_hints_env.yaml \
-e /home/stack/templates/extra/node-info.yaml \
--libvirt-type qemu --timeout 120 --debug 

