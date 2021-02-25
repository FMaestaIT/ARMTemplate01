<#
  .SYNOPSIS
  This script create the Image from the VM Source.
  

  .DESCRIPTION

  This script works by creating a clone of VM Source and convert it to image.
  Durigin the process this script will create the temp Resource group and temp vNet to isolate the VM.


  The output of this script is the Image File than it can use for create new VMs or WVD Host Pool.
   
  
  .EXAMPLE


  
#>


Param (
    [parameter(Mandatory)]
    [String]
    $vmRGSource,

    [parameter(Mandatory)]
    [string]
    $vmNameSource,

    [parameter(Mandatory)]
    [String]
    $location,

    [parameter(Mandatory)]
    [String]
    $imageName,

    [parameter(Mandatory)]
    [string]
    $imageRGName,

    [parameter(Mandatory)]
    [string]
    $subscriptionID,

    [ValidateSet("PROD","DEV")]
    [string]
    $env = "PROD"

)

$rgTmpName          =   "rg-wvd-ImageCreateTemp"
$vNetTmpName        =   "vnet-wvd-ImageCreateTemp"
$vmClonedTmpName    =   "vmcloned-wvd-ImageCreateTemp"
$snapshotName       =   "snap-wvd-imageCreateTemp"

###FOR DEV ENV####
if ($env -ne "PROD"){
    $location = "West Europe"
    $subscriptionID = "82421080-f838-456b-aac0-7c847f66269d"
    $vmRGSource = "rg-wvd-vm"
    $vmNameSource = "wvd-w10-source"
    $imageName = "Win10BaseImage"
    $imageRGName = "rg-wvd-001"
}



#Login to Azure
    Connect-AzAccount 
    Set-AzContext -SubscriptionId $subscriptionID



#create Temp Resource Group and vNet
    $rgTmpCtx = New-AzResourceGroup -Name  $rgTmpName -Location $location

    $vnetTmpCtx = New-AzVirtualNetwork `
    -ResourceGroupName $rgTmpCtx.ResourceGroupName `
    -Location $location `
    -Name $vNetTmpName `
    -AddressPrefix 10.0.0.0/16

    Add-AzVirtualNetworkSubnetConfig `
    -Name default `
    -AddressPrefix 10.0.0.0/24 `
    -VirtualNetwork $vnetTmpCtx

    $vnetTmpCtx | Set-AzVirtualNetwork


#creating shapshot
    $vmSource = Get-AzVM -ResourceGroupName $vmRGSource -Name $vmNameSource
    $snapshotCfg =  New-AzSnapshotConfig -SourceUri $vmSource.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
    $snapshot = New-AzSnapshot -Snapshot $snapshotCfg -SnapshotName $snapshotName -ResourceGroupName $rgTmpCtx.ResourceGroupName



##cloning VM
    #Create a new Managed Disk from the Snapshot  
    $diskVmSource = Get-AzDisk -ResourceGroupName $vmSource.ResourceGroupName -DiskName $vmSource.StorageProfile.OsDisk.Name

    $disk = New-AzDiskConfig -SkuName $diskVmSource.Sku.name -DiskSizeGB $diskVmSource.DiskSizeGB -Location $diskVmSource.Location -CreateOption Copy -SourceResourceId $snapshot.Id  
    $diskCloned = New-AzDisk -Disk $disk -ResourceGroupName $rgTmpCtx.ResourceGroupName -DiskName "$($diskVmSource.Name)_Cloned"  

    #Initialize virtual machine configuration  
    $vmCloned = New-AzVMConfig -VMName $vmClonedTmpName -VMSize $vmSource.HardwareProfile.VmSize  
    
    #Attach Managed Disk to target virtual machine. OS type depends OS present in the disk (Windows/Linux)  
    $vmCloned = Set-AzVMOSDisk -VM $vmCloned -ManagedDiskId $diskCloned.Id -CreateOption Attach -Windows  
    
    #Create a public IP for the VM  
    $publicIp = New-AzPublicIpAddress -Name ("pip-" + $vmClonedTmpName.ToLower()) -ResourceGroupName $rgTmpCtx.ResourceGroupName -Location $location -AllocationMethod Dynamic  
    
    # Create Network Interface for the VM  
    $vnic = New-AzNetworkInterface -Name ("vnic-" + $vmClonedTmpName.ToLower()) -ResourceGroupName $rgTmpCtx.ResourceGroupName -Location $location -SubnetId ((Get-AzVirtualNetwork -Name $vnetTmpCtx.Name -ResourceGroupName $vnetTmpCtx.ResourceGroupName).Subnets[0].id) -PublicIpAddressId $publicIp.Id  
    $vmCloned = Add-AzVMNetworkInterface -VM $vmCloned -Id $vnic.Id  
    
    #Create the virtual machine with Managed Disk attached  
    New-AzVM -VM $vmCloned -ResourceGroupName $rgTmpCtx.ResourceGroupName -Location $location 



#Run Sysprep
# Build a command that will be run inside the VM.
$remoteCommand =
@"
Start-Process -FilePath "c:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /shutdown /oobe"
"@
    # Save the command to a local file
    Set-Content -Path .\sysprepCommand.ps1 -Value $remoteCommand
    # Invoke the command on the VM, using the local file
    Invoke-AzVMRunCommand -Name $vmCloned.name -ResourceGroupName $rgTmpCtx.ResourceGroupName -CommandId 'RunPowerShellScript' -ScriptPath .\sysprepCommand.ps1 
    # Clean-up the local file
    Remove-Item .\sysprepCommand.ps1


do {
    write-host "waiting sysprep end!!!"
} while (((Get-AzVM -ResourceGroupName RG-WVD-IMAGECREATETEMP -Name vmcloned-wvd-ImageCreateTemp -Status).Statuses[1].DisplayStatus) -ne "VM stopped")



#Creating image
    #Deallocating VM
    Stop-AzVM -ResourceGroupName $rgTmpCtx.ResourceGroupName -Name $vmCloned.name -Force



    #Prepare VM to create image
    set-azvm -ResourceGroupName $rgTmpCtx.ResourceGroupName -Name $vmCloned.name -Generalized
    $vmCloned = get-azvm -ResourceGroupName $rgTmpCtx.ResourceGroupName -Name $vmCloned.name

    #creating Image
    $imageConfig = New-AzImageConfig -Location $location -SourceVirtualMachineId $vmCloned.Id
    New-AzImage -ImageName $imageName -ResourceGroupName $imageRGName -Image $imageConfig


#CleanUP TMP Environment
    #Attention removing the tmp environment
    Remove-AzResourceGroup -Name $rgTmpCtx.ResourceGroupName -Force