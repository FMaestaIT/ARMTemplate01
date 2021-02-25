<#
  .SYNOPSIS
  This cmdlet takes an existing virtual machine, makes a copy of its disks in the local storage account and then copies the virtual machine to a seperate subscription.
  Running this script can take several minutes and up to hours if copying a virtual machine to a remote storage account.

  Ensure the source subscription and the destination subscription are configured for PowerShell access.
  
  Verify by running the following command to ensure that both subscriptions are listed: 
  Get-AzureSubscription | select SubscriptionName 
  

  .DESCRIPTION

  This script works by creating a copy of all of the disks of the virtual machine to a container in the same storage account. 
  You may optionally specify -ShutdownVM to shut the virtual machine down to ensure the backup is clean first.

  Once the disks are backed up locally the script validates that the remote cloud service name, storage account, virtual network and subnet are all accessible from the current configuration.
  
  Once validation is complete the script will copy the disks from the backup in the source storage account to the destination storage account. 

  Once the copy is complete the script will register the disks in the subscription with the same disk names to match the virtual machine configuration. 

  The script next will export the virtual machine settings to a local file on the file system and import them into the target subscription and create the virtual machine. 
   
  
  .EXAMPLE


  
#>


Param (
    [parameter(Mandatory)]
    [String]
    $resourceGroupName,

    [parameter(Mandatory)]
    [String]
    $location,

    [parameter(Mandatory)]
    [String]
    $snapshotName,

    [parameter(Mandatory)]
    [String]
    $imageName,

    [parameter(Mandatory)]
    [string]
    $vmName,

    [parameter(Mandatory)]
    [string]
    $HyperVGeneration,

    [parameter(Mandatory)]
    [string]
    $subscriptionID
)

#logging
$Credential = Get-Credential
Connect-AzAccount -Credential $Credential
Set-AzContext -SubscriptionId $subscriptionID


#creating shapshot
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$snapshotCfg =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
#$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
$snapshot = New-AzSnapshot -Snapshot $snapshotCfg -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName


#creating Image
$imageConfig = New-AzImageConfig -Location $location -HyperVGeneration $HyperVGeneration
$imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Windows -SnapshotId $snapshot.Id
New-AzImage -ImageName $imageName -ResourceGroupName $resourceGroupName -Image $imageConfig