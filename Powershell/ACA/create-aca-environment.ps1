#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Checking Azure Container App Environment '$($config.ACA_ENV)'..."
az containerapp env show --name $config.ACA_ENV --resource-group $config.RESOURCE_GROUP 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Azure Container App Environment '$($config.ACA_ENV)' already exists. Please choose a different name or delete the existing environment before deploying. Or select a different script"
    Exit
}
else
{   
    Write-Host "Creating Azure Container App Environment '$($config.ACA_ENV)'..."
    az containerapp env create `
        --name $config.ACA_ENV `
        --resource-group $config.RESOURCE_GROUP `
        --location $config.LOCATION

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$([char]0x2713) Azure Container App Environment created: $($config.ACA_ENV)"
    }
    else {
        Write-Host "Error: Failed to create Azure Container App Environment"
        exit 1
    }
}


