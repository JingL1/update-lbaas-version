#!/bin/bash

# before scripts:
# VM env: mkdir -p /stack
# Local env: scp -oStrictHostKeyChecking=no update_f5_lbaas_version.sh ${username}@{ip address}:/stack
# VM env: chmod 755 update_f5_lbaas_version.sh
# VM env: sudo DRIVER=${driver_rpm_name} AGENT=${agent_rpm_name} /stack/update_f5_lbaas_version.sh

cd /stack

new_driver_RPM=${DRIVER:=unknown}
new_agent_RPM=${AGENT:=unknown}
echo "New LBaaSV2 Driver version: " ${new_driver_RPM}
echo "New Agent version: " ${new_agent_RPM}

sudo systemctl stop neutron-server
sudo systemctl stop f5-openstack-agent

# Back up neutron
mv /etc/neutron /tmp/neutron

# Uninstall
old_driver_RPM=$(rpm -qa | grep f5-openstack-lbaasv2-driver)
sudo rpm -e ${old_driver_RPM}
echo "Replaced LBaaSV2 Driver version: "  ${old_driver_RPM}
old_agent_RPM=$(rpm -qa | grep f5-openstack-agent)
sudo rpm -e ${old_agent_RPM}
echo "Replaced Agent version: " ${old_agent_RPM}

# Install new driver & agent
sudo rpm -ivh ${new_driver_RPM}
sudo rpm -ivh ${new_agent_RPM}

# Recover neutron
mkdir -p /etc/neutron_archive
DATE=$(date +"%Y%m%d%H%M")
USER=$(whoami)
mv /etc/neutron /etc/neutron_archive/neutron+$DATE+$USER
mv /tmp/neutron /etc/neutron

# Restart
sudo systemctl restart neutron-server
sudo systemctl enable f5-openstack-agent
sudo systemctl start f5-openstack-agent
echo "neutron server restart...wait for 10s please. "

sleep 10
sudo systemctl status neutron-server