#!/bin/bash
# web_cert_expires.sh v1.0-STABLE | Andy Saputra <yacsap@gmail.com>
# put this script on your ExternalScripts=/usr/lib/zabbix/externalscripts (/etc/zabbix/zabbix_server.conf)
# import zbx_web_cert_expires_templates.xml, then Host group: Supplementary Services and Template: SSL Certificate Checks will appears.

FQDN="$1"
PORT="$2"

if [ "$#" != "1" ]
then
        echo "Usage: <fqdn/hostname/ip> <port>"
        exit 1
fi

if [ "" == "$PORT" ]
then
        PORT="443"
fi

EXPIRES=$(echo | /usr/bin/openssl s_client -connect $FQDN:$PORT 2>/dev/null | /usr/bin/openssl x509 -noout -enddate | cut -d'=' -f2 | xargs -0 -L1 -I input /bin/date -d'input' +'%s')
NOW=$(date +'%s')

let DIFF_SEC=$EXPIRES-$NOW
let DIFF_DAYS=$DIFF_SEC/86400

echo $DIFF_DAYS;
