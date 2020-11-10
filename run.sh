#!/bin/bash

# Feedme
# 14-05-2019

checkSNMP () {
#       $1 - ip
#echo "checkSNMP runned for $1" >> $logFile

        /bin/snmpget -v1 -c $community $1 .1.3.6.1.2.1.1.1.0 | sed "s/SNMPv2-MIB::sysDescr.0 = STRING: /$var /"
}

checkExist () {
#       $1 - ip
#       $2 - group

#echo "checkExist runned for $1 $2" >> $logFile

ip=$1";"

        for line in $(cat $script_path/dictionary)
                do
                        if [ $line = "END" ]; then 
                                break
                        else
                                group=`echo $line | /bin/cut -f 3 -d ';'`
                                if [[ $group != $2 ]]; then
                                        if grep -rni --quiet $ip $path/$group/router.db; then
                                                sed -i "/$1/d" $path/$group/router.db
                                                echo "UPDATE DB: removed $ip from $group" >> $logFile
                                        fi
                                fi
                        fi
                done
}

checkVendor () {
#       $1 - ip
#       $2 - expect snmp sanswer
#       $3 - script
#       $4 - group name

#echo "checkVendor runned for $1 $2 $3 $4" >> $logFile

snmpAnswer=$(checkSNMP $1)

db_path="$path/$4/router.db"

        if [[ $snmpAnswer == *"$2"* ]]; then
                device="$1;$3;up"

        # grep -rni 172.17.40.10 ./routers/*/router.db

                if grep --quiet $device $db_path; then
                        echo "INFO: $device already in db" >> $logFile
                        checkExist $1 $4
                        res=true
                else
			mkdir -p "$path/$4"
                        echo $device >> $db_path
                        echo "UPDATE DB: $device add in $db_path" >> $logFile
                        checkExist $1 $4
                        res=true
                fi
        elif [[ $snmpAnswer == "" ]]; then
                echo "WARNING: $1 answered on icmp but not answer on snmp" >> $logFile
        res=true
        fi
}

runCheck() {
# $1 - network
#echo "runCheck runned for $1" >> $logFile

for var in $(cat $1)
do
        res=false
	
        for i in $(cat $script_path/dictionary)
        do
                if [ $res != true ] && [ $i = "END" ]; then
                        Answer=$(checkSNMP $var)
                        echo "WARNING: $Answer not founded in dictionary" >> $logFile
                        break
                else
                        snmp=`echo $i | /bin/cut -f 1 -d';'`
                        script=`echo $i | /bin/cut -f 2 -d';'`
                        group=`echo $i | /bin/cut -f 3 -d';'`

                        if [[ $res != true ]]; then
                                checkVendor $var "$snmp" "$script" "$group" 
		        else
                                break
                        fi
                fi

        done

done

}

checkAlive() {
#echo "checkAlive runned for $1 $2 $3" >> $logFile
# $1 - network
# $2 - gateway
# $3 - mask

echo "" > $script_path/networks/$1
/usr/sbin/fping -a -g -q -r 1 $1/$3 >> $script_path/networks/$1
sed -i "/$2$/d" $script_path/networks/$1

for black in $(cat $script_path/blacklist)
do
        sed -i "/$black$/d" $script_path/networks/$1
        echo "INFO: $black removed from lists" >> $logFile
done

runCheck $script_path/networks/$1
}

addNetworks() {

        for net in $(cat $script_path/subnets)
        do
                address=`echo $net | /bin/cut -f 1 -d ';'`
                gateway=`echo $net | /bin/cut -f 2 -d ';'`
		mask=`echo $net | /bin/cut -f 3 -d ';'`
                checkAlive "$address" "$gateway" "$mask" &

        done
}


IFS=$'\n' #fix wrong cat output

date=$(date +%F_%H-%M-%S)
logFile=/home/rancid/rancidShell.$date
community=$1
path=$2
script_path=/etc/rancid/rancid_updater_v2
addNetworks
wait



