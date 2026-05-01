#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}


Write-Host "Checking Azure Service Bus Namespace '$($config.SB_NAMESPACE)'..."

az servicebus namespace show --name $config.SB_NAMESPACE --resource-group $config.RESOURCE_GROUP 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Azure Service Bus Namespace '$($config.SB_NAMESPACE)' already exists."
}
else {
    Write-Host "Creating Azure Service Bus Namespace '$($config.SB_NAMESPACE)'..."
    az servicebus namespace create `
        --name $config.SB_NAMESPACE `
        --resource-group $config.RESOURCE_GROUP `
        --location $config.LOCATION `
        --sku $config.SB_SKU `

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Azure Service Bus Namespace '$($config.SB_NAMESPACE)' created successfully."
    }
    else {
        Write-Host "Error: Failed to create Azure Service Bus Namespace '$($config.SB_NAMESPACE)'."
        exit 1
    }
}

Write-Host "Creating a Service Bus Queue '$($config.SB_QUEUE_NAME)' in Namespace '$($config.SB_NAMESPACE)'..."

$maxRetries = 10
$delaySeconds = 5

for ($i = 1; $i -le $maxRetries; $i++) {

    Write-Host "Attempt $i to create queue..."

    $queueExists = az servicebus queue show `
    --name $config.SB_QUEUE_NAME `
    --namespace-name $config.SB_NAMESPACE `
    --resource-group $config.RESOURCE_GROUP `
    --query "name" -o tsv 2>$null

    if ([string]::IsNullOrWhiteSpace($queueExists)) {
        Write-Host "Queue '$($config.SB_QUEUE_NAME)' does not exist. Attempting to create it..."
            az servicebus queue create `
            --name $config.SB_QUEUE_NAME `
            --namespace-name $config.SB_NAMESPACE `
            --resource-group $config.RESOURCE_GROUP 2>&1 | Out-Null
    }
    else {
        Write-Host "$([char]0x2713) Queue '$($config.SB_QUEUE_NAME)' already exists."
        break
    }

    Write-Host "Not ready yet (exit code $LASTEXITCODE), retrying in $delaySeconds seconds..."
    Start-Sleep -Seconds $delaySeconds
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Queue '$($config.SB_QUEUE_NAME)' created successfully in Namespace '$($config.SB_NAMESPACE)'."    
}
else {
    Write-Host "Error: Failed to create queue '$($config.SB_QUEUE_NAME)' in Namespace '$($config.SB_NAMESPACE)'."
    exit 1
}

