param resourceSuffix string
param addressPrefix string
param location string = resourceGroup().location

var bastionSubnetName = 'AzureBastionSubnet'
var jumphostSubnetName = 'snet-jumphost'
var bastionSubnetAddressPrefix = replace(addressPrefix, '254.0/23', '254.0/24')
var jumphostSubnetAddressPrefix = replace(addressPrefix, '254.0/23', '255.0/24')

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vnet-${resourceSuffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          networkSecurityGroup: {
            id: bastionNetworkSecurityGroup.id
          }
        }
      }
      {
        name: jumphostSubnetName
        properties: {
          addressPrefix: jumphostSubnetAddressPrefix
          networkSecurityGroup: {
            id: jumphostNetworkSecurityGroup.id
          }
        }
      }
    ]
  }

  resource bastionSubnet 'subnets' existing = {
    name: bastionSubnetName
  }

  resource jumphostSubnet 'subnets' existing = {
    name: jumphostSubnetName
  }
}

resource bastionNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-${resourceSuffix}-bas'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowInternetInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowControlPlaneInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowHealthProbesInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowDataPlaneInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Inbound'
          priority: 130
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          direction: 'Outbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowCloudOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowDataPlaneOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Outbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSessionCertificateValidationOutbound'
        properties: {
          access: 'Allow'
          description: 'Allow session and certificate validation'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 130
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Outbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource jumphostNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: 'nsg-${resourceSuffix}-jumphost'
  location: location
}

output id string = virtualNetwork.id
output bastionSubnetId string = virtualNetwork::bastionSubnet.id
output jumphostSubnetId string = virtualNetwork::jumphostSubnet.id
