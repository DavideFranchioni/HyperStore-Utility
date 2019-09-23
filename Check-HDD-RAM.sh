#!/bin/bash

#This script help you to check the HDD and RAM error at cluster level on a Cloudian 
#HyperStore, the script need to be runned in the puppet-master node
#It will autodiscover the staging-directory, so you can run anywhere.



STAGING_DIR=$(grep installscript /opt/cloudian/conf/cloudianservicemap.json | tr '"' '\n' | grep cloudianInstall.sh | sed  's/\/cloudianInstall.sh//')
KEYFILE=$(grep INSTALL_SSH_KEY_FILE $STAGING_DIR/CloudianInstallConfiguration.txt | cut -d "=" -f2 | sed 's/.\///')
SSHKEY="${STAGING_DIR}/${KEYFILE}"
HOSTLIST="${STAGING_DIR}/hosts.cloudian"
VERSION=`service cloudian-s3 version | grep Version | sed 's/Version:\s*//'`
LOG_PATH=/tmp/Hardwarecheck$$.log
LOG="tee -a ${LOG_PATH}"
DATE="date +'%Y-%m-%d-%H:%M:%S'"
DISK_HEAD="Filesystem                      Size  Used Avail Use% Mounted on"

echo "Cluster informations:"|${LOG}
echo "Stagin directory is: ${STAGING_DIR}"|${LOG}
echo "Keyfile name is: ${KEYFILE}"|${LOG}
echo "ssh key  full path is: ${SSHKEY}"|${LOG}
echo "host list full path is: ${HOSTLIST}"|${LOG}
echo "installed version is: ${VERSION}"|${LOG}
echo "log are saved in ${LOG_PATH}"
for node in $(awk '{print $3}' ${HOSTLIST})
do
	echo -e "\n-----------Connecting to node to perform Harwdare Checks ${node}-----------\n"|${LOG}
	echo "${DISK_HEAD}"|${LOG}
	DISK_LIST=`ssh -i ${SSHKEY} -n ${node} "df -h | grep "/cloudian" | sort -k6"`
	echo "${DISK_LIST}"|${LOG}
	ERR=`ssh -i ${SSHKEY} -n ${node} "dmesg -T|grep 'I/O\|DIMM'"`
	echo "`${DATE}` ${ERR:-Nothing Found}"|${LOG}
done
echo "`${DATE}` Scan completed, log are saved in ${LOG_PATH}"
echo "Created By Davide Franchioni www.davidefranchioni.it"
