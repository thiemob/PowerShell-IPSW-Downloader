# Function to get the appropriate update path based on device type
function Get-UpdatePath {
    param (
        [string]$Identifier
    )
    
    switch ($Identifier.Substring(0,4)) {
        "iPad" { return "$env:APPDATA\Apple Computer\iTunes\iPad Software Updates\" }
        "iPho" { return "$env:APPDATA\Apple Computer\iTunes\iPhone Software Updates\" }
        default { throw "Unsupported device type: $Identifier" }
    }
}

# Function to clean up legacy firmware files
function Remove-LegacyFirmware {
    param (
        [string]$UpdatePath,
        [string]$ModelIdentifier,
        [string]$CurrentVersion
    )
    
    try {
        $legacyFiles = Get-ChildItem -Path $UpdatePath -Filter "*.ipsw" | 
            Where-Object { $_.Name -like "*$ModelIdentifier*" -and $_.Name -notlike "*$CurrentVersion*" }
        
        foreach ($file in $legacyFiles) {
            Write-Output "Removing legacy firmware: $($file.Name)"
            Remove-Item -Path $file.FullName -Force
        }
    }
    catch {
        Write-Warning "Failed to remove legacy firmware: $_"
    }
}

# Function to download firmware
function Get-Firmware {
    param (
        [string]$Identifier
    )
    
    try {
        $url = "https://api.ipsw.me/v4/device/$Identifier?type=ipsw"
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $models = $response | ConvertFrom-Json
        $firmwares = $models | Select-Object -ExpandProperty firmwares
        return $firmwares[0]
    }
    catch {
        Write-Error "Failed to fetch firmware information for $Identifier : $_"
        return $null
    }
}

# Main script
$idpath = "models.txt"
if (-not (Test-Path $idpath)) {
    Write-Error "Please create models.txt and add a model identifier in each line."
    exit 1
}

$identifiers = Get-Content $idpath
foreach ($identifier in $identifiers) {
    Write-Output "Processing $identifier..."
    
    $firmware = Get-Firmware -Identifier $identifier
    if ($null -eq $firmware) { continue }
    
    $ipswURL = $firmware.url
    $ipswFile = $ipswURL.Split("/")[-1]
    $version = $firmware.version
    $model = $firmware.identifier
    
    $updatePath = Get-UpdatePath -Identifier $identifier
    $ipswPath = Join-Path $updatePath $ipswFile
    
    if (Test-Path $ipswPath) {
        Write-Output "$version for $model is already downloaded, skipping."
    }
    else {
        Write-Output "Downloading $version for $model..."
        try {
            $ProgressPreference = 'Continue'
            Invoke-WebRequest $ipswURL -OutFile $ipswPath
            Write-Output "Download completed successfully."
            
            # Clean up legacy firmware files after successful download
            Remove-LegacyFirmware -UpdatePath $updatePath -ModelIdentifier $model -CurrentVersion $version
        }
        catch {
            Write-Error "Failed to download firmware: $_"
        }
    }
}