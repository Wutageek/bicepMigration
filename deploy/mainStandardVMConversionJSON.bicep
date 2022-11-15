param location string
param networkInterfaceName1 string
param enableAcceleratedNetworking bool
param networkSecurityGroupName string
param networkSecurityGroupRules array
param subnetName string
param virtualNetworkName string
param addressPrefixes array
param subnets array
param publicIpAddressName1 string
param publicIpAddressType string
param publicIpAddressSku string
param pipDeleteOption string
param virtualMachineName string
param virtualMachineName1 string
param virtualMachineComputerName1 string
param virtualMachineRG string
param osDiskType string
param osDiskDeleteOption string
param dataDisks1 array
param dataDiskResources1 array
param virtualMachineSize string
param nicDeleteOption string
param adminUsername string

@secure()
param adminPassword string
param patchMode string
param enableHotpatching bool
param zone string
param autoShutdownStatus string
param autoShutdownTime string
param autoShutdownTimeZone string
param autoShutdownNotificationStatus string
param autoShutdownNotificationLocale string
param autoShutdownNotificationEmail string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetName = virtualNetworkName
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var aadLoginExtensionName = 'AADLoginForWindows'

resource networkInterfaceName1_resource 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName1
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName1)
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
    virtualNetworkName_resource
    publicIpAddressName1_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2021-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

resource publicIpAddressName1_resource 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressName1
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
  zones: [
    '1'
  ]
}

resource dataDiskResources1_name 'Microsoft.Compute/disks@2022-03-02' = [for item in dataDiskResources1: {
  name: item.name
  location: location
  properties: item.properties
  sku: {
    name: item.sku
  }
  zones: (contains(item.sku, '_ZRS') ? json('null') : array(1))
}]

resource virtualMachineName1_resource 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName1
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      dataDisks: [for item in dataDisks1: {
        lun: item.lun
        createOption: item.createOption
        caching: item.caching
        diskSizeGB: item.diskSizeGB
        managedDisk: {
          id: (item.id ?? ((item.name == json('null')) ? json('null') : resourceId('Microsoft.Compute/disks', item.name)))
          storageAccountType: item.storageAccountType
        }
        deleteOption: item.deleteOption
        writeAcceleratorEnabled: item.writeAcceleratorEnabled
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName1_resource.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineComputerName1
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVmAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'systemAssigned'
  }
  zones: [
    '1'
  ]
  dependsOn: [
    dataDiskResources1_name
  ]
}

resource shutdown_computevm_virtualMachineName1 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${virtualMachineName1}'
  location: location
  properties: {
    status: autoShutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: virtualMachineName1_resource.id
    notificationSettings: {
      status: autoShutdownNotificationStatus
      notificationLocale: autoShutdownNotificationLocale
      timeInMinutes: '30'
      emailRecipient: autoShutdownNotificationEmail
    }
  }
}

resource virtualMachineName1_aadLoginExtensionName 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: virtualMachineName1_resource
  name: '${aadLoginExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: aadLoginExtensionName
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

output adminUsername string = adminUsername