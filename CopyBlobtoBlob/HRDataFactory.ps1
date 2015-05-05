#Common Parameters
$ResourceGroupName = "HRPOCResourceGroup"
$DataFactoryName = "POCMoveData"
$DataFactoryLocation = "West US"
$Location = "West US"
$StorageAccountName = "hrpocstorageaccount"
$FileName = "HRDataTable"
$ContainerName = "demo"
$ClusterName = "HRHDInsightCluster"
$ClusterNodes = 2
$StorageAccountKey =  "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$SecurePassword = ConvertTo-SecureString "XXXXXXXXXXXXX" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("admin", $SecurePassword)
$GatewayName = "CemLocalhost"

#Blob to blob copy creates a replica copy of the data. No transformations could be applied. 
#Ignores the schema defined at the dataset as well. 

#List all the subscriptions
Get-AzureSubscription

#Set the subscription to HR IT POC
Select-AzureSubscription -SubscriptionName "HRIT POC"


# Use the AzureResourceManager Mode 
Switch-AzureMode AzureResourceManager 

#Create a data factory
New-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $Location -Force -ErrorAction Stop 
 
#Get the data factory
$df = Get-AzureDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName 

#Create the Azure Blob store linked service
$FileFullName = "C:\Test\CopyBlobtoBlob\HRBlobStoreLinkedService.json"
New-AzureDataFactoryLinkedService -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF input table (dataset) 
$FileFullName = "C:\Test\CopyBlobtoBlob\HRDataTable.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the ADF output table (dataset) 
$FileFullName = "C:\Test\CopyBlobtoBlob\HRDataTableOutput.json"
New-AzureDataFactoryTable -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Create the pipeline between the tables
$FileFullName = "C:\Test\CopyBlobtoBlob\HRPipeline.json"
New-AzureDataFactoryPipeline -DataFactory $df -File $FileFullName -ErrorAction Stop -Force

#Set the time window to run 
Set-AzureDataFactoryPipelineActivePeriod -DataFactory $df -StartDateTime 2015-02-01Z –EndDateTime 2015-02-03Z –Name HRPipeline  

#To remove all the objects
Remove-AzureDataFactoryPipeline -DataFactory $df -Name HRPipeline -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataTableOutput -Force
Remove-AzureDataFactoryTable -DataFactory $df -Name HRDataTable -Force