#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

az login

Write-Host "Create the VNet with an address space"
az network vnet create `
  --name $config.VNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --address-prefix 10.0.0.0/16

write-Host "Create a subnet for Flask"
az network vnet subnet create `
  --name $config.FLASK_SUBNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet-name $config.VNET_NAME `
  --address-prefix 10.0.1.0/24

Write-Host "Create a subnet for the .NET API"
az network vnet subnet create `
  --name $config.API_SUBNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet-name $config.VNET_NAME `
  --address-prefix 10.0.2.0/24

Write-Host "Integrate Flask App Service with its subnet"
az webapp vnet-integration add `
  --name $config.FLASK_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet $config.VNET_NAME `
  --subnet $config.FLASK_SUBNET_NAME

Write-Host "Integrate .NET API with its subnet"
az webapp vnet-integration add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet $config.VNET_NAME `
  --subnet $config.API_SUBNET_NAME

Write-Host "Restrict inbound traffic on the API to Flask's subnet only"
az webapp config access-restriction add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --rule-name "AllowFlaskSubnet" `
  --action Allow `
  --vnet-name $config.VNET_NAME `
  --subnet $config.FLASK_SUBNET_NAME `
  --priority 100

Write-Host "Deny all other inbound traffic to the API"

az webapp config access-restriction add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --rule-name "DenyAll" `
  --action Deny `
  --ip-address 0.0.0.0/0 `
  --priority 200

Write-Host "VNet setup complete. The API is now only accessible from the Flask app's subnet."

az logout