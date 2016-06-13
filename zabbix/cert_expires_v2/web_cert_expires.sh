#!/bin/bash
# web_cert_expires.sh v2.0-STABLE | Andy Saputra <yacsap@gmail.com>
# It combines both web_cert_expires.sh and web_cert_grades.sh function.
# Usage1: web_cert_expires.sh 1 google.com - checks the SSL certificate grade
# Usage2: web_cert_expires.sh google.com - checks the SSL certificate expiration
# put this script on your ExternalScripts=/usr/lib/zabbix/externalscripts (/etc/zabbix/zabbix_server.conf)
# import zbx_web_cert_grades_v2_templates.xml, then Host group: Supplementary Services and Template: SSL Certificate Checks will appears.

ACTION="$1"

re='^[0-9]+$'
if ! [[ $1 =~ $re ]] ; then
ACTION=0
fi

if [ $ACTION -eq 1 ]; then

# Checking for Certificate Grade..
domain=$2
if [ "$domain" = "" ]; then
        exit 1
fi

tmp=$(mktemp)
#TODO: trap
a=0
b=0
c=0
d=0
e=0
f=0
wget -q -O $tmp "https://api.dev.ssllabs.com/api/fa78d5a4/analyze?host=$domain&#38;publish=On&#38;clearCache=On&#38;all=done"
for word in $(sed 's/,/\n/g' $tmp | grep grade | awk -F '"' '{print $4}'); do

        if [ $word == "A" ]; then a=$((a+1)); fi
        if [ $word == "B" ]; then b=$((b+1)); fi
        if [ $word == "C" ]; then c=$((c+1)); fi
        if [ $word == "D" ]; then d=$((d+1)); fi
        if [ $word == "E" ]; then e=$((e+1)); fi
        if [ $word == "F" ]; then f=$((f+1)); fi
done
rm $tmp
if [ $f -gt 0 ]; then echo "6"
elif [ $e -gt 0 ]; then echo "5"
elif [ $d -gt 0 ]; then echo "4"
elif [ $c -gt 0 ]; then echo "3"
elif [ $b -gt 0 ]; then echo "2"
else echo "1"
fi

else
# Checking for Certificate Expiration..
FQDN="$1"
PORT="$2"

if [ "" == "$PORT" ]
then
        PORT="443"
fi

EXPIRES=$(echo | /usr/bin/openssl s_client -connect $FQDN:$PORT 2>/dev/null | /usr/bin/openssl x509 -noout -enddate | cut -d'=' -f2 | xargs -0 -L1 -I input /bin/date -d'input' +'%s')
NOW=$(date +'%s')

let DIFF_SEC=$EXPIRES-$NOW
let DIFF_DAYS=$DIFF_SEC/86400

echo $DIFF_DAYS;

fi
