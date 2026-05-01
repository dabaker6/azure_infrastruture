function Select-FilePath {
    param (
        [string]$Description = "Select a file"
    )
    Add-Type -AssemblyName System.Windows.Forms
    $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $fileBrowser.Title = $Description        
    $fileBrowser.InitialDirectory = Get-Location    
    if ($fileBrowser.ShowDialog() -eq "OK") {
        return $fileBrowser.FileName
    } else {
        Write-Host "No file selected. Exiting script."
        exit
    }
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

write-Host "Deploying container to Azure Container Apps..."

write-Host "Checking if Azure Container App Environment '$($config.ACA_ENV)' exists..."
az containerapp env show `
    --name $config.ACA_ENV `
    --resource-group $config.RESOURCE_GROUP `
    --query id -o tsv 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure Container App Environment '$($config.ACA_ENV)' does not exist. Please choose a different name or create the environment first."
    Exit
}

write-Host "Azure Container App Environment '$($config.ACA_ENV)' exists. Proceeding with deployment..."
$acrServer = "$($config.ACR_NAME).azurecr.io"
$containerImageFQDN = "$acrServer/$($config.IMAGE_NAME_TAG)"

az acr repository show --name $config.ACR_NAME --image $config.IMAGE_NAME_TAG 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Container image '$($containerImageFQDN)' isn't available in '$($config.ACR_NAME)'."    
    Write-Host "Please ensure the image is built and pushed to the registry before deploying. Or select a different script"
    Exit
}

write-Host "Container image '$($containerImageFQDN)' is available. Proceeding with deployment..."

write-Host "Checking if Azure Container App '$($config.ACA_APP_NAME)' exists..."
az containerapp show --name $config.ACA_APP_NAME --resource-group $config.RESOURCE_GROUP 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Azure Container App '$($config.ACA_APP_NAME)' already exists. Please choose a different name or delete the existing app before deploying. Or select a different script"
    Exit
}
else
{   
    write-Host "Creating Azure Container App '$($config.ACA_APP_NAME)'..."

    az containerapp create `
            --name $config.CONTAINER_APP_NAME `
            --resource-group $config.RESOURCE_GROUP `
            --environment $config.ACA_ENV `
            --image $containerImageFQDN `
            --registry-server $acrServer `
            --registry-identity system `
            --system-assigned `
            --ingress $config.INGRESS_TYPE `
            --target-port $config.CONTAINER_PORT `
            --min-replicas $config.CONTAINER_APP_MIN_REPLICAS `
            --max-replicas $config.CONTAINER_APP_MAX_REPLICAS `

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Azure Container App created: $($config.CONTAINER_APP_NAME)"       
    }
    else {
        Write-Host "Error: Failed to create Azure Container App"
        exit 1
    } 

        ##App settings for app

        ######
        $configPath = Select-FilePath -Description "Select the JSON file containing application settings for the app (key-value pairs)"
        $appSettings = Get-Content $configPath | ConvertFrom-Json

        # Convert JSON to key=value format
        $settingsArray = @()

        $appSettings.PSObject.Properties | ForEach-Object {
            $settingsArray += "$($_.Name)=$($_.Value)"
        }

        Write-Host "Configuring app application settings..."
        az containerapp update `
            --name $config.CONTAINER_APP_NAME `
            --resource-group $config.RESOURCE_GROUP `
            --set $settingsArray
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$([char]0x2713) Web App application settings updated"       
        }
        else {
            Write-Host "Error: Failed to update Web App application settings"
            exit 1
        }              
}


