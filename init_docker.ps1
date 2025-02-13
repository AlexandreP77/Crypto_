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

$LOGFILE = "./logs/init_docker.log"

function LogMessage {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Write-Host $logEntry
    Add-Content -Path $LOGFILE -Value $logEntry
}

LogMessage "Starting docker compose..."
try {
    $dockerResult = & docker compose up --build -d 2>&1
    LogMessage "Docker compose completed successfully."
} catch {
    LogMessage "Docker compose failed with error: $_"
    exit 1
}

Start-Sleep -Seconds 7

LogMessage "Executing docker exec..."
LogMessage "Creating hdfs cryptodata"
try {
    & docker exec -it namenode hadoop fs -mkdir -p /cryptodata/ 2>&1
    LogMessage "HDFS directory cryptodata has been created"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

LogMessage "Creating hdfs ventes"
try {
    & docker exec -it namenode hadoop fs -mkdir -p /ventes/ 2>&1
    LogMessage "HDFS directory ventes has been created"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

LogMessage "Transfer dataset (csv files)"
try {
    & docker exec -it namenode bash -c "find /myhadoop/data -name '*.csv' -exec hadoop fs -put {} /cryptodata/ \;" 2>&1
    LogMessage "The crypto data csv files have been transferred successfully"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

LogMessage "Transfer globales sells"
try {
    & docker exec -it namenode hadoop fs -put /myhadoop/data/ventes/ventes_globales.csv /ventes/ 2>&1
    LogMessage "The globales csv file has been transferred successfully"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

LogMessage "Submit spark scripts"
LogMessage "Submit app.py"
try {
    $sparkScriptApp = & docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/app.py 2>&1
    LogMessage "The script app.py has been submitted to spark master"
} catch {
    LogMessage "Error on submitting app.py to spark master: $_"
}

LogMessage "Submit process_sales.py"
try {
    $sparkScriptProcessSales = & docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/process_sales.py 2>&1
    LogMessage "The script process_sales.py has been submitted to spark master"
} catch {
    LogMessage "Error on submitting process_sales.py to spark master: $_"
}

LogMessage "Submit process_crypto.py"
try {
    $sparkScriptProcessCrypto = & docker exec -it spark-master /spark/bin/spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1 /app/process_crypto.py 2>&1
    LogMessage "The script process_crypto.py has been submitted to spark master"
} catch {
    LogMessage "Error on submitting process_crypto.py to spark master: $_"
}

LogMessage "Executing script inside the docker"
try {
    & docker exec -it spark-master sh /app/update_data.sh 2>&1
    LogMessage "The script has been executed successfully"
} catch {
    LogMessage "Docker exec failed with error: $_"
    exit 1
}

LogMessage "Script completed."
exit 0
