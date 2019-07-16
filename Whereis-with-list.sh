#!/bin/bash
log=/tmp/WhereIs$$.log
echo "Log saved in $log"
cat << EOF
This is a simple script to get all fragments/replica for 
Cloudian HyperStore cluster given list of objects, it works using hsstool.
just pass the file name to the script and it will log all :)
EOF

if [ -z "$*" ];
  for obj in `awk '{print $1}' $1` 
  do
    echo "`date` im finding $obj"|tee -a $log
    /opt/cloudian/bin/hsstool whereis $obj |grep file|tee -a $log
    echo "-------------------------------------------------------"|tee -a $log
  done
  echo "Created By Davide Franchioni www.davidefranchioni.it"
  exit 0
then 
echo "`date`No args"|tee -a $log
echo "Created By Davide Franchioni www.davidefranchioni.it"
fi
