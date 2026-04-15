#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Assigning API identity and granting access to Cosmos DB..."

$API_PRINCIPAL_ID=(az webapp identity assign `
  --name $config.APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --query principalId -o tsv)

# Grant the API read access to Cosmos DB
Write-Host "Granting API read access to Cosmos DB..."

$SCOPE = "/dbs/$($config.DATABASE_NAME)/colls/$($config.CONTAINER_NAME)"

az cosmosdb sql role assignment create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --role-definition-name $config.RBAC_ROLE_NAME `
  --principal-id $API_PRINCIPAL_ID `
  --scope $SCOPE
  
Write-Host "Print Role Assignments for Cosmos DB..."

az cosmosdb sql role assignment list --account-name "dev-246" --resource-group "rg-dev-personal-website" --query "[].[principalId,roleDefinitionId]" --output tsv

Write-Host "API access to Cosmos DB configured successfully."