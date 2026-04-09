#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

az login

Write-Host "Creating Cosmos DB database..."

az cosmosdb sql database create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --name $config.DATABASE_NAME  

Write-Host "Creating Cosmos DB container..."

az cosmosdb sql container create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --database-name $config.DATABASE_NAME `
  --name $config.CONTAINER_NAME `
  --partition-key-path "/id"

Write-Host "Assigning API identity and granting access to Cosmos DB..."

$API_PRINCIPAL_ID=(az webapp identity assign `
  --name $config.APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --query principalId -o tsv)

# Grant the API read access to Cosmos DB
Write-Host "Granting API read access to Cosmos DB..."
az cosmosdb sql role assignment create `
  --account-name $config.ACCOUNT_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --role-definition-name "Cosmos DB Built-in Data Reader" `
  --principal-id $API_PRINCIPAL_ID `
  --scope "/"  

Write-Host "Cosmos DB setup complete."