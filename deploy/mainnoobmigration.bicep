/*
  SYNOPSIS: VM creation 
  DESCRIPTION: migrate from json template file
  VERSION: 1.0.0
  OWNER TEAM: TLKLabs
*/
param location string = resourceGroup().location
param virtualMachine_name string
param adminUsernameVM string = 'Louke'

//change ID
param disks_OsDisk_1 string = '/subscriptions/dba92d2c-0609-4859-aaee-8ae4c3c79919/resourceGroups/BicepNoob/providers/Microsoft.Compute/disks/${virtualMachine_name}_OsDisk_1'
param disks_DiskServerVM_externalid string = '/subscriptions/dba92d2c-0609-4859-aaee-8ae4c3c79919/resourceGroups/BicepNoob/providers/Microsoft.Compute/disks/DiskServerVM'
param disks_DiskClientVM_externalid string = '/subscriptions/dba92d2c-0609-4859-aaee-8ae4c3c79919/resourceGroups/BicepNoob/providers/Microsoft.Compute/disks/DiskClientVM'
param networkInterfaces_hypervlabs463_externalid string = '/subscriptions/dba92d2c-0609-4859-aaee-8ae4c3c79919/resourceGroups/BicepNoob/providers/Microsoft.Network/networkInterfaces/hypervlabs463'

//change symbolic
resource virtualMachines 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachine_name
  location: location
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
        name: '${virtualMachine_name}_OsDisk_1' //define resource group id
        createOption: 'FromImage'
        caching: 'ReadWrite'
       // managedDisk: {
          //id: disks_OsDisk_1
       // }
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
      computerName: virtualMachine_name
      adminUsername: adminUsernameVM
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
  parent: virtualMachines
  name: 'enablevmaccess'
  location: location
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
