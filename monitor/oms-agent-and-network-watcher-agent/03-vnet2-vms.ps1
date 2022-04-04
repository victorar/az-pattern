# create vnet2 and VMs in vnet2
#
# set admin username and password in the variables: $adminUsername, $adminPassword
#
################# Input parameters #################
$subscriptionName = 'ExpressRoute-Lab'     
$location = 'westus2'
$rgName = 'SEA-Cust41'
$deploymentName = 'vnet2_and_vms'
$armTemplateFile = '03-vnet2-vms.json'
$adminUsername = 'ADMINISTRATOR_USERNAME'
$adminPassword = 'ADMINISTRATOR_PASSWORD'
####################################################
$pathFiles      = Split-Path -Parent $PSCommandPath
$templateFile   = "$pathFiles\$armTemplateFile"

$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id

# Create Resource Group
Write-Host (Get-Date)' - ' -NoNewline
Write-Host "Creating Resource Group $rgName " -ForegroundColor Cyan
Try {$rg = Get-AzResourceGroup -Name $rgName  -ErrorAction Stop
     Write-Host '  resource exists, skipping'}
Catch {$rg = New-AzResourceGroup -Name $rgName  -Location $location  }

$parameters = @{
     "location" = $location;
     "adminUsername" = $adminUsername;
     "adminPassword" = $adminPassword
}

$startTime = Get-Date
$runTime=Measure-Command {
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
