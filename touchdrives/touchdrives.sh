# touchdrives.sh v1.0-macos
# designed to keep all drives spinning on Mac
# tested on macOS Sierra 10.12.3 (16D32)
# schedule it on cron, e.g.:
# ANDY-MAC:~ andy$ crontab -l
# MAILTO=""
# */5 * * * * sh /Users/andy/touchdrives.sh > /Users/andy/touchdrivescron.log

for D in /Volumes/*; do
  if [ -d "${D}" ]; then
    echo "${D}"
    touch "${D}/.touchdrive"
  fi
done
