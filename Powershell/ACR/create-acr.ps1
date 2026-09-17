#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Creating Azure Container Registry '$config.ACR_NAME'..."
az acr create `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.ACR_NAME `
    --sku Basic `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) ACR created: $config.ACR_NAME"
    Write-Host "  Login server: $config.ACR_NAME.azurecr.io"
}
else {
    Write-Host "Error: Failed to create ACR"
    exit 1
}

Write-Host "$([char]0x2713) Azure Container Registry '$($config.ACR_NAME)' created successfully."
