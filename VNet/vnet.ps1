#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Create the VNet with an address space"

az network vnet create `
  --name $config.VNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --address-prefix 10.0.0.0/16

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) VNet created: $config.VNET_NAME with address space"
}
else {
    Write-Host "Error: Failed to create VNet"
    exit 1
}  

write-Host "Create a subnet for Flask"

az network vnet subnet create `
  --name $config.FLASK_SUBNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet-name $config.VNET_NAME `
  --address-prefix 10.0.1.0/24

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Flask subnet created: $config.FLASK_SUBNET_NAME"
}
else {
    Write-Host "Error: Failed to create Flask subnet"
    exit 1
}  

Write-Host "Create a subnet for the .NET API"

az network vnet subnet create `
  --name $config.API_SUBNET_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet-name $config.VNET_NAME `
  --address-prefix 10.0.2.0/24

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) API subnet created: $config.API_SUBNET_NAME"
}
else {
    Write-Host "Error: Failed to create API subnet"
    exit 1
}  

Write-Host "Integrate Flask App Service with its subnet"

az webapp vnet-integration add `
  --name $config.FLASK_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet $config.VNET_NAME `
  --subnet $config.FLASK_SUBNET_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Flask App Service integrated with subnet: $config.FLASK_SUBNET_NAME"
}
else {
    Write-Host "Error: Failed to integrate Flask App Service with subnet"
    exit 1
}  

Write-Host "Integrate .NET API with its subnet"

az webapp vnet-integration add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --vnet $config.VNET_NAME `
  --subnet $config.API_SUBNET_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) API App Service integrated with subnet: $config.API_SUBNET_NAME"
}
else {
    Write-Host "Error: Failed to integrate .NET API with subnet"
    exit 1
}  

Write-Host "Restrict inbound traffic on the API to Flask's subnet only"

az webapp config access-restriction add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --rule-name "AllowFlaskSubnet" `
  --action Allow `
  --vnet-name $config.VNET_NAME `
  --subnet $config.FLASK_SUBNET_NAME `
  --priority 100

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Inbound traffic restricted to Flask's subnet successfully."
}
else {
    Write-Host "Error: Failed to create access restriction for Flask's subnet"
    exit 1
}  

Write-Host "Deny all other inbound traffic to the API"

az webapp config access-restriction add `
  --name $config.API_APP_NAME `
  --resource-group $config.RESOURCE_GROUP `
  --rule-name "DenyAll" `
  --action Deny `
  --ip-address 0.0.0.0/0 `
  --priority 200

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) All other inbound traffic to the API denied successfully."
}
else {
    Write-Host "Error: Failed to deny inbound traffic to the API"
    exit 1
}  

Write-Host "$([char]0x2713) VNet setup complete. The API is now only accessible from the Flask app's subnet."