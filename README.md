# RancidShell
Shell for Rancid

Add to crontab from Rancid user
0 0 * * * /etc/rancid/rancid_updater_v2/run.sh public /etc/rancid/var 

Where: 
public - snmp ro community
/etc/rancid/var - directory to rancid reps
