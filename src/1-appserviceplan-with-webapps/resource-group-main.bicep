metadata description = 'Creates a resource group for the project'
targetScope = 'subscription'

@minLength(3)
@maxLength(24)
@description('Provide a location.')
param location string

@minLength(3)
@maxLength(3)
@description('Provide a env.')
param envsufix string

@minLength(3)
@maxLength(12)
@description('Provide a name for the project.')
param project string

resource newRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${project}-${location}-${envsufix}'
  location: location
  tags: {
    project: project
  }
}
