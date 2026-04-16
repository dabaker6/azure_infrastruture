#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Creating resource group '$($config.RESOURCE_GROUP)'..."
$rgexists = az group exists --name $config.RESOURCE_GROUP
if ($rgexists -eq "false") {
    az group create --name $config.RESOURCE_GROUP --location $config.LOCATION --output none
    Write-Host "$([char]0x2713) Resource group created: $config.RESOURCE_GROUP"
}
else {
    Write-Host "$([char]0x2713) Resource group already exists: $config.RESOURCE_GROUP"
}