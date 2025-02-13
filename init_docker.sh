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
docker_trans_file_result="$(sudo docker exec -it namenode bash -c 'find /myhadoop/data -name "*.csv" -exec hadoop fs -put {} /cryptodata/ \;')"
ret_trans_file=$?
if [ $ret_trans_file -eq 0 ]; then
    log "The crypto data csv files have been transferred successfully"
else 
    log "Docker exec failed with error code $ret_trans_file. Output: $docker_trans_file_result"
    exit $ret_trans_file
fi

log "Transfer globales sells"
docker_trans_file_result2="$(sudo docker exec -it namenode hadoop fs -put /myhadoop/data/ventes/ventes_globales.csv /ventes/)"
ret_trans_file2=$?
if [ $ret_trans_file2 -eq 0 ]; then
    log "The globales csv file have been transfered successfully"
else 
    log "Docker exec failed with error code $ret_trans_file2. Output: $docker_trans_file_result2"
    exit $ret_trans_file2
fi
log "Docker exec have been done"

log "Script completed."
exit 0