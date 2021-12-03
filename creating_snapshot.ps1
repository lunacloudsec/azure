# Criar Snapshot de todos os discos das VMs de um Resource Group
 
$VmResourceGroup = 'PUT-YOUR-RESOURCEGOUP-HERE' # Nome do Resource Group das VMs
$location = 'PUT-YOUR-LOCATION-HERE' # Localização dos Snapshots

# Pega todas as VMs do ResourceGroup, limpa linhas deixando apenas os nomes das VMs no arquivo all_vms.txt
Get-AzVM -ResourceGroupName 'DL-RG' | Select-Object -Property Name >> vms_result.txt
(Get-Content vms_result.txt ) | Where-Object {$_.trim() -ne "" } | Set-Content all_vms.txt
$content = Get-Content all_vms.txt
$content[2..($content.length-1)]|Out-File all_vms.txt -Force
$lines = (Get-Content .\all_vms.txt).Length
Write-Output "Quantidade de VMS: $($lines)"

# VM Snapshot
# Percorrer as linhas do arquivo .\all_vms.txt e faz os snapshots de todas as VMs encontradas

foreach ($LINE in Get-Content all_vms.txt) 
{
    $vm = get-azvm -Name $LINE -ResourceGroupName $VmResourceGroup
    Write-Output "VM $($vm.name) OS Disk Snapshot Begin"
    $snapshotdisk = $vm.StorageProfile
    $OSDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $snapshotdisk.OsDisk.ManagedDisk.id -CreateOption Copy -Location $location
    $snapshotNameOS = "$($snapshotdisk.OsDisk.Name)_snapshot_$(Get-Date -Format ddMMyy)"

    # OS Disk Snapshot

        try {
            New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameOS -Snapshot $OSDiskSnapshotConfig -ErrorAction Stop
        } catch {
            $_
        }
 
        Write-Output "VM $($vm.name) OS Disk Snapshot End"
        Write-Output "----------------------------"

    # Data Disk Snapshot
    Write-Output "VM $($vm.name) Data Disk Snapshots Begin"
    $dataDisks = ($snapshotdisk.DataDisks).name
        
        foreach ($datadisk in $datadisks) {
        
            $dataDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $datadisk
            Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot Begin"
            $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $location
            $snapshotNameData = "$($datadisk.name)_snapshot_$(Get-Date -Format ddMMyy)"
            New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig -ErrorAction Stop
            Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot End"   
            }
        
        Write-Output "VM $($vm.name) Data Disk Snapshots End"
        Write-Output "----------------------------"
}

# Remover arquivos
Remove-Item .\vms_result.txt,.\all_vms.txt
