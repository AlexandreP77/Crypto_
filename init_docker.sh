#!/bin/bash

LOGFILE="./logs/init_docker.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Starting docker compose..."
docker_result="$(sudo docker compose up --build -d 2>&1)"
ret=$?
if [ $ret -eq 0 ]; then
    log "Docker compose completed successfully."
else
    log "Docker compose failed with error code $ret. Output: $docker_result"
    exit $ret
fi

sleep 7

log "Executing docker exec..."
log "Creating hdfs cryptodata"
docker_exec_result="$(sudo docker exec -it namenode hadoop fs -mkdir -p /cryptodata/ 2>&1)"
ret_exe=$?
if [ $ret_exe -eq 0 ]; then
    log "HDFS directory cryptodata have been created"
else 
    log "Docker exec failed with error code $ret_exe. Output: $docker_exec_result"
    exit $ret_exe
fi

log "Creating hdfs ventes"
docker_exec_result2="$(sudo docker exec -it namenode hadoop fs -mkdir -p /ventes/ 2>&1)"
ret_exe2=$?
if [ $ret_exe -eq 0 ]; then
    log "HDFS directory ventes have been created"
else 
    log "Docker exec failed with error code $ret_exe2. Output: $docker_exec_result2"
    exit $ret_exe2
fi

log "Transfer dataset (csv files)"
docker_trans_file_result="$(sudo docker exec -it namenode hadoop fs)"

log "Script completed."
exit 0
