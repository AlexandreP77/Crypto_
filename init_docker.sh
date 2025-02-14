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
sudo docker exec -it namenode hadoop fs -rm /cryptodata/ventes_globales.csv
ret_trans_file=$?
if [ $ret_trans_file -eq 0 ]; then
    log "The crypto data csv files have been transferred successfully"
else 
    log "Docker exec failed with error code $ret_trans_file. Output: $docker_trans_file_result"
    exit $ret_trans_file
fi

log "Transfer globales sells"
docker_trans_file_result2="$(sudo docker exec -it namenode hadoop fs -put /myhadoop/data/ventes/ventes_globales.csv /ventes/ 2>&1)"
ret_trans_file2=$?
if [ $ret_trans_file2 -eq 0 ]; then
    log "The globales csv file have been transfered successfully"
else 
    log "Docker exec failed with error code $ret_trans_file2. Output: $docker_trans_file_result2"
    exit $ret_trans_file2
fi
log "Docker exec have been done"

log "Submit spark scripts"
log "Submit crypto_batch.py"
spark_script_app="$(sudo docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/crypto_batch.py 2>&1)"
ret_script_spark=$?
if [ $ret_script_spark -eq 0 ]; then
    log "The script crypto_batch.py have been submit to spark master"
else
    log "Error on the submit with the spark master: $spark_script_app. Exit with error $ret_script_spark"
fi

log "Submit crypto_streaming.py"
spark_script_process_sales="$(sudo docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/crypto_streaming.py 2>&1)"
ret_script_spark2=$?
if [ $ret_script_spark2 -eq 0 ]; then
    log "The script crypto_streaming.py have been submit to spark master"
else
    log "Error on the submit with the spark master: $spark_script_process_sales. Exit with error $ret_script_spark2"
fi

log "Executing script inside the docker"
docker_trans_file_result2="$(sudo docker exec -it spark-master sh /app/update_data.sh)"
ret_trans_file2=$?
if [ $ret_trans_file2 -eq 0 ]; then
    log "The script have been executed successfully"
else 
    log "Docker exec failed with error code $ret_trans_file2. Output: $docker_trans_file_result2"
    exit $ret_trans_file2
fi

log "Script completed."
exit 0