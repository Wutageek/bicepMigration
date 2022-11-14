param virtualMachines_HyperVLabs_name string = 'HyperVLabs'
param disks_HyperVLabs_OsDisk_1_16356a2bfe774ab995a3906ced7a0460_externalid string = '/subscriptions/ed9b1b3a-7701-4096-b99a-d8c9fcfe74c9/resourceGroups/TLKLABS/providers/Microsoft.Compute/disks/HyperVLabs_OsDisk_1_16356a2bfe774ab995a3906ced7a0460'
param disks_DiskServerVM_externalid string = '/subscriptions/ed9b1b3a-7701-4096-b99a-d8c9fcfe74c9/resourceGroups/TLKLABS/providers/Microsoft.Compute/disks/DiskServerVM'
param disks_DiskClientVM_externalid string = '/subscriptions/ed9b1b3a-7701-4096-b99a-d8c9fcfe74c9/resourceGroups/TLKLABS/providers/Microsoft.Compute/disks/DiskClientVM'
param networkInterfaces_hypervlabs463_externalid string = '/subscriptions/ed9b1b3a-7701-4096-b99a-d8c9fcfe74c9/resourceGroups/TLKLabs/providers/Microsoft.Network/networkInterfaces/hypervlabs463'

resource virtualMachines_HyperVLabs_name_resource 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachines_HyperVLabs_name
  location: 'westeurope'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_E4s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachines_HyperVLabs_name}_OsDisk_1_16356a2bfe774ab995a3906ced7a0460'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          id: disks_HyperVLabs_OsDisk_1_16356a2bfe774ab995a3906ced7a0460_externalid
        }
      }
      dataDisks: [
        {
          lun: 0
          name: 'DiskServerVM'
          createOption: 'Attach'
          caching: 'ReadWrite'
          writeAcceleratorEnabled: false
          managedDisk: {
            id: disks_DiskServerVM_externalid
          }
          toBeDetached: false
        }
        {
          lun: 1
          name: 'DiskClientVM'
          createOption: 'Attach'
          caching: 'ReadWrite'
          writeAcceleratorEnabled: false
          managedDisk: {
            id: disks_DiskClientVM_externalid
          }
          toBeDetached: false
        }
      ]
    }
    osProfile: {
      computerName: virtualMachines_HyperVLabs_name
      adminUsername: 'Louke'
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_hypervlabs463_externalid
        }
      ]
    }
  }
}

resource virtualMachines_HyperVLabs_name_enablevmaccess 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachines_HyperVLabs_name_resource
  name: 'enablevmaccess'
  location: 'westeurope'
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'VMAccessAgent'
    typeHandlerVersion: '2.0'
    settings: {
      UserName: 'louke'
    }
    protectedSettings: {}
  }
}