

```bash


            "list",
            "get"
          ],
          "storage": [
            "all"
          ]
        },
        "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8"
      }
    ],
    "createMode": null,
    "enablePurgeProtection": null,
    "enableRbacAuthorization": false,
    "enableSoftDelete": true,
    "enabledForDeployment": false,
    "enabledForDiskEncryption": null,
    "enabledForTemplateDeployment": null,
    "hsmPoolResourceId": null,
    "networkAcls": null,
    "privateEndpointConnections": null,
    "provisioningState": "Succeeded",
    "publicNetworkAccess": "Enabled",
    "sku": {
      "family": "A",
      "name": "standard"
    },
    "softDeleteRetentionInDays": 90,
    "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8",
    "vaultUri": "https://djapp-kv-71130.vault.azure.net/"
  },
  "resourceGroup": "django-app-production-rg",
  "systemData": {
    "createdAt": "2025-07-02T15:53:44.037000+00:00",
    "createdBy": "vitalii_shevchuk3@epam.com",
    "createdByType": "User",
    "lastModifiedAt": "2025-07-02T15:54:21.470000+00:00",
    "lastModifiedBy": "vitalii_shevchuk3@epam.com",
    "lastModifiedByType": "User"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.KeyVault/vaults"
}
[2025-07-02 15:54:21] Додавання секретів до Key Vault
[2025-07-02 15:54:22] ✅ Django secret key додано
[2025-07-02 15:54:23] ✅ Database password додано
[2025-07-02 15:54:24] ✅ Storage account key додано
[2025-07-02 15:54:24] Створення Application Insights: django-app-production-insights
Preview version of extension is disabled by default for extension installation, enabled for modules without stable versions. 
Please run 'az config set extension.dynamic_install_allow_preview=true or false' to config it specifically. 
The command requires the extension application-insights. Do you want to install it now? The command will continue to run after the extension is installed. (Y/n): y
Run 'az config set extension.use_dynamic_install=yes_without_prompt' to allow installing extensions without prompt.
Extension 'application-insights' has a later preview version to install, add `--allow-preview True` to try preview version.
{- Installing ..
  "appId": "7b8a10e2-39f7-49f0-97ea-431d87bd2a7b",
  "applicationId": "django-app-production-insights",
  "applicationType": "web",
  "connectionString": "InstrumentationKey=ccf40b2a-6776-465d-a683-a7f74b9e9a79;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/;ApplicationId=7b8a10e2-39f7-49f0-97ea-431d87bd2a7b",
  "creationDate": "2025-07-01T19:16:37.520827+00:00",
  "disableIpMasking": null,
  "etag": "\"0e059414-0000-0200-0000-6865578a0000\"",
  "flowType": "Bluefield",
  "hockeyAppId": null,
  "hockeyAppToken": null,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/microsoft.insights/components/django-app-production-insights",
  "immediatePurgeDataOn30Days": null,
  "ingestionMode": "LogAnalytics",
  "instrumentationKey": "ccf40b2a-6776-465d-a683-a7f74b9e9a79",
  "kind": "web",
  "location": "westeurope",
  "name": "django-app-production-insights",
  "privateLinkScopedResources": null,
  "provisioningState": "Succeeded",
  "publicNetworkAccessForIngestion": "Enabled",
  "publicNetworkAccessForQuery": "Enabled",
  "requestSource": "rest",
  "resourceGroup": "django-app-production-rg",
  "retentionInDays": 90,
  "samplingPercentage": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "tenantId": "f7dc8823-4f06-4346-9de0-badbe6273a54",
  "type": "microsoft.insights/components"
}
[2025-07-02 16:00:14] Створення App Service Plan: django-app-production-plan
{
  "elasticScaleEnabled": false,
  "extendedLocation": null,
  "freeOfferExpirationTime": null,
  "geoRegion": "West Europe",
  "hostingEnvironmentProfile": null,
  "hyperV": false,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/serverfarms/django-app-production-plan",
  "isSpot": false,
  "isXenon": false,
  "kind": "linux",
  "kubeEnvironmentProfile": null,
  "location": "westeurope",
  "maximumElasticWorkerCount": 1,
  "maximumNumberOfWorkers": 3,
  "name": "django-app-production-plan",
  "numberOfSites": 1,
  "numberOfWorkers": 1,
  "perSiteScaling": false,
  "provisioningState": "Succeeded",
  "reserved": true,
  "resourceGroup": "django-app-production-rg",
  "sku": {
    "capabilities": null,
    "capacity": 1,
    "family": "B",
    "locations": null,
    "name": "B1",
    "size": "B1",
    "skuCapacity": null,
    "tier": "Basic"
  },
  "spotExpirationTime": null,
  "status": "Ready",
  "subscription": "f7dc8823-4f06-4346-9de0-badbe6273a54",
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "targetWorkerCount": 0,
  "targetWorkerSizeId": 0,
  "type": "Microsoft.Web/serverfarms",
  "workerTierName": null,
  "zoneRedundant": false
}
[2025-07-02 16:00:19] Створення Web App: django-app-production-1751471130
{
  "availabilityState": "Normal",
  "clientAffinityEnabled": true,
  "clientCertEnabled": false,
  "clientCertExclusionPaths": null,
  "clientCertMode": "Required",
  "cloningInfo": null,
  "containerSize": 0,
  "customDomainVerificationId": "277D8A1B15CA68EB12A5F295764EA158E61A2A3D155C88E7660BB300D2D92D51",
  "dailyMemoryTimeQuota": 0,
  "daprConfig": null,
  "defaultHostName": "django-app-production-1751471130.azurewebsites.net",
  "enabled": true,
  "enabledHostNames": [
    "django-app-production-1751471130.azurewebsites.net",
    "django-app-production-1751471130.scm.azurewebsites.net"
  ],
  "endToEndEncryptionEnabled": false,
  "extendedLocation": null,
  "ftpPublishingUrl": "ftps://waws-prod-am2-601.ftp.azurewebsites.windows.net/site/wwwroot",
  "hostNameSslStates": [
    {
      "certificateResourceId": null,
      "hostType": "Standard",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-app-production-1751471130.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    },
    {
      "certificateResourceId": null,
      "hostType": "Repository",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-app-production-1751471130.scm.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    }
  ],
  "hostNames": [
    "django-app-production-1751471130.azurewebsites.net"
  ],
  "hostNamesDisabled": false,
  "hostingEnvironmentProfile": null,
  "httpsOnly": false,
  "hyperV": false,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/sites/django-app-production-1751471130",
  "identity": null,
  "inProgressOperationId": null,
  "isDefaultContainer": null,
  "isXenon": false,
  "keyVaultReferenceIdentity": "SystemAssigned",
  "kind": "app,linux",
  "lastModifiedTimeUtc": "2025-07-02T16:00:24.680000",
  "location": "West Europe",
  "managedEnvironmentId": null,
  "maxNumberOfWorkers": null,
  "name": "django-app-production-1751471130",
  "outboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,20.105.224.17",
  "possibleOutboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,51.124.61.31,51.124.61.49,51.124.61.56,51.124.61.142,51.124.61.184,51.124.61.192,51.105.209.160,51.105.210.136,51.105.210.122,51.124.56.53,51.124.61.162,51.105.210.2,51.124.61.169,51.105.209.155,51.124.57.83,51.124.62.101,51.124.57.229,51.124.58.97,20.105.224.17",
  "publicNetworkAccess": null,
  "redundancyMode": "None",
  "repositorySiteName": "django-app-production-1751471130",
  "reserved": true,
  "resourceConfig": null,
  "resourceGroup": "django-app-production-rg",
  "scmSiteAlsoStopped": false,
  "serverFarmId": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/serverfarms/django-app-production-plan",
  "siteConfig": {
    "acrUseManagedIdentityCreds": false,
    "acrUserManagedIdentityId": null,
    "alwaysOn": false,
    "antivirusScanEnabled": null,
    "apiDefinition": null,
    "apiManagementConfig": null,
    "appCommandLine": null,
    "appSettings": null,
    "autoHealEnabled": null,
    "autoHealRules": null,
    "autoSwapSlotName": null,
    "azureMonitorLogCategories": null,
    "azureStorageAccounts": null,
    "clusteringEnabled": false,
    "connectionStrings": null,
    "cors": null,
    "customAppPoolIdentityAdminState": null,
    "customAppPoolIdentityTenantState": null,
    "defaultDocuments": null,
    "detailedErrorLoggingEnabled": null,
    "documentRoot": null,
    "elasticWebAppScaleLimit": 0,
    "experiments": null,
    "fileChangeAuditEnabled": null,
    "ftpsState": null,
    "functionAppScaleLimit": null,
    "functionsRuntimeScaleMonitoringEnabled": null,
    "handlerMappings": null,
    "healthCheckPath": null,
    "http20Enabled": false,
    "http20ProxyFlag": null,
    "httpLoggingEnabled": null,
    "ipSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "ipSecurityRestrictionsDefaultAction": null,
    "javaContainer": null,
    "javaContainerVersion": null,
    "javaVersion": null,
    "keyVaultReferenceIdentity": null,
    "limits": null,
    "linuxFxVersion": "",
    "loadBalancing": null,
    "localMySqlEnabled": null,
    "logsDirectorySizeLimit": null,
    "machineKey": null,
    "managedPipelineMode": null,
    "managedServiceIdentityId": null,
    "metadata": null,
    "minTlsCipherSuite": null,
    "minTlsVersion": null,
    "minimumElasticInstanceCount": 0,
    "netFrameworkVersion": null,
    "nodeVersion": null,
    "numberOfWorkers": 1,
    "phpVersion": null,
    "powerShellVersion": null,
    "preWarmedInstanceCount": null,
    "publicNetworkAccess": null,
    "publishingPassword": null,
    "publishingUsername": null,
    "push": null,
    "pythonVersion": null,
    "remoteDebuggingEnabled": null,
    "remoteDebuggingVersion": null,
    "requestTracingEnabled": null,
    "requestTracingExpirationTime": null,
    "routingRules": null,
    "runtimeADUser": null,
    "runtimeADUserPassword": null,
    "sandboxType": null,
    "scmIpSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "scmIpSecurityRestrictionsDefaultAction": null,
    "scmIpSecurityRestrictionsUseMain": null,
    "scmMinTlsCipherSuite": null,
    "scmMinTlsVersion": null,
    "scmSupportedTlsCipherSuites": null,
    "scmType": null,
    "sitePort": null,
    "sitePrivateLinkHostEnabled": null,
    "storageType": null,
    "supportedTlsCipherSuites": null,
    "tracingOptions": null,
    "use32BitWorkerProcess": null,
    "virtualApplications": null,
    "vnetName": null,
    "vnetPrivatePortsCount": null,
    "vnetRouteAllEnabled": null,
    "webSocketsEnabled": null,
    "websiteTimeZone": null,
    "winAuthAdminState": null,
    "winAuthTenantState": null,
    "windowsConfiguredStacks": null,
    "windowsFxVersion": null,
    "xManagedServiceIdentityId": null
  },
  "slotSwapStatus": null,
  "state": "Running",
  "storageAccountRequired": false,
  "suspendedTill": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "targetSwapSlot": null,
  "trafficManagerHostNames": null,
  "type": "Microsoft.Web/sites",
  "usageState": "Normal",
  "virtualNetworkSubnetId": null,
  "vnetContentShareEnabled": false,
  "vnetImagePullEnabled": false,
  "vnetRouteAllEnabled": false,
  "workloadProfileName": null
}
[2025-07-02 16:00:46] Налаштування змінних середовища
[
  {
    "name": "DJANGO_SETTINGS_MODULE",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "DATABASE_URL",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "AZURE_STORAGE_ACCOUNT_NAME",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "AZURE_STORAGE_CONTAINER_STATIC",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "AZURE_STORAGE_CONTAINER_MEDIA",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "APPINSIGHTS_INSTRUMENTATIONKEY",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "APPLICATIONINSIGHTS_CONNECTION_STRING",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "DEBUG",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "ALLOWED_HOSTS",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "DJANGO_LOG_LEVEL",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "PYTHONPATH",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "SECRET_KEY",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "AZURE_STORAGE_ACCOUNT_KEY",
    "slotSetting": false,
    "value": null
  }
]
[2025-07-02 16:00:49] Налаштування App Service для Django
{
  "acrUseManagedIdentityCreds": false,
  "acrUserManagedIdentityId": null,
  "alwaysOn": false,
  "apiDefinition": null,
  "apiManagementConfig": null,
  "appCommandLine": "gunicorn --bind=0.0.0.0 --timeout 600 config.wsgi",
  "appSettings": null,
  "autoHealEnabled": false,
  "autoHealRules": null,
  "autoSwapSlotName": null,
  "azureStorageAccounts": {},
  "connectionStrings": null,
  "cors": null,
  "defaultDocuments": [
    "Default.htm",
    "Default.html",
    "Default.asp",
    "index.htm",
    "index.html",
    "iisstart.htm",
    "default.aspx",
    "index.php",
    "hostingstart.html"
  ],
  "detailedErrorLoggingEnabled": false,
  "documentRoot": null,
  "elasticWebAppScaleLimit": 0,
  "experiments": {
    "rampUpRules": []
  },
  "ftpsState": "FtpsOnly",
  "functionAppScaleLimit": null,
  "functionsRuntimeScaleMonitoringEnabled": false,
  "handlerMappings": null,
  "healthCheckPath": null,
  "http20Enabled": true,
  "httpLoggingEnabled": false,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/sites/django-app-production-1751471130",
  "ipSecurityRestrictions": [
    {
      "action": "Allow",
      "description": "Allow all access",
      "headers": null,
      "ipAddress": "Any",
      "name": "Allow all",
      "priority": 2147483647,
      "subnetMask": null,
      "subnetTrafficTag": null,
      "tag": null,
      "vnetSubnetResourceId": null,
      "vnetTrafficTag": null
    }
  ],
  "ipSecurityRestrictionsDefaultAction": null,
  "javaContainer": null,
  "javaContainerVersion": null,
  "javaVersion": null,
  "keyVaultReferenceIdentity": null,
  "kind": null,
  "limits": null,
  "linuxFxVersion": "PYTHON|3.11",
  "loadBalancing": "LeastRequests",
  "localMySqlEnabled": false,
  "location": "West Europe",
  "logsDirectorySizeLimit": 35,
  "machineKey": null,
  "managedPipelineMode": "Integrated",
  "managedServiceIdentityId": null,
  "metadata": null,
  "minTlsCipherSuite": null,
  "minTlsVersion": "1.2",
  "minimumElasticInstanceCount": 1,
  "name": "django-app-production-1751471130",
  "netFrameworkVersion": "v4.0",
  "nodeVersion": "",
  "numberOfWorkers": 1,
  "phpVersion": "",
  "powerShellVersion": "",
  "preWarmedInstanceCount": 0,
  "publicNetworkAccess": null,
  "publishingUsername": "$django-app-production-1751471130",
  "push": null,
  "pythonVersion": "",
  "remoteDebuggingEnabled": false,
  "remoteDebuggingVersion": "VS2022",
  "requestTracingEnabled": false,
  "requestTracingExpirationTime": null,
  "resourceGroup": "django-app-production-rg",
  "scmIpSecurityRestrictions": [
    {
      "action": "Allow",
      "description": "Allow all access",
      "headers": null,
      "ipAddress": "Any",
      "name": "Allow all",
      "priority": 2147483647,
      "subnetMask": null,
      "subnetTrafficTag": null,
      "tag": null,
      "vnetSubnetResourceId": null,
      "vnetTrafficTag": null
    }
  ],
  "scmIpSecurityRestrictionsDefaultAction": null,
  "scmIpSecurityRestrictionsUseMain": false,
  "scmMinTlsVersion": "1.2",
  "scmType": "None",
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "tracingOptions": null,
  "type": "Microsoft.Web/sites",
  "use32BitWorkerProcess": true,
  "virtualApplications": [
    {
      "physicalPath": "site\\wwwroot",
      "preloadEnabled": false,
      "virtualDirectories": null,
      "virtualPath": "/"
    }
  ],
  "vnetName": "",
  "vnetPrivatePortsCount": 0,
  "vnetRouteAllEnabled": false,
  "webSocketsEnabled": false,
  "websiteTimeZone": null,
  "windowsFxVersion": null,
  "xManagedServiceIdentityId": null
}
{
  "applicationLogs": {
    "azureBlobStorage": {
      "level": "Off",
      "retentionInDays": null,
      "sasUrl": null
    },
    "azureTableStorage": {
      "level": "Off",
      "sasUrl": null
    },
    "fileSystem": {
      "level": "Off"
    }
  },
  "detailedErrorMessages": {
    "enabled": true
  },
  "failedRequestsTracing": {
    "enabled": true
  },
  "httpLogs": {
    "azureBlobStorage": {
      "enabled": false,
      "retentionInDays": 3,
      "sasUrl": null
    },
    "fileSystem": {
      "enabled": true,
      "retentionInDays": 3,
      "retentionInMb": 100
    }
  },
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/sites/django-app-production-1751471130/config/logs",
  "kind": null,
  "location": "West Europe",
  "name": "logs",
  "resourceGroup": "django-app-production-rg",
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Web/sites/config"
}
[2025-07-02 16:00:56] Налаштування Managed Identity
{
  "principalId": "2393cd80-b73c-46fb-b75e-eacfadd119a2",
  "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8",
  "type": "SystemAssigned",
  "userAssignedIdentities": null
}
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.KeyVault/vaults/djapp-kv-71130",
  "location": "westeurope",
  "name": "djapp-kv-71130",
  "properties": {
    "accessPolicies": [
      {
        "applicationId": null,
        "objectId": "2b519bbb-fa41-470c-9279-95f55f66c3b9",
        "permissions": {
          "certificates": [
            "all"
          ],
          "keys": [
            "all"
          ],
          "secrets": [
            "set",
            "delete",
            "list",
            "get"
          ],
          "storage": [
            "all"
          ]
        },
        "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8"
      },
      {
        "applicationId": null,
        "objectId": "2393cd80-b73c-46fb-b75e-eacfadd119a2",
        "permissions": {
          "certificates": null,
          "keys": null,
          "secrets": [
            "list",
            "get"
          ],
          "storage": null
        },
        "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8"
      }
    ],
    "createMode": null,
    "enablePurgeProtection": null,
    "enableRbacAuthorization": false,
    "enableSoftDelete": true,
    "enabledForDeployment": false,
    "enabledForDiskEncryption": null,
    "enabledForTemplateDeployment": null,
    "hsmPoolResourceId": null,
    "networkAcls": null,
    "privateEndpointConnections": null,
    "provisioningState": "Succeeded",
    "publicNetworkAccess": "Enabled",
    "sku": {
      "family": "A",
      "name": "standard"
    },
    "softDeleteRetentionInDays": 90,
    "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8",
    "vaultUri": "https://djapp-kv-71130.vault.azure.net/"
  },
  "resourceGroup": "django-app-production-rg",
  "systemData": {
    "createdAt": "2025-07-02T15:53:44.037000+00:00",
    "createdBy": "vitalii_shevchuk3@epam.com",
    "createdByType": "User",
    "lastModifiedAt": "2025-07-02T16:01:04.728000+00:00",
    "lastModifiedBy": "vitalii_shevchuk3@epam.com",
    "lastModifiedByType": "User"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.KeyVault/vaults"
}
[2025-07-02 16:01:05] Увімкнення HTTPS
{
  "availabilityState": "Normal",
  "clientAffinityEnabled": true,
  "clientCertEnabled": false,
  "clientCertExclusionPaths": null,
  "clientCertMode": "Required",
  "cloningInfo": null,
  "containerSize": 0,
  "customDomainVerificationId": "277D8A1B15CA68EB12A5F295764EA158E61A2A3D155C88E7660BB300D2D92D51",
  "dailyMemoryTimeQuota": 0,
  "daprConfig": null,
  "defaultHostName": "django-app-production-1751471130.azurewebsites.net",
  "enabled": true,
  "enabledHostNames": [
    "django-app-production-1751471130.azurewebsites.net",
    "django-app-production-1751471130.scm.azurewebsites.net"
  ],
  "endToEndEncryptionEnabled": false,
  "extendedLocation": null,
  "hostNameSslStates": [
    {
      "certificateResourceId": null,
      "hostType": "Standard",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-app-production-1751471130.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    },
    {
      "certificateResourceId": null,
      "hostType": "Repository",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-app-production-1751471130.scm.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    }
  ],
  "hostNames": [
    "django-app-production-1751471130.azurewebsites.net"
  ],
  "hostNamesDisabled": false,
  "hostingEnvironmentProfile": null,
  "httpsOnly": true,
  "hyperV": false,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/sites/django-app-production-1751471130",
  "identity": {
    "principalId": "2393cd80-b73c-46fb-b75e-eacfadd119a2",
    "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8",
    "type": "SystemAssigned",
    "userAssignedIdentities": null
  },
  "inProgressOperationId": null,
  "isDefaultContainer": null,
  "isXenon": false,
  "keyVaultReferenceIdentity": "SystemAssigned",
  "kind": "app,linux",
  "lastModifiedTimeUtc": "2025-07-02T16:01:08.213333",
  "location": "West Europe",
  "managedEnvironmentId": null,
  "maxNumberOfWorkers": null,
  "name": "django-app-production-1751471130",
  "outboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,20.105.224.17",
  "possibleOutboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,51.124.61.31,51.124.61.49,51.124.61.56,51.124.61.142,51.124.61.184,51.124.61.192,51.105.209.160,51.105.210.136,51.105.210.122,51.124.56.53,51.124.61.162,51.105.210.2,51.124.61.169,51.105.209.155,51.124.57.83,51.124.62.101,51.124.57.229,51.124.58.97,20.105.224.17",
  "publicNetworkAccess": null,
  "redundancyMode": "None",
  "repositorySiteName": "django-app-production-1751471130",
  "reserved": true,
  "resourceConfig": null,
  "resourceGroup": "django-app-production-rg",
  "scmSiteAlsoStopped": false,
  "serverFarmId": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Web/serverfarms/django-app-production-plan",
  "siteConfig": {
    "acrUseManagedIdentityCreds": false,
    "acrUserManagedIdentityId": null,
    "alwaysOn": false,
    "antivirusScanEnabled": null,
    "apiDefinition": null,
    "apiManagementConfig": null,
    "appCommandLine": null,
    "appSettings": null,
    "autoHealEnabled": null,
    "autoHealRules": null,
    "autoSwapSlotName": null,
    "azureMonitorLogCategories": null,
    "azureStorageAccounts": null,
    "clusteringEnabled": false,
    "connectionStrings": null,
    "cors": null,
    "customAppPoolIdentityAdminState": null,
    "customAppPoolIdentityTenantState": null,
    "defaultDocuments": null,
    "detailedErrorLoggingEnabled": null,
    "documentRoot": null,
    "elasticWebAppScaleLimit": 0,
    "experiments": null,
    "fileChangeAuditEnabled": null,
    "ftpsState": null,
    "functionAppScaleLimit": null,
    "functionsRuntimeScaleMonitoringEnabled": null,
    "handlerMappings": null,
    "healthCheckPath": null,
    "http20Enabled": true,
    "http20ProxyFlag": null,
    "httpLoggingEnabled": null,
    "ipSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "ipSecurityRestrictionsDefaultAction": null,
    "javaContainer": null,
    "javaContainerVersion": null,
    "javaVersion": null,
    "keyVaultReferenceIdentity": null,
    "limits": null,
    "linuxFxVersion": "PYTHON|3.11",
    "loadBalancing": null,
    "localMySqlEnabled": null,
    "logsDirectorySizeLimit": null,
    "machineKey": null,
    "managedPipelineMode": null,
    "managedServiceIdentityId": null,
    "metadata": null,
    "minTlsCipherSuite": null,
    "minTlsVersion": null,
    "minimumElasticInstanceCount": 1,
    "netFrameworkVersion": null,
    "nodeVersion": null,
    "numberOfWorkers": 1,
    "phpVersion": null,
    "powerShellVersion": null,
    "preWarmedInstanceCount": null,
    "publicNetworkAccess": null,
    "publishingPassword": null,
    "publishingUsername": null,
    "push": null,
    "pythonVersion": null,
    "remoteDebuggingEnabled": null,
    "remoteDebuggingVersion": null,
    "requestTracingEnabled": null,
    "requestTracingExpirationTime": null,
    "routingRules": null,
    "runtimeADUser": null,
    "runtimeADUserPassword": null,
    "sandboxType": null,
    "scmIpSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "scmIpSecurityRestrictionsDefaultAction": null,
    "scmIpSecurityRestrictionsUseMain": null,
    "scmMinTlsCipherSuite": null,
    "scmMinTlsVersion": null,
    "scmSupportedTlsCipherSuites": null,
    "scmType": null,
    "sitePort": null,
    "sitePrivateLinkHostEnabled": null,
    "storageType": null,
    "supportedTlsCipherSuites": null,
    "tracingOptions": null,
    "use32BitWorkerProcess": null,
    "virtualApplications": null,
    "vnetName": null,
    "vnetPrivatePortsCount": null,
    "vnetRouteAllEnabled": null,
    "webSocketsEnabled": null,
    "websiteTimeZone": null,
    "winAuthAdminState": null,
    "winAuthTenantState": null,
    "windowsConfiguredStacks": null,
    "windowsFxVersion": null,
    "xManagedServiceIdentityId": null
  },
  "slotSwapStatus": null,
  "state": "Running",
  "storageAccountRequired": false,
  "suspendedTill": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "targetSwapSlot": null,
  "trafficManagerHostNames": null,
  "type": "Microsoft.Web/sites",
  "usageState": "Normal",
  "virtualNetworkSubnetId": null,
  "vnetContentShareEnabled": false,
  "vnetImagePullEnabled": false,
  "vnetRouteAllEnabled": false,
  "workloadProfileName": null
}
[2025-07-02 16:01:09] Створення файлів конфігурації
[2025-07-02 16:01:09] Створення cleanup скрипту: cleanup_azure_infrastructure.sh

============================================
📋 CLEANUP СКРИПТ СТВОРЕНО
============================================
📁 Файл: cleanup_azure_infrastructure.sh

🔧 Використання:
  ./cleanup_azure_infrastructure.sh              # Інтерактивне видалення
  ./cleanup_azure_infrastructure.sh --dry-run    # Показати план видалення
  ./cleanup_azure_infrastructure.sh --force      # Видалити без підтвердження
  ./cleanup_azure_infrastructure.sh --help       # Показати довідку

⚠️  УВАГА: Цей скрипт видалить ВСЮ створену інфраструктуру!
```





```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $  ./cleanup_azure_infrastructure.sh --help
Використання: ./cleanup_azure_infrastructure.sh [опції]

Опції:
  --help, -h     Показати цю довідку
  --dry-run      Показати що буде видалено без фактичного видалення
  --force        Пропустити підтвердження (НЕБЕЗПЕЧНО!)

Приклади:
  ./cleanup_azure_infrastructure.sh                 # Інтерактивне видалення
  ./cleanup_azure_infrastructure.sh --dry-run       # Показати план видалення
  ./cleanup_azure_infrastructure.sh --force         # Видалити без підтвердження
```


```bash

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./cleanup_azure_infrastructure.sh --dry-run
🔍 DRY RUN MODE - показуємо що буде видалено:
[2025-07-02 16:22:43] Перевірка поточних ресурсів...
true

📊 Поточні ресурси в групі django-app-production-rg:
Name                                                ResourceGroup             Location    Type                                                Status
--------------------------------------------------  ------------------------  ----------  --------------------------------------------------  --------
djapp1374072                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
djapp1387336                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751387336                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp1389430                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751389430                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-89430                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1390690                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751390690                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-90690                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1391690                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751391690                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-91690                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1393613                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751393613                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-93613                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1394601                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751394601                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-94601                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1396534                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751396534                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-96534                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-insights                      django-app-production-rg  westeurope  Microsoft.Insights/components
Application Insights Smart Detection                django-app-production-rg  global      microsoft.insights/actiongroups
Failure Anomalies - django-app-production-insights  django-app-production-rg  global      microsoft.alertsmanagement/smartDetectorAlertRules
djapp1428831                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751428831                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-28831                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-plan                          django-app-production-rg  westeurope  Microsoft.Web/serverFarms
django-app-production-1751428831                    django-app-production-rg  westeurope  Microsoft.Web/sites
djapp1471130                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751471130                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-71130                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-1751471130                    django-app-production-rg  westeurope  Microsoft.Web/sites


Ресурси, які будуть видалені:
- Resource Group: django-app-production-rg
- Всі ресурси всередині групи
- Локальні конфігураційні файли

Для фактичного видалення запустіть: ./cleanup_azure_infrastructure.sh
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

