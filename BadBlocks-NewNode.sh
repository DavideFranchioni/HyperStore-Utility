#!/bin/bash

cat << EOF
This is a simple script to check the badblocks
of disks on new nodes first to add them to the
Cloudian HyperStore cluster
EOF

file=/tmp/output$$.log
echo "Logfile...$file"
echo "Executing df -h on the system .... " | tee -a $file

df -h | grep "Filesystem" | tee -a $file
df -h | grep "/cloudian" | sort -k6 | tee -a $file
read -r -p "Are you sure to start the disks scan? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
	echo "Starting disk damaged sectors...." | tee -a $file
	for i in `df -h | grep "/cloudian" | sort -k6 | awk '{ print $1}'`
	do
		echo "Start scan on disk $i..."| tee -a $file
					date | tee -a $file
		badblocks -b 4096 -c 65536 -v $i 2>&1 | tee -a $file
	done
else
    echo "Bye Bye!"| tee -a $file
fi
echo "Created By Davide Franchioni www.davidefranchioni.it"
