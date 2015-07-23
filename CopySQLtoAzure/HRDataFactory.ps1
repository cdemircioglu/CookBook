#Common Parameters
$ResourceGroupName = "Default-SQL-WestUS"
$DataFactoryName = "POCSQLtoAzureSQL"
$DataFactoryLocation = "West US"
$GatewayName = "LocalGateway"

#Blob to blob copy creates a replica copy of the data. No transformations could be applied. 
#Ignores the schema defined at the dataset as well.

#List all the subscriptions
Get-AzureSubscription

#Set the subscription to Finance IT POC
Select-AzureSubscription -SubscriptionName "Windows Azure  MSDN - Visual Studio Premium"

# Use the AzureResourceManager Mode 
Switch-AzureMode AzureResourceManager 

#Create a data factory
New-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $DataFactoryLocation -Force -ErrorAction Stop 
 
#Get the data factory
$df = Get-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName 

#Create the data gateway 
#This is a manual step done at the UI and requires installation + restart. 
New-AzureDataFactoryGateway -Name $GatewayName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName –Description "ADF" -Location $DataFactoryLocation
$Key = New-AzureDataFactoryGatewayKey -GatewayName $GatewayName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
.\RegisterGateway.ps1 $Key.GatewayKey

#Create the on-prem SQL Server linked service
$FileFullName = "C:\Test\CopySQLtoAzure\LocalSQLOnPremLinkedService.json"
New-AzureDataFactoryLinkedService -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the Azure SQL linked service
$FileFullName = "C:\Test\CopySQLtoAzure\AzureSQLLinkedService.json"
New-AzureDataFactoryLinkedService -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF input table (dataset) 
$FileFullName = "C:\Test\CopySQLtoAzure\LocalStockTable.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF output table (dataset) 
$FileFullName = "C:\Test\CopySQLtoAzure\AzureSQLStockTable.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the pipeline between the tables
$FileFullName = "C:\Test\CopySQLtoAzure\CopySQLtoAzurePipeline.json"
New-AzureDataFactoryPipeline -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Set the time window to run 
Set-AzureDataFactoryPipelineActivePeriod -DataFactory $df -StartDateTime 2015-04-02Z –EndDateTime 2015-04-03Z –Name CopySQLtoAzurePipeline

#To remove all the objects
Remove-AzureDataFactoryPipeline -DataFactory $df -Name HRPipeline -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataBlobOutput -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataTable -Force
Remove-AzureDataFactoryLinkedService -DataFactory $df -Name HROnPremLinkedService -Force
Remove-AzureDataFactoryLinkedService -DataFactory $df -Name HRBlobStoreLinkedService -Force
Remove-AzureDataFactory -DataFactory $df

