#
################# Input parameters #################
$deploymentName = 'routeserver1'
$armTemplateFile = 'rs.json'
$inputParams = 'init.json'
$cloudInitFileName = 'cloud-init.txt'
####################################################

$pathFiles = Split-Path -Parent $PSCommandPath
$templateFile = "$pathFiles\$armTemplateFile"
$cloudInitFile = "$pathFiles\$cloudInitFileName"

Write-Host "$(Get-Date) - reading file:"$cloudInitFile
If (Test-Path -Path $cloudInitFile) {
  # The command gets the contents of a file as one string, instead of an array of strings. 
  # By default, without the Raw dynamic parameter, content is returned as an array of newline-delimited strings
  $filecontentCloudInit = Get-Content $cloudInitFile -Raw
}
Else { Write-Warning "$(Get-Date) - $cloudInitFile file not found, please change to the directory where these scripts reside ($pathFiles) and ensure this file is present."; Return }

# reading the input parameter file $inputParams and convert the values in hashtable 
If (Test-Path -Path $pathFiles\$inputParams) {
  # convert the json into PSCustomObject
  $jsonObj = Get-Content -Raw $pathFiles\$inputParams | ConvertFrom-Json
  if ($null -eq $jsonObj) {
    Write-Host "file $inputParams is empty"
    Exit
  }
  # convert the PSCustomObject in hashtable
  if ($jsonObj -is [psobject]) {
    $hash = @{}
    foreach ($property in $jsonObj.PSObject.Properties) {
      $hash[$property.Name] = $property.Value
    }
  }
  foreach ($key in $hash.keys) {
    $message = '{0} = {1} ' -f $key, $hash[$key]
    # Write-Output $message
    Try { New-Variable -Name $key -Value $hash[$key] -ErrorAction Stop }
    Catch { Set-Variable -Name $key -Value $hash[$key] }
  }
} 
else { Write-Warning "$inputParams file not found, please change to the directory where these scripts reside ($pathFiles) and ensure this file is present."; Return }

# checking the values of variables
Write-Host "$(Get-Date) - values from file: $inputParams" -ForegroundColor Yellow
if (!$subscriptionName) { Write-Host 'variable $subscriptionName is null' ; Exit }       else { Write-Host '  subscription name.....: '$subscriptionName -ForegroundColor Yellow }
if (!$ResourceGroupName) { Write-Host 'variable $ResourceGroupName is null' ; Exit }     else { Write-Host '  resource group name...: '$ResourceGroupName -ForegroundColor Yellow }
if (!$adminUsername) { Write-Host 'variable $adminUsername is null' ; Exit }             else { Write-Host '  admin username........: '$adminUsername -ForegroundColor Green }
if (!$authenticationType) { Write-Host 'variable $authenticationType is null' ; Exit }   else { Write-Host '  authentication type...: '$authenticationType -ForegroundColor Green }
if (!$adminPasswordOrKey) { Write-Host 'variable $adminPasswordOrKey is null' ; Exit }   else { Write-Host '  admin password/key....: '$adminPasswordOrKey -ForegroundColor Green }
if (!$locationvnet1) { Write-Host 'variable $locationvnet1 is null' ; Exit }             else { Write-Host '  locationvnet1.........: '$locationvnet1 -ForegroundColor Yellow }
if (!$mngIP) { Write-Host 'variable $mngIP is null' } 
if (!$er_subscriptionId) { Write-Host 'variable $er_subscriptionId is null' ; Exit }     else { Write-Host '  er_subscriptionId.....: '$er_subscriptionId -ForegroundColor Yellow }
if (!$er_resourceGroup) { Write-Host 'variable $er_resourceGroup is null' ; Exit }       else { Write-Host '  er_resourceGroup......: '$er_resourceGroup -ForegroundColor Yellow }
if (!$er_circuitName) { Write-Host 'variable $er_circuitName is null' ; Exit }           else { Write-Host '  er_circuitName........: '$er_circuitName -ForegroundColor Yellow }
if (!$er_authorizationKey) { Write-Host 'variable $er_authorizationKey is null' ; Exit } else { Write-Host '  er_authorizationKey...: '$er_authorizationKey -ForegroundColor Yellow }

          
$rgName = $ResourceGroupName
$location = $locationvnet1

$subscr = Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id

$parameters = @{
  "adminUsername"       = $adminUsername;
  "authenticationType"  = $authenticationType;
  "adminPasswordOrKey"  = $adminPasswordOrKey;
  "cloudInitContent"    = $filecontentCloudInit;
  "locationvnet1"       = $locationvnet1;
  "mngIP"               = $mngIP;
  "er_subscriptionId"   = $er_subscriptionId;
  "er_resourceGroup"    = $er_resourceGroup;
  "er_circuitName"      = $er_circuitName;
  "er_authorizationKey" = $er_authorizationKey
}


# Create Resource Group 
Write-Host "$(Get-Date) - Creating Resource Group $rgName " -ForegroundColor Cyan
Try {
  $rg = Get-AzResourceGroup -Name $rgName  -ErrorAction Stop
  Write-Host '  resource exists, skipping'
}
Catch { $rg = New-AzResourceGroup -Name $rgName  -Location $location }


$StartTime = Get-Date
write-host "$StartTime - running ARM template: $templateFile"
New-AzResourceGroupDeployment  -Name $deploymentName -ResourceGroupName $rgName -TemplateFile $templateFile -TemplateParameterObject $parameters -Verbose 

$EndTime = Get-Date
$TimeDiff = New-TimeSpan $StartTime $EndTime
$Mins = $TimeDiff.Minutes
$Secs = $TimeDiff.Seconds
$RunTime = '{0:00}:{1:00} (M:S)' -f $Mins, $Secs
Write-Host "runtime: $RunTime" -ForegroundColor Yellow