# RancidShell
Shell for Rancid

Add to /etc/cron.d/rancid

```
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/home/rancid
# Run config differ hourly
0 1 * * * /etc/rancid/rancid_updater_v2/run.sh /var/rancid
0 3 * * * rancid /usr/libexec/rancid/rancid-run
```


Where: 
```/var/rancid```  - directory to rancid reps


