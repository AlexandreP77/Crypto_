#!/bin/bash

LOGFILE="/app/logs/logs_data/init_docker.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Submit data.py"
spark_script_yes="$(/spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/data.py)"
ret_script_spark4=$?
if [ $ret_script_spark4 -eq 0 ]; then
    log "The script data.py have been submit to spark master"
else
    log "Error on the submit with the spark master: $spark_script_yes. Exit with error $ret_script_spark4"
    exit $spark_script_yes
fi 
log "Script done"

exit 0