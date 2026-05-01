#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Setting access to Service Bus"

Write-Host "Checking if Azure Service Bus Namespace '$($config.SB_NAMESPACE)' exists..."

$queueId = az servicebus queue show `
    --name $config.SB_QUEUE_NAME `
    --namespace-name $config.SB_NAMESPACE `
    --resource-group $config.RESOURCE_GROUP `
    --query id -o tsv  2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure Service Bus Queue '$($config.SB_QUEUE_NAME)' does not exist. Please choose a different name or create the queue first."
    Exit
}

Write-Host "Retrieving container app id..."

$PRINCIPAL_ID = az containerapp show `
    --name $config.CONTAINER_APP_NAME `
    --resource-group $config.RESOURCE_GROUP `
    --query identity.principalId -o tsv 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Container app Id not found. Please ensure the container app exists and try again."
    Exit
}

Write-Host "Assigning 'Azure Service Bus Data Receiver' role to container app identity for Service Bus Namespace '$($config.SB_NAMESPACE)'..."

az role assignment create `
    --assignee-object-id $PRINCIPAL_ID `
    --role "Azure Service Bus Data Receiver" `
    --scope $queueId 2>$null | Out-Null

if($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Role assignment successful."
}
else {
    Write-Host "Error: Failed to assign role. Please ensure you have the necessary permissions to assign roles in this subscription and try again."
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
