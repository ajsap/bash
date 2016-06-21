#!/bin/bash
#######################
# disk_digest_monthly.sh v1.0 (2016-06-21)
# Andy Saputra <yacsap@gmail.com>
# this script generates a monthly report for production hard drives that had alerts in the last month and send it to specific zabbix users via email
# schedule it on cron (every 1st day of month at 9:00)
#######################


### function to convert bytes to human readable values, e.g. 1024 -> 1Kb
bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}


MYDB=zabbix
MYUSER=zabbix
MYPASS=zabbix
MYHOST=localhost
TRESHOLD=2 #warning or worse
INTERVAL="1 MONTH"
APPNAME="Filesystems"
MESSAGEFROM="dontreply@zabbix.host"
USERGROUP="Monthly report"
message=""

ARRAY=()
### here we get a list of items and their hosts which have alerts for the last period (see $INTERVAL) and in App name $APPNAME - they are drives.
read -ra vars <<< $(/usr/bin/mysql $MYDB -u$MYUSER -p$MYPASS -h$MYHOST -se "select i.key_, h.hostid,h.host from triggers t  INNER JOIN functions f ON (f.triggerid = t.triggerid) INNER JOIN items i ON (i.itemid = f.itemid) INNER JOIN hosts h on (i.hostid = h.hostid)   where t.lastchange>UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL $INTERVAL)) and t.priority > $TRESHOLD  and f.itemid in ( select ia.itemid from items_applications ia where ia.applicationid in ( select a.applicationid from applications a left join hosts h on (a.hostid = h.hostid) where a.name like '$APPNAME' and h.status=0)) and h.host not like '%DR' group by i.itemid order by lastchange desc");

cnt=$((0));
### parse result and send it to ARRAY variable
for i in "${vars[@]}"; do
[ $((cnt%3)) -eq 0 ] && tmp=$(echo $i | sed "s/^.*\[//g" | sed "s/,.*\]//g")
[ $((cnt%3)) -eq 1 ] && tmp+="#"$i
[ $((cnt%3)) -eq 2 ] && ARRAY+=($i"#"$tmp)
cnt=$((cnt+1));
done

### sort it and remove duplicates. This array in format SERVERNAME#DRIVENAME#SERVERID
IFS=$'\n' sorted=($(sort -u <<<"${ARRAY[*]}"))
lastserver=""

### start generating HTML report
message+="<html><body>This is a report for the last $INTERVAL<table>"
message+="<thead><tr><td>SERVERNAME</td><td style='text-align:right;'>DRIVE</td><td style='text-align:right;'>TOTAL SPACE</td><td style='text-align:right;'>USED SPACE</td><td style='text-align:right;'>FREE SPACE %</td></tr></thead>"
message+="<tbody>"

### generates a table row for every unique drive with alerts for last $PERIOD
for j in "${sorted[@]}"; do
servername=$(echo $j | cut -d"#" -f1)
item=$(echo $j | cut -d"#" -f2)
server=$(echo $j | cut -d"#" -f3)
totals=$(/usr/bin/mysql $MYDB -u$MYUSER -p$MYPASS -h$MYHOST -s -N  <<<"select value from history_uint where itemid= ( select i.itemid from items i left join hosts h on (h.hostid = i.hostid) where i.key_ = 'vfs.fs.size[$item,total]' and i.hostid = '$server' ) order by clock desc limit 1;")
total=$( bytesToHuman $totals )
useds=$(/usr/bin/mysql $MYDB -u$MYUSER -p$MYPASS -h$MYHOST  -s -N <<<"select value from history_uint where itemid= ( select i.itemid from items i left join hosts h on (h.hostid = i.hostid) where i.key_ = 'vfs.fs.size[$item,used]' and i.hostid = '$server' ) order by clock desc limit 1;")
used=$( bytesToHuman $useds )
pfrees=$(/usr/bin/mysql $MYDB -u$MYUSER -p$MYPASS -h$MYHOST  -s -N <<<"select value from history where itemid= ( select i.itemid from items i left join hosts h on (h.hostid = i.hostid) where i.key_ = 'vfs.fs.size[$item,pfree]' and i.hostid = '$server' ) order by clock desc limit 1;")

### remove third and next digits after comma
pfree=$(printf "%.2f" $pfrees)
if [[ $server == $lastserver ]]; then message+='<tr><td></td><td style="text-align:right;">'$item'</td><td style="text-align:right;">'$total'</td><td style="text-align:right;">'$used'</td><td style="text-align:right;">'$pfree'</td></tr>\n';
else lastserver=$server; message+='<tr><td>'$servername'</td><td style="text-align:right;">'$item'</td><td style="text-align:right;">'$total'</td><td style="text-align:right;">'$used'</td><td style="text-align:right;">'$pfree'</td></tr>\n';
fi
done

message+="</tbody></table></body></html>"


### at this point we have generated HTML report. Now we have to determine list of emails
while read line
do
	recepients+=("$line")
done < <(/usr/bin/mysql $MYDB -u$MYUSER -p$MYPASS -h$MYHOST -se "select sendto from media m left join users u on ( u.userid=m.userid ) left join users_groups ug on (ug.userid = u.userid) left join usrgrp ugr on (ugr.usrgrpid = ug.usrgrpid) where m.mediatypeid=1 and m.active=0 and ugr.name='$USERGROUP'");
for k in "${recepients[@]}"; do
echo -e "Sending message to $k\n";

### sending this digest to every found email address
echo -e $message | /usr/bin/mail \
-a "From: $MESSAGEFROM" \
-a "MIME-Version: 1.0" \
-a "Content-Type: text/html" \
-s "[Zabbix] Disks report for the last $INTERVAL" \
$k
done

### done :)
