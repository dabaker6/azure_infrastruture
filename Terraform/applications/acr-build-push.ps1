<#
Script to build and push a local repository to ACR, and check it's presence

Requires the image name
Accepts optional tag name
#>

param (
    # must define the image name
    [Parameter(Mandatory=$true)]
    [string]$imageName,
    
    # optional tag name
    [string]$tagName = 'latest'
)

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

# Select the app directory
$selectedPath = Select-FolderPath -Description "Select the app directory"

$userObjectId = (az ad signed-in-user show --query "id" -o tsv 2>&1) | Where-Object { $_ -notmatch 'ERROR' } | Select-Object -First 1
if ([string]::IsNullOrEmpty($userObjectId)) {
    Write-Host "Error: Not authenticated with Azure. Please run: az login"
    exit 1
}

Write-Host "Building and pushing Docker image to ACR..."
$registry = $null
$registry = (terraform output -json container_registry | convertfrom-json).name

if ([string]::IsNullOrEmpty($registry)){
    Write-Host "Container registry not in terraform outputs"
    Exit 1
}

az acr build `
    --registry $registry `
    --image "$($imageName):$($tagName)" `
    $selectedPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "$([char]0x2713) Image built and pushed to ACR: $($imageName):$($tagName)"    
}
else {
    Write-Host "Error: Failed to build and push Docker image to ACR"
    exit 1
}

Write-Host "Listing images in ACR..."
az acr repository show `
  --name $registry `
  --repository $imageName `
  --output table

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
}
else {
    Write-Host "Error: Failed to list repositories in ACR"
    exit 1
}

Write-Host "All complete, image ${$appSettings.web_app_image_name} pushed to ${$registry}"