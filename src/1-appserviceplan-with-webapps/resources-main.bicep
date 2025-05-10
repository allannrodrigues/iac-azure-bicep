metadata description = 'Creates resources for the resource group project'

@minLength(3)
@maxLength(8)
@description('Provide a location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(3)
@description('Provide a env sufix.')
param envsufix string

@minLength(3)
@maxLength(11)
@description('Provide a name for the project.')
param project string

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'cr${project}${envsufix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: 'plan-${project}-${envsufix}'
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
  tags: {
    project: project
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appins-${project}-${envsufix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
  tags: {
    project: project
  }
}

resource appFrontend 'Microsoft.Web/sites@2022-09-01' = {
  name: 'frontend-${project}-${envsufix}'
  location: location
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig: {
      minTlsVersion: '1.2'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'Brazil/East'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: '@Microsoft.KeyVault(https://kv-${project}-${envsufix}.vault.azure.net/secrets/ContainerRegistry)'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: acrResource.properties.loginServer
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acrResource.name
        }
      ]
    }
    httpsOnly: true
  }
  tags: {
    project: project
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appBackend 'Microsoft.Web/sites@2022-09-01' = {
  name: 'backend-${project}-${envsufix}'
  location: location
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig: {
      minTlsVersion: '1.2'
      alwaysOn: true
      appSettings: [
        {
          name: 'ConnectionStrings_DefaultConnection'
          value: '@Microsoft.KeyVault(https://kv-${project}-${envsufix}.vault.azure.net/secrets/Database)'
        }
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'Brazil/East'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: '@Microsoft.KeyVault(https://kv-${project}-${envsufix}.vault.azure.net/secrets/ContainerRegistry)'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: acrResource.properties.loginServer
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acrResource.name
        }
      ]
    }
    httpsOnly: true
  }
  tags: {
    project: project
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'st${project}${envsufix}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  dependsOn: [appServicePlan]
  tags: {
    project: project
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: 'func-${project}-${envsufix}'
  location: location
  kind: 'functionapp'
  tags: {
    project: project
  }
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'ConnectionStrings__Database'
          value: '@Microsoft.KeyVault(https://kv-${project}-${envsufix}.vault.azure.net/secrets/Database)'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'Brazil/East'
        }
      ]
      minTlsVersion: '1.2'
      alwaysOn: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource funcAppsettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    AzureWebJobsDisableHomepage: '1'
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageaccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageaccount.listKeys().keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~4'
    ftpsState: 'Disabled'
    minTlsVersion: '1.2'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_TIME_ZONE: 'Brazil/East'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'sql-${project}-${envsufix}'
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: 'db-${project}-${envsufix}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${project}-${envsufix}'
  location: location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        objectId: appBackend.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          keys: ['list', 'get']
          secrets: ['list', 'get']
        }
      }
      {
        objectId: appFrontend.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          keys: ['list', 'get']
          secrets: ['list', 'get']
        }
      }
      {
        objectId: functionApp.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          keys: ['list', 'get']
          secrets: ['list', 'get']
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secretDatabase 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'Database'
  properties: {
    value: 'Server=sql-${project}-${envsufix}.database.windows.net;Database=db-${project}-${envsufix};User Id=${administratorLogin};Password=${administratorLoginPassword};TrustServerCertificate=True;Encrypt=True;'
  }
}

resource secretContainer 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'ContainerRegistry'
  properties: {
    value: acrResource.listCredentials().passwords[0].value
  }
}

resource secretStorage 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'Storage'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageaccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageaccount.listKeys().keys[0].value}'
  }
}
