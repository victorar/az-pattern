# Before running the script set the values of the variables in the file init.json
#
################# Input parameters #################
$deploymentName = "nsg-log"
$armTemplateFile = "02-flowlogs.json"
$inputParams = 'init.json'
####################################################

$pathFiles = Split-Path -Parent $PSCommandPath
$templateFile = "$pathFiles\$armTemplateFile"

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
        Write-Output $message
        Try { New-Variable -Name $key -Value $hash[$key] -ErrorAction Stop }
        Catch { Set-Variable -Name $key -Value $hash[$key] }
    }
} 
else { Write-Warning "$inputParams file not found, please change to the directory where these scripts reside ($pathFiles) and ensure this file is present."; Return }

# checking the values of variables
Write-Host "$(Get-Date) - values from file: $inputParams" -ForegroundColor Yellow
if (!$adminUsername) { Write-Host 'variable $adminUsername is null' ; Exit }         else { Write-Host '   administrator username: '$adminUsername -ForegroundColor Green }
if (!$adminPassword) { Write-Host 'variable $adminPassword is null' ; Exit }         else { Write-Host '   administrator password: '$adminPassword -ForegroundColor Green }
if (!$subscriptionName) { Write-Host 'variable $subscriptionName is null' ; Exit }   else { Write-Host '   subscription name.....: '$subscriptionName -ForegroundColor Yellow }
if (!$location) { Write-Host 'variable $location is null' ; Exit }                   else { Write-Host '   location..............: '$location -ForegroundColor Yellow }
if (!$ResourceGroupName) { Write-Host 'variable $ResourceGroupName is null' ; Exit } else { Write-Host '   resource group name...: '$ResourceGroupName -ForegroundColor Yellow }
if (!$vm1Name) { Write-Host 'variable $vm1Name is null' ; Exit }                     else { Write-Host '   vm1 name..............: '$vm1Name -ForegroundColor Yellow }
if (!$vm2Name) { Write-Host 'variable $vm2Name is null' ; Exit }                     else { Write-Host '   vm2 name..............: '$vm2Name -ForegroundColor Yellow }
if (!$vm3Name) { Write-Host 'variable $vm3Name is null' ; Exit }                     else { Write-Host '   vm3 name..............: '$vm3Name -ForegroundColor Yellow }
if (!$mngIP) { Write-Host 'variable $mngIP is null'  -ForegroundColor Cyan }         else { Write-Host '   mngIP.................: '$mngIP -ForegroundColor Yellow }
$rgName = $ResourceGroupName

$subscr = Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id

# Login Check
Try {
    Write-Host 'Using Subscription: ' -NoNewline
    Write-Host $((Get-AzContext).Name) -ForegroundColor Green
}
Catch {
    Write-Warning 'You are not logged in dummy. Login and try again!'
    Return
}


# Create Resource Group 
Write-Host (Get-Date)' - ' -NoNewline
Write-Host "Creating Resource Group $rgName " -ForegroundColor Cyan
Try {
    $rg = Get-AzResourceGroup -Name $rgName  -ErrorAction Stop
    Write-Host '  resource exists, skipping'
}
Catch {
    $rg = New-AzResourceGroup -Name $rgName  -Location $location  
#    Set-AzResourceGroup -Name $rgName `
#        -Tag @{Expires = $RGTagExpireDate; Contacts = $RGTagContact; Owner = $RGTagAlias; Usage = $RGTagUsage } | Out-Null
}

$parameters = @{ 
    "location" = $location;
    "vm1Name" = $vm1Name;
    "vm2Name" = $vm2Name;
    "vm3Name" = $vm3Name
}

$startTime = Get-Date
$runTime = Measure-Command {
    write-host "$startTime - running ARM template:"$templateFile
    New-AzResourceGroupDeployment  -Name $deploymentName -ResourceGroupName $rgName -TemplateFile $templateFile -TemplateParameterObject $parameters -Verbose 
}

# End and printout the runtime
$endTime = Get-Date
$TimeDiff = New-TimeSpan $startTime $endTime
$Mins = $TimeDiff.Minutes
$Secs = $TimeDiff.Seconds
$RunTime = '{0:00}:{1:00} (M:S)' -f $Mins, $Secs
Write-Host (Get-Date)' - ' -NoNewline
Write-Host "Script completed" -ForegroundColor Green
Write-Host "  Time to complete: $RunTime" -ForegroundColor Yellow