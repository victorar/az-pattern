# Before running the script set the variables in init.json file
#
################# Input parameters #################
$deploymentName = "anm1-vms"
$armTemplateFile = "01-vnets.json"
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
if (!$adminUsername) { Write-Host 'variable $adminUsername is null' ; Exit }         else { Write-Host '   administrator username...: '$adminUsername -ForegroundColor Green }
if (!$adminPassword) { Write-Host 'variable $adminPassword is null' ; Exit }         else { Write-Host '   administrator password...: '$adminPassword -ForegroundColor Green }
if (!$subscriptionName) { Write-Host 'variable $subscriptionName is null' ; Exit }   else { Write-Host '   subscription name........: '$subscriptionName -ForegroundColor Yellow }
if (!$location) { Write-Host 'variable $location is null' ; Exit }                   else { Write-Host '   location.................: '$location -ForegroundColor Yellow }
if (!$locationhub) { Write-Host 'variable $locationhub is null' ; Exit }             else { Write-Host '   locationhub..............: '$locationhub -ForegroundColor Yellow }
if (!$locationspokes) { Write-Host 'variable $locationspokes is null' ; Exit }       else { Write-Host '   locationspokes...........: '$locationspokes -ForegroundColor Yellow }
if (!$resourceGroupName) { Write-Host 'variable $resourceGroupName is null' ; Exit } else { Write-Host '   resource group name......: '$resourceGroupName -ForegroundColor Yellow }
if (!$resourceGroupNameVNets) { Write-Host 'variable $resourceGroupNameVNets is null' ; Exit } else { Write-Host '   resource group name VNets: '$resourceGroupNameVNets -ForegroundColor Yellow }
if (!$numSpokes) { Write-Host 'variable $numSpokes is null' ; Exit }                 else { Write-Host '   numSpokes................: '$numSpokes -ForegroundColor Yellow }
if (!$mngIP) { Write-Host 'variable $mngIP is null' ; Exit }                         else { Write-Host '   mngIP....................: '$mngIP -ForegroundColor Yellow }
if (!$RGTagExpireDate) { Write-Host 'variable $RGTagExpireDate is null' ; Exit }     else { Write-Host '   RGTagExpireDate..........: '$RGTagExpireDate -ForegroundColor Yellow }
if (!$RGTagContact) { Write-Host 'variable $RGTagContact is null' ; Exit }           else { Write-Host '   RGTagContact.............: '$RGTagContact -ForegroundColor Yellow }
if (!$RGTagNinja) { Write-Host 'variable $RGTagNinja is null' ; Exit }               else { Write-Host '   RGTagNinja...............: '$RGTagNinja -ForegroundColor Yellow }
if (!$RGTagUsage) { Write-Host 'variable $RGTagUsage is null' ; Exit }               else { Write-Host '   RGTagUsage...............: '$RGTagUsage -ForegroundColor Yellow }

$rgName = $resourceGroupNameVNets

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

$subscr = Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id

# Create Resource Group
Write-Host (Get-Date)' - ' -NoNewline
Write-Host "Creating Resource Group $rgName " -ForegroundColor Cyan
Try {
    $rg = Get-AzResourceGroup -Name $rgName  -ErrorAction Stop
    Write-Host '  resource exists, skipping'
}
Catch {
    $rg = New-AzResourceGroup -Name $rgName  -Location $location  
    Set-AzResourceGroup -Name $rgName `
        -Tag @{Expires = $RGTagExpireDate; Contacts = $RGTagContact; Owner = $RGTagAlias; Usage = $RGTagUsage } | Out-Null
}

$parameters = @{ 
    "locationhub" = $locationhub;
    "locationspokes" = $locationspokes;
    "numSpokes" = $numSpokes
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