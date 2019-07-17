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
TABLE='Hostname,Admin,IAM,Cassandra,HyperStore,Mon,Cred,QOS,S3,CMC,Agent
'

echo -e "This script allows you to check the status of Cloudian HyperStore services at the cluster level.
unlike the cloudianServices.sh it shows the minimum necessary information and allows to verify if the service is active or not, allowing a better visibility thanks to color.
green ${GREEN}running${NC}, yellow${YELLOW} stopped${NC}.
This script is very useful on large clusters where it is usually difficult to verify the status with the cloudianServices.sh"

#method
function printTable()
{
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
							  #table=${table//✓/${GREEN}✓${NC}}
								#table=${table//✗/${RED}✗${NC}}
								#table=${table//pid/${YELLOW}pid${NC}}
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}


for node in $(awk '{print $3}' ${HOSTLIST})
do
	ADMIN=' '
	IAM=' '
	CASSANDRA=' '
	HYPERSTORE=' '
	REDISMON=' '
	REDISCRED=' '
	REDISQOS=' '
	S3=' '
	CMC=' '
	AGENT=' '

	echo -e "\n-----------Connecting to node to perform Services Checks ${BLUE}${node}${NC}-----------\n"
  listprocess=`ssh -i ${SSHKEY} -n ${node} "ls /etc/init.d/*cloudian* | sed -r 's/^.+\///'|grep -v 'cloudian-local'"`
  for element in $listprocess
  do


      status=`ssh -i ${SSHKEY} -n ${node} "/etc/init.d/$element status|grep 'pid\|stopped'"`

      if [[ $element == *"cloudian-s3"* ]]; then
			LINE=$(echo "${status}"|wc -l)
      #echo "${LINE}"
				if [[ $LINE = "2" ]]; then
					S3=$(echo "${status}"| sed -n 1p)
					ADMIN=$(echo "${status}"| sed -n 2p)

			elif [[ $LINE = "3" ]]; then
					S3=$(echo "${status}"| sed -n 1p)
					ADMIN=$(echo "${status}"| sed -n 2p)
					IAM=$(echo "${status}"| sed -n 3p)
				fi
		  fi

			#s3 status
			if [[ $S3 == *"running"* ]]; then
			S3="✓"
			elif [[ $S3 == *"stopped"* ]]; then
			S3="✗"
			elif [[ $S3 == *"pid file"* ]]; then
			S3="pid"
			fi

			#admin status
			if [[ $ADMIN == *"running"* ]]; then
			ADMIN="✓"
		  elif [[ $ADMIN == *"stopped"* ]]; then
			ADMIN="✗"
			elif [[ $ADMIN == *"pid file"* ]]; then
			ADMIN="pid"
			fi

      #IAM status
			if [[ $LINE = "3" ]]; then
			if [[ $status == *"running"* ]]; then
			IAM="✓"
			elif [[ $status == *"stopped"* ]]; then
			IAM="✗"
		  elif [[ $IAM == *"pid file"* ]]; then
	  	IAM="pid"
			fi
		  fi

			case $status in
				*"Cassandra"*)
				if [[ $status == *"running"* ]]; then
  			CASSANDRA="✓"
			  elif [[ $status == *"stopped"* ]]; then
  			CASSANDRA="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			CASSANDRA="pid"
			  fi;;
				*"HyperStore"*)
				if [[ $status == *"running"* ]]; then
  			HYPERSTORE="✓"
			  elif [[ $status == *"stopped"* ]]; then
  			HYPERSTORE="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			HYPERSTORE="pid"
			  fi;;
				*"monitor"*)
				if [[ $status == *"running"* ]]; then
  			REDISMON="✓"
			  elif [[ $status == *"stopped"* ]]; then
  			REDISMON="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			REDISMON="pid"
			  fi;;
				*"Credentials"*)
				if [[ $status == *"running"* ]]; then
  			REDISCRED="✓"
			  elif [[ $status == *"stopped"* ]]; then
  			REDISCRED="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			REDISCRED="pid"
			  fi;;
				*"QOS"*)
				if [[ $status == *"running"* ]]; then
  			REDISQOS="✓"
			  elif [[ $status == *"stopped"* ]]; then
  			REDISQOS="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			REDISQOS="pid"
			  fi;;
				*"Agent"*)
				if [[ $status == *"running"* ]]; then
  			AGENT="✓"
			  elif [[ $status == *"stopped"* ]]; then
  		  AGENT="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			AGENT="pid"
			  fi;;
				*"Management"*)
				if [[ $status == *"running"* ]]; then
  			CMC="✓"
			  elif [[ $status == *"stopped"* ]]; then
  		  CMC="✗"
			  fi
				if [[ $status == *"pid file"* ]]; then
  			CMC="pid"
			  fi;;
				esac

      status=${status//running/${GREEN}running${NC}}
      status=${status//stopped/${YELLOW}stopped${NC}}
			status=${status//pid file exists/pid file ${YELLOW}exists${NC}}
      echo -e "${status}"
  done

	TABLE+="${node},${ADMIN},${IAM},${CASSANDRA},${HYPERSTORE},${REDISMON},${REDISCRED},${REDISQOS},${S3},${CMC},${AGENT}
"
	#echo "${node},${ADMIN},${IAM},${CASSANDRA},${HYPERSTORE},${REDISMON},${REDISCRED},${REDISQOS},${S3},${CMC},${AGENT}
#"
done
printTable ',' "$(echo  "${TABLE}")"
#echo  "${TABLE}"
echo "Created By Davide Franchioni www.davidefranchioni.it"
