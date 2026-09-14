#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Creating Cosmos DB database..."

az cosmosdb sql database create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --name $config.DATABASE_NAME  

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Cosmos DB database created: $config.DATABASE_NAME"
}
else {
    Write-Host "Error: Failed to create Cosmos DB database"
    exit 1
}

Write-Host "Creating Cosmos DB container..."

az cosmosdb sql container create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --database-name $config.DATABASE_NAME `
  --name $config.CONTAINER_NAME `
  --partition-key-path "/id"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Cosmos DB container created: $config.CONTAINER_NAME"
}
else {
    Write-Host "Error: Failed to create Cosmos DB container"
    exit 1
}
Write-Host "$([char]0x2713) Cosmos DB setup complete."