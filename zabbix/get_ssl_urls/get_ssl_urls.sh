#! /bin/bash
# get_ssl_urls.sh v1.0-STABLE | Andy Saputra <yacsap@gmail.com>
# put this script on your ExternalScripts=/usr/lib/zabbix/externalscripts (/etc/zabbix/zabbix_server.conf)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATE=`date +%Y-%m-%d:%H:%M:%S`

cat $DIR/ssl_urls.txt

echo $DATE > $DIR/ssl_last_check.txt
