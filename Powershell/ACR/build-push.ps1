#Load configuration from config.psd1
Get-Content .\config.psd1
$config = Import-PowerShellDataFile .\config.psd1
$config.AllNodes

# Function to select a folder path using a dialog
function Select-FolderPath {
    param (
        [string]$Description = "Select a folder"
    )
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description        
    $folderBrowser.SelectedPath = Get-Location    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        return $folderBrowser.SelectedPath
    } else {
        Write-Host "No folder selected. Exiting script."
        exit
    }
}

# Select the Flask app directory
$selectedPath = Select-FolderPath -Description "Select the Flask app directory"

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Building and pushing Docker image to ACR..."

az acr build `
    --registry $config.ACR_NAME `
    --image "$($config.IMAGE_NAME):$($config.IMAGE_TAG)" `
    $selectedPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Image built and pushed to ACR: $($config.IMAGE_NAME):$($config.IMAGE_TAG)"    
}
else {
    Write-Host "Error: Failed to build and push Docker image to ACR"
    exit 1
}

Write-Host "Listing images in ACR..."
az acr repository show-tags `
  --name $config.ACR_NAME `
  --repository $config.IMAGE_NAME `
  --output table

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
}
else {
    Write-Host "Error: Failed to list repositories in ACR"
    exit 1
}

Write-Host "Testing the container by running it in ACR..."

az acr run `
    --registry $config.ACR_NAME `
    --cmd "$($config.ACR_NAME).azurecr.io/$($config.IMAGE_NAME):$($config.IMAGE_TAG) python -c 'from app import app'" `
    /dev/null

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Container ran successfully in ACR."
}
else {
    Write-Host "Error: Failed to run container in ACR"
    exit 1
}
