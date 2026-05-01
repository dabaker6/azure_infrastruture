#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

az containerapp show --name $config.CONTAINER_APP_NAME --resource-group $config.RESOURCE_GROUP 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure Container App '$($config.CONTAINER_APP_NAME)' does not exist. Please choose a different name or create the container app first. Or select a different script."
    exit 1
}

$CONTAINER_APP_ID = az containerapp show `
    --name $config.CONTAINER_APP_NAME `
    --resource-group $config.RESOURCE_GROUP `
    --query id -o tsv 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Container app Id not found. Please ensure the container app exists and try again."
    Exit
}

az containerapp update `
    --name $config.CONTAINER_APP_NAME `
    --resource-group $config.RESOURCE_GROUP `
    --min-replicas $config.CONTAINER_APP_MIN_REPLICAS `
    --max-replicas $config.CONTAINER_APP_MAX_REPLICAS `
    --scale-rule-name azure-servicebus-queue-rule `
    --scale-rule-type azure-servicebus `
    --scale-rule-metadata "queueName=$($config.SB_QUEUE_NAME)" `
                            "namespace=$($config.SB_NAMESPACE)" `
                            "messageCount=$($config.MESSAGE_COUNT)" `
    --scale-rule-identity system

    az containerapp show `
  --name $config.CONTAINER_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --query properties.template.scale.rules