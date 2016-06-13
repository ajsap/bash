#!/bin/bash
# web_cert_grades.sh v0.9-RC | Andy Saputra <yacsap@gmail.com>
# put this script on your ExternalScripts=/usr/lib/zabbix/externalscripts (/etc/zabbix/zabbix_server.conf)
# import zbx_web_cert_expires_templates.xml, then Host group: Supplementary Services and Template: SSL Certificate Checks will appears.
# Original Idea: https://blog.chr.istoph.de/ssllabs-overall-rating-zabbix-check/
#
#     domain=$1
#     if [ "$domain" = "" ]; then
#     	exit 1
#     fi
#
#     tmp=$(mktemp)
#     # TODO: trap
#     wget -q -O $tmp "https://api.dev.ssllabs.com/api/fa78d5a4/analyze?host=$domain&#38;publish=On&#38;clearCache=On&#38;all=done"
#     sed 's/,/\n/g' $tmp | grep grade | awk -F '"' '{print $4}'
#     rm $tmp
#

domain=$1
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
if [ $f -gt 0 ]; then echo "F"
elif [ $e -gt 0 ]; then echo "E"
elif [ $d -gt 0 ]; then echo "D"
elif [ $c -gt 0 ]; then echo "C"
elif [ $b -gt 0 ]; then echo "B"
else echo "A"
fi
