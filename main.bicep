targetScope = 'subscription'

param project string = 'contoso'
param location string = deployment().location
param environment string = 'dev'
param region string = 'weu'
param team string
param deploymentName string = '${deployment().name}-${uniqueString(utcNow())}'

var resourceSuffix = '${project}-${environment}-${region}'

param networkAddressPrefix string = '192.168.254.0/23'
param bastionScaleUnits int = 2
param sshKeyData string
param jumphostVmSize string = 'Standard_D2d_v5'
param jumphostImagePublisher string = 'Canonical'
param jumphostImageOffer string = '0001-com-ubuntu-server-jammy'
param jumphostImageSku string = '22_04-lts-gen2'
param jumphostImageVersion string = 'latest'
param jumphostDiskSizeGB int = 64

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceSuffix}'
  location: location
  tags: {
    project: project
    environment: environment
    region: region
    automation: 'bicep'
  }
}

module network 'modules/network.bicep' = {
  name: '${deploymentName}-network'
  scope: resourceGroup
  params: {
    location: location
    addressPrefix: networkAddressPrefix
    resourceSuffix: resourceSuffix
  }
}

module bastion 'modules/bastion.bicep' = {
  name: '${deploymentName}-bastion'
  scope: resourceGroup
  params: {
    location: location
    subnetId: network.outputs.bastionSubnetId
    scaleUnits: bastionScaleUnits
    resourceSuffix: resourceSuffix
  }
}

module jumphost 'modules/jumphost.bicep' = {
  name: '${deploymentName}-jumphost'
  scope: resourceGroup
  params: {
    location: location
    team: team
    adminUsername: 'azure'
    diskSizeGB: jumphostDiskSizeGB
    imageOffer: jumphostImageOffer
    imagePublisher: jumphostImagePublisher
    imageSku:  jumphostImageSku
    imageVersion: jumphostImageVersion
    sshKeyData: sshKeyData
    resourceSuffix: resourceSuffix
    subnetId: network.outputs.jumphostSubnetId
    vmSize: jumphostVmSize
  }
}

output command string = 'az network bastion ssh --name ${bastion.outputs.name} --resource-group ${resourceGroup.name} --auth-type ssh-key --username azure --target-resource-id ${jumphost.outputs.id} --ssh-key ...'
