param resourceSuffix string
param location string = resourceGroup().location
param subnetId string
param scaleUnits int

var dnsName = 'bas-${resourceSuffix}'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'pip-${resourceSuffix}-bas'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bas-${resourceSuffix}'
  location: location
  sku: {
     name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    dnsName: dnsName
    enableFileCopy: true
    enableIpConnect: true
    enableShareableLink: true
    enableTunneling: true
    scaleUnits: scaleUnits
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: {
            id: publicIpAddress.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

output name string = bastion.name
