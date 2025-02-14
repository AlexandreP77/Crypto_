#!/bin/bash

set -e 

LOGFILE="/app/logs/init_docker.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Updating APK packages"
update_apk=$(apk upgrade --available 2>&1)
ret_update=$?
if [ "$ret_update" -eq 0 ]; then
    log "Update successful"
else 
    log "Update failed with error code $ret_update. Output: $update_apk"
    exit "$ret_update"
fi

log "Installing tini, openrc, and busybox-initscripts"
add_apk=$(apk add --no-cache tini openrc busybox-initscripts 2>&1)
ret_add=$?
if [ "$ret_add" -eq 0 ]; then
    log "Installation successful"
else 
    log "Installation failed with error code $ret_add. Output: $add_apk"
    exit "$ret_add"
fi

if [ -f "/app/update_data_by_fiveteen_minutes.sh" ]; then
    cp /app/update_data_by_hours.sh /etc/periodic/15min/
    chmod a+x /etc/periodic/15min/update_data_by_fiveteen_minutes.sh
    log "Scheduled script copied and permissions set"
else
    log "Error: /app/update_data_by_fiveteen_minutes.sh not found!"
    exit 1
fi

log "Starting cron service"
/usr/sbin/crond -b -l 2

exit 0
