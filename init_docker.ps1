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

# Start Docker Compose
Log "Starting docker compose..."
$dockerResult = docker compose up --build -d 2>&1
$ret = $LASTEXITCODE
if ($ret -eq 0) {
    Log "Docker compose completed successfully."
} else {
    Log "Docker compose failed with error code $ret. Output: $dockerResult"
    exit $ret
}

Start-Sleep -Seconds 7

# Execute Docker commands
Log "Executing docker exec..."

# Create HDFS cryptodata directory
Log "Creating hdfs cryptodata"
$dockerExecResult = docker exec -it namenode hadoop fs -mkdir -p /cryptodata/ 2>&1
$retExe = $LASTEXITCODE
if ($retExe -eq 0) {
    Log "HDFS directory cryptodata has been created."
} else {
    Log "Docker exec failed with error code $retExe. Output: $dockerExecResult"
    exit $retExe
}

# Create HDFS ventes directory
Log "Creating hdfs ventes"
$dockerExecResult2 = docker exec -it namenode hadoop fs -mkdir -p /ventes/ 2>&1
$retExe2 = $LASTEXITCODE
if ($retExe2 -eq 0) {
    Log "HDFS directory ventes has been created."
} else {
    Log "Docker exec failed with error code $retExe2. Output: $dockerExecResult2"
    exit $retExe2
}

# Transfer dataset (csv files)
Log "Transfer dataset (csv files)"
$dockerTransFileResult = docker exec -it namenode bash -c 'find /myhadoop/data -name "*.csv" -exec hadoop fs -put {} /cryptodata/ \;' 2>&1
$retTransFile = $LASTEXITCODE
if ($retTransFile -eq 0) {
    Log "The crypto data csv files have been transferred successfully."
} else {
    Log "Docker exec failed with error code $retTransFile. Output: $dockerTransFileResult"
    exit $retTransFile
}

# Transfer globales sells
Log "Transfer globales sells"
$dockerTransFileResult2 = docker exec -it namenode hadoop fs -put /myhadoop/data/ventes/ventes_globales.csv /ventes/ 2>&1
$retTransFile2 = $LASTEXITCODE
if ($retTransFile2 -eq 0) {
    Log "The globales csv file has been transferred successfully."
} else {
    Log "Docker exec failed with error code $retTransFile2. Output: $dockerTransFileResult2"
    exit $retTransFile2
}

Log "Docker exec has been done."

Log "Script completed."
exit 0
