# Function to check if the script is running with elevated privileges
function Is-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If not running as administrator, relaunch the script with elevated privileges
if (-not (Is-Admin)) {
    # Relaunch the script with admin privileges
    $arguments = "& '" + $myinvocation.MyCommand.Definition + "'"
    Start-Process powershell -ArgumentList "Start-Process powershell -ArgumentList $arguments -Verb runAs" -Verb runAs
    exit
}

# Define log file path
$LogFile = "./logs/init_docker.log"

# Function to log messages with timestamps
function Log {
    $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $args"
    $message | Tee-Object -FilePath $LogFile -Append
}

Log "Starting docker compose..."
$docker_result = &  docker compose up --build -d 2>&1
$ret = $LASTEXITCODE
if ($ret -eq 0) {
    Log "Docker compose completed successfully."
} else {
    Log "Docker compose failed with error code $ret. Output: $docker_result"
    exit $ret
}

Start-Sleep -Seconds 7

Log "Executing docker exec..."

# Create HDFS cryptodata directory
Log "Creating hdfs cryptodata"
$docker_exec_result =   docker exec -it namenode hadoop fs -mkdir -p /cryptodata/ 2>&1
$ret_exe = $LASTEXITCODE
if ($ret_exe -eq 0) {
    Log "HDFS directory cryptodata has been created"
} else {
    Log "Docker exec failed with error code $ret_exe. Output: $docker_exec_result"
    exit $ret_exe
}

# Create HDFS ventes directory
Log "Creating hdfs ventes"
$docker_exec_result2 =   docker exec -it namenode hadoop fs -mkdir -p /ventes/ 2>&1
$ret_exe2 = $LASTEXITCODE
if ($ret_exe2 -eq 0) {
    Log "HDFS directory ventes has been created"
} else {
    Log "Docker exec failed with error code $ret_exe2. Output: $docker_exec_result2"
    exit $ret_exe2
}

# Transfer dataset (csv files)
Log "Transfer dataset (csv files)"
$docker_trans_file_result =   docker exec -it namenode bash -c 'find /myhadoop/data -name "*.csv" -exec hadoop fs -put {} /cryptodata/ \;' 2>&1
$ret_trans_file = $LASTEXITCODE
if ($ret_trans_file -eq 0) {
    Log "The crypto data csv files have been transferred successfully"
} else {
    Log "Docker exec failed with error code $ret_trans_file. Output: $docker_trans_file_result"
    exit $ret_trans_file
}

# Transfer globales sells
Log "Transfer globales sells"
$docker_trans_file_result2 =   docker exec -it namenode hadoop fs -put /myhadoop/data/ventes/ventes_globales.csv /ventes/ 2>&1
$ret_trans_file2 = $LASTEXITCODE
if ($ret_trans_file2 -eq 0) {
    Log "The globales csv file has been transferred successfully"
} else {
    Log "Docker exec failed with error code $ret_trans_file2. Output: $docker_trans_file_result2"
    exit $ret_trans_file2
}

Log "Docker exec has been done"

# Submit spark scripts
Log "Submit spark scripts"
Log "Submit app.py"
$spark_script_app =   docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/app.py
$ret_script_spark = $LASTEXITCODE
if ($ret_script_spark -eq 0) {
    Log "The script app.py has been submitted to spark master"
} else {
    Log "Error on the submit with the spark master: $spark_script_app. Exit with error $ret_script_spark"
}

Log "Submit process_sales.py"
$spark_script_process_sales =  docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/process_sales.py
$ret_script_spark2 = $LASTEXITCODE
if ($ret_script_spark2 -eq 0) {
    Log "The script process_sales.py has been submitted to spark master"
} else {
    Log "Error on the submit with the spark master: $spark_script_process_sales. Exit with error $ret_script_spark2"
}

Log "Submit process_crypto.py"
$spark_script_process_crypto =  docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/process_crypto.py
$ret_script_spark3 = $LASTEXITCODE
if ($ret_script_spark3 -eq 0) {
    Log "The script process_crypto.py has been submitted to spark master"
} else {
    Log "Error on the submit with the spark master: $spark_script_process_crypto. Exit with error $ret_script_spark3"
}

Log "Submit process_crypto.py"
try {
    $sparkScriptProcessCrypto = docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/process_crypto.py 2>&1
    Log "The script process_crypto.py has been submitted to spark master"
} catch {
    Log "Error on submitting process_crypto.py to spark master: $_"
}
Log "Executing script inside the docker"
try {
    docker exec -it spark-master sh /app/update_data.sh 2>&1
    Log "The script has been executed successfully"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

Log "Scripts submitted to the spark master."
Log "Script completed."
exit 0
