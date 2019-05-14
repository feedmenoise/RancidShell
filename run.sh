#!/bin/bash

# Feedme
# 14-05-2019

checkSNMP () {
#	$1 - ip

	snmpget -v1 -c $community $1 .1.3.6.1.2.1.1.1.0 | sed "s/SNMPv2-MIB::sysDescr.0 = STRING:/$var/"
}

checkExist () {
#	$1 - ip
#	$2 - group

ip=$1";" 

	for line in $(cat ./dictionary)
		do
				group=`echo $line | cut -f 3 -d ';'`
				if [[ $group != $2 ]]; then
					if grep -rni --quiet $ip $path/$group/router.db; then
						sed -i "/$1/d" $path/$group/router.db
						echo "removed $ip from $group" >> $logFile
					fi
				fi
		done
}

checkVendor () {
#	$1 - ip
#	$2 - expect snmp sanswer
#	$3 - script
#	$4 - group name

snmpAnswer=$(checkSNMP $1)

db_path="$path/$4/router.db"

	if [[ $snmpAnswer == *"$2"* ]]; then
		device="$1;$3;up"

	# grep -rni 172.17.40.10 ./routers/*/router.db

		if grep --quiet $device $db_path; then
			echo "$device already in db" >> $logFile
			checkExist $1 $4
			res=true
		else
			echo $device >> $db_path
			echo "$device add in $db_path" >> $logFile
			checkExist $1 $4
			res=true
		fi
	elif [[ $snmpAnswer == "" ]]; then
		echo "$1 answered on icmp but not answer on snmp" >> $logFile
        res=true
	fi
}

runCheck() {
# $1 - network

for var in $(cat $1)
do
	res=false

	for i in $(cat ./dictionary)
	do
		snmp=`echo $i | cut -f 1 -d';'`
		script=`echo $i | cut -f 2 -d';'`
		group=`echo $i | cut -f 3 -d';'`

		if [[ $res != true ]]; then
			checkVendor $var "$snmp" "$script" "$group"
		else
			break
		fi

	done	

done	

}

checkAlive() {
# $1 - network
# $2 - gateway

echo "" > ./networks/$1
fping -a -g -q -r 1 $1/24 >> ./networks/$1
sed -i "/$2/d" ./networks/$1

runCheck ./networks/$1 
}

addNetworks() {

	for net in $(cat ./subnets)
	do
		address=`echo $net | cut -f 1 -d ';'`
		gateway=`echo $net | cut -f 2 -d ';'`

		checkAlive "$address" "$gateway" &

	done
}


IFS=$'\n' #fix wrong cat output

date=$(date +%F_%H-%M-%S)
logFile=rancidShell.$date
community=$1
path=$2
addNetworks 
wait


