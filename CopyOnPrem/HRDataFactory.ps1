#Common Parameters
$ResourceGroupName = "HRPOCResourceGroup"
$DataFactoryName = "POCMoveDataOnPrem"
$DataFactoryLocation = "West US"
$Location = "West US"
$StorageAccountName = "hrpocstorageaccount"
$FileName = "HRDataTable"
$ContainerName = "demo"
$ClusterName = "HRHDInsightCluster"
$ClusterNodes = 32
$StorageAccountKey =  "Le1CnOQVpCYhAe9Ncrf8KlIf6Aq6CbFBwvTgggnhRrcScoid77ogDcAJhpklHm5vZMVqQOxEqpzyqtXZA0VhoQ=="
$SecurePassword = ConvertTo-SecureString "TalkingRa2!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("admin", $SecurePassword)
$GatewayName = "CemLocalhost"

#Blob to blob copy creates a replica copy of the data. No transformations could be applied. 
#Ignores the schema defined at the dataset as well.

#List all the subscriptions
Get-AzureSubscription

#Set the subscription to Finance IT POC
Select-AzureSubscription -SubscriptionName "HRIT POC"

#Create a data factory
New-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $DataFactoryLocation -Force -ErrorAction Stop 

# Use the AzureResourceManager Mode 
Switch-AzureMode AzureResourceManager 
 
#Get the data factory
$df = Get-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName 

#Create the Azure Blob store linked service
$FileFullName = "C:\Test\CopyOnPrem\HRBlobStoreLinkedService.json"
New-AzureDataFactoryLinkedService -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the data gateway 
#This is a manual step done at the UI and requires installation + restart. 
New-AzureDataFactoryGateway -Name $GatewayName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName –Description "ADF" -Location $DataFactoryLocation
$Key = New-AzureDataFactoryGatewayKey -GatewayName $GatewayName -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
.\RegisterGateway.ps1 $Key.GatewayKey

#Create the linked service to on prem database
$FileFullName = "C:\Test\CopyOnPrem\HROnPremLinkedService.json"
New-AzureDataFactoryLinkedService -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF input table (dataset) 
$FileFullName = "C:\Test\CopyOnPrem\HRDataTable.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF output table (dataset) 
$FileFullName = "C:\Test\CopyOnPrem\HRDataBlobOutput.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the pipeline between the tables
$FileFullName = "C:\Test\CopyOnPrem\HRPipeline.json"
New-AzureDataFactoryPipeline -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Set the time window to run 
Set-AzureDataFactoryPipelineActivePeriod -DataFactory $df -StartDateTime 2015-01-20Z –EndDateTime 2015-01-22Z –Name HRPipeline  

#To remove all the objects
Remove-AzureDataFactoryPipeline -DataFactory $df -Name HRPipeline -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataBlobOutput -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataTable -Force
Remove-AzureDataFactoryLinkedService -DataFactory $df -Name HROnPremLinkedService -Force
Remove-AzureDataFactoryLinkedService -DataFactory $df -Name HRBlobStoreLinkedService -Force
Remove-AzureDataFactory -DataFactory $df

