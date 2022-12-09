$idpath = "models.txt"
if (Test-Path $idpath) {
    $identifiers = Get-Content $idpath
}Else{
    Write-Output "Please create models.txt and add a model identifier in each line."
    pause
    exit
}
foreach ($identifier in $identifiers) {
$url = 'https://api.ipsw.me/v4/device/' + $identifier + '?type=ipsw'
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$models = $response | ConvertFrom-Json
$firmwares = $models | Select-Object -ExpandProperty firmwares
$latestfirmware = $firmwares[0]
$ipswURL = $latestfirmware.url
$ipswFile = $ipswURL.Split("/")
$ipswbuild = $latestfirmware.build
Switch ($identifier.Substring(0,4)) {
  iPad {$updatePath = '%appdata%\Apple Computer\iTunes\iPad Software Updates\'}
  iPho {$updatePath = '%appdata%\Apple Computer\iTunes\iPhone Software Updates\'}
}
$ipswPath = $updatePath + $ipswFile[-1]
$version = $latestfirmware.version
$model = $latestfirmware.identifier
if (Test-Path $ipswPath) {
    Write-Output "$version for $model is already downloaded, skipping."
    }Else{
    Write-Output "File not found, downloading $version for $model ..."
    if (Invoke-WebRequest $ipswURL -OutFile $ipswPath) {
        Write-Output "Download completed."
        } else {
        Write-Output "Download error."
        }
    }
}