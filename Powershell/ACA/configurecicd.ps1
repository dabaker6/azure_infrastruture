#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

write-Host "Setting up CI/CD pipeline for Azure Container App '$($config.CONTAINER_APP_NAME)' with Azure DevOps..."

write-Host "Enabling admin user for ACR '$($config.ACR_NAME)' to allow Azure DevOps to authenticate and pull images from the registry..."

az acr update --name $config.ACR_NAME --admin-enabled true

