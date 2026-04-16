function New-UniqueString {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Inputs
    )
    
    # Concatenate all input strings
    $combinedInput = $Inputs -join ''
    
    # Compute SHA-256 hash
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combinedInput))
    $sha256.Dispose()
    
    # Convert to lowercase hex string and take first 13 characters
    $hashString = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    return $hashString.Substring(0, 13)
}

#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

$ASP_NAME = "$($config.ASP_NAME)-$(New-UniqueString -Inputs @($config.ASP_NAME))"
$IMAGE_NAME_TAG = "$($config.IMAGE_NAME):$($config.IMAGE_TAG)"

Write-Host "Deploying container to Azure App Service..."

#Check ASP and create if it doesn't exist
Write-Host "Checking Azure App Service Plan '$ASP_NAME'..."

az appservice plan show --name $ASP_NAME --resource-group $config.RESOURCE_GROUP 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Azure App Service Plan '$($ASP_NAME)' already exists."
}
else {
    Write-Host "Creating Azure App Service Plan '$($ASP_NAME)'..."
    az appservice plan create `
        --name $ASP_NAME `
        --resource-group $config.RESOURCE_GROUP `
        --sku $config.ASP_SKU `
        --is-linux
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Azure App Service Plan created: $ASP_NAME"    
    }
    else {
        Write-Host "Error: Failed to create Azure App Service Plan"
        exit 1
    }
}

#Check webapp and create if it doesn't exist
Write-Host "Checking if Azure Web App '$($config.FLASK_APP_NAME)' exists..."

az webapp show --resource-group $config.RESOURCE_GROUP --name $config.FLASK_APP_NAME 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Azure Web App '$($config.FLASK_APP_NAME)' already exists. Please choose a different name or delete the existing Web App before deploying. Or select a different script"
    Exit
}

#Create webapp
Write-Host "Creating Azure Web App '$($config.FLASK_APP_NAME)'..."
az webapp create `
    --name $config.FLASK_APP_NAME `
    --resource-group $config.RESOURCE_GROUP `
    --plan $ASP_NAME `
    --container-image-name "$($config.ACR_NAME).azurecr.io/$IMAGE_NAME_TAG"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App created: $config.FLASK_APP_NAME"    
}
else {
    Write-Host "Error: Failed to create Web App"
    exit 1
}

#Configure Web App to use Managed Identity for ACR authentication
Write-Host "Assigning Managed Identity to Web App '$($config.FLASK_APP_NAME)'..."

az webapp identity assign `
    --name $config.FLASK_APP_NAME `
    --resource-group $config.RESOURCE_GROUP

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Managed Identity assigned to Web App: $($config.FLASK_APP_NAME)"    
}
else {
    Write-Host "Error: Failed to assign Managed Identity to Web App"
    exit 1
}

#Get the Principal ID of the Web App's Managed Identity
$PRINCIPAL_ID = az webapp identity show `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --query principalId `
    --output tsv

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Retrieved Principal ID for Web App: $PRINCIPAL_ID"    
}
else {
    Write-Host "Error: Failed to retrieve Principal ID for Web App"
    exit 1
}

#Get the ACR resource ID
$ACR_ID = az acr show `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.ACR_NAME `
    --query id `
    --output tsv

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Retrieved ACR ID: $ACR_ID"    
}
else {
    Write-Host "Error: Failed to retrieve ACR ID"
    exit 1
}

Write-Host "Assigning 'AcrPull' role to Web App's Managed Identity for ACR access..."

$maxRetries = 10
$delaySeconds = 5
$success = $false

for ($i = 1; $i -le $maxRetries; $i++) {

    Write-Host "Attempt $i to assign role..."

    az role assignment create `
        --assignee $PRINCIPAL_ID `
        --scope $ACR_ID `
        --role AcrPull 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Role assignment succeeded"
        break
    }

    Write-Host "Not ready yet (exit code $LASTEXITCODE), retrying in $delaySeconds seconds..."
    Start-Sleep -Seconds $delaySeconds
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Role assignment created: Web App can pull from ACR"    
}
else {
    Write-Host "Error: Failed to create role assignment for Web App to pull from ACR"
    exit 1
}

#Configure Web App to use ACR with Managed Identity
az webapp config set `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --acr-use-identity true `
    --acr-identity [system]

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App configured to use Managed Identity for ACR authentication"    
}
else {
    Write-Host "Error: Failed to configure Web App to use Managed Identity for ACR authentication"
    exit 1
}

#Configure Web App to use the container image from ACR
az webapp config container set `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --container-image-name "$($config.ACR_NAME).azurecr.io/$IMAGE_NAME_TAG" `
    --container-registry-url "https://$($config.ACR_NAME).azurecr.io"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App container configuration updated"        
}
else {
    Write-Host "Error: Failed to update Web App container configuration"
    exit 1
}

##App settings for Flask app

Write-Host "Configuring Web App application settings for Flask app..."
az webapp config appsettings set `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --settings "SCM_DO_BUILD_DURING_DEPLOYMENT=true" "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" "MATCHES_API_BASE_URL=$($config.API_APP_NAME)"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App application settings updated"       
}
else {
    Write-Host "Error: Failed to update Web App application settings"
    exit 1
}    

Write-Host "Ensure always on..."
az webapp config set `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --always-on true

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App 'Always On' setting enabled"       
}
else {
    Write-Host "Error: Failed to enable 'Always On' setting for Web App"
    exit 1
}  

write-Host "Configuring Web App logging for container output..."

az webapp log config `
    --resource-group $config.RESOURCE_GROUP `
    --name $config.FLASK_APP_NAME `
    --docker-container-logging filesystem

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Web App logging configured for container output"       
}
else {
    Write-Host "Error: Failed to configure Web App logging for container output"
    exit 1
}  

Write-Host "Deployment complete. You can access your Flask app at: https://$($config.FLASK_APP_NAME).azurewebsites.net"

Invoke-RestMethod -Uri "https://$($config.FLASK_APP_NAME).azurewebsites.net/health" | ConvertTo-Json -Depth 10

