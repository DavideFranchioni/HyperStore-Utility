#!/bin/bash

STAGING_DIR=$(grep installscript /opt/cloudian/conf/cloudianservicemap.json | tr '"' '\n' | grep cloudianInstall.sh | sed  's/\/cloudianInstall.sh//')
KEYFILE=$(grep INSTALL_SSH_KEY_FILE $STAGING_DIR/CloudianInstallConfiguration.txt | cut -d "=" -f2 | sed 's/.\///')
SSHKEY="${STAGING_DIR}/${KEYFILE}"
HOSTLIST="${STAGING_DIR}/hosts.cloudian"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cat<< EOF
This script allows you to check the status of Cloudian HyperStore services at the cluster level.
unlike the cloudianServices.sh it shows the minimum necessary information and allows to verify if the service is active or not, allowing a better visibility thanks to color.
green running, yellow stopped.
This script is very useful on large clusters where it is usually difficult to verify the status with the cloudianServices.sh
EOF

for node in $(awk '{print $3}' ${HOSTLIST})
do
	echo -e "\n-----------Connecting to node to perform Services Checks ${BLUE}${node}${NC}-----------\n"
  listprocess=`ssh -i ${SSHKEY} -n ${node} "ls /etc/init.d/*cloudian* | sed -r 's/^.+\///'|grep -v 'cloudian-local'"`
  for element in $listprocess
  do
      status=`ssh -i ${SSHKEY} -n ${node} "/etc/init.d/$element status|grep 'pid\|stopped'"`
      status=${status//running/${GREEN}running${NC}}
      status=${status//stopped/${YELLOW}stopped${NC}}
      echo -e "${status}"
  done
done
echo "Created By Davide Franchioni www.davidefranchioni.it"
