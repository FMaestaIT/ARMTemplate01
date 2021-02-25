Deployment Resource to Subscription Scope

location="WestEurope"

Validate Template
az deployment validate --template-file azuredeploy.json --parameters @azuredeploy.parameters.json --location $location

Verificare che l'output del comando presenti la proprietà error valorizzata "null"
{- Finished ..
  "error": null,
  "id": "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/providers/Microsoft.Resources/deployments/azuredeploy",
  "location": "westeurope",
  "name": "azuredeploy",
  .........................

What-If Template
az deployment sub what-if --template-file azuredeploy.json  --parameters @azuredeploy.parameters.json --location $location
L'output indicherà esattamente il risultato dell'applicazione del template:
Note: The result may contain false positive predictions (noise).
You can help us improve the accuracy of the result by opening an issue here: https://aka.ms/WhatIfIssues.

Resource and property changes are indicated with this symbol:
  + Create

The deployment will update the following scope:

Scope: /subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc

  + resourceGroups/rg-shared-prod-we-001 [2018-05-01]

      apiVersion:       "2018-05-01"
      id:               "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001"
      location:         "West Europe"
      name:             "rg-shared-prod-we-001"
      tags.Application: "Infra"
      tags.Environment: "Prod"
      tags.Location:    "WestEurope"
      type:             "Microsoft.Resources/resourceGroups"

Resource changes: 1 to create.



Deploy Resource By Template to Subscription Scope
az deployment sub create --template-file azuredeploy.json  --parameters @azuredeploy.parameters.json --location $location

L'output indicherà il termine del deployment del template

{- Finished ..
  "id": "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/providers/Microsoft.Resources/deployments/azuredeploy",
  "location": "westeurope",
  "name": "azuredeploy",
  "properties": {
   .........


Deploymnet Resource to Resource Group Scope


resourcegroup="rg-shared-prod-we-001"

az deployment group validate --resource-group $resourcegroup --template-file azuredeploy.json  --parameters @azuredeploy.parameters.json


{- Finished ..
  "error": null,
  "id": "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001/providers/Microsoft.Resources/deployments/azuredeploy",
  "name": "azuredeploy",
  "properties": {
   ..................


az deployment group what-if --resource-group $resourcegroup --template-file azuredeploy.json  --parameters @azuredeploy.parameters.json


Note: The result may contain false positive predictions (noise).
You can help us improve the accuracy of the result by opening an issue here: https://aka.ms/WhatIfIssues.

Resource and property changes are indicated with this symbol:
  + Create

The deployment will update the following scope:

Scope: /subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001

  + Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001 [2020-05-01]

      apiVersion:               "2020-05-01"
      id:                       "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001/providers/Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001"
      location:                 "West Europe"
      name:                     "vnet-shared-prod-we-001"
      properties.addressSpace.addressPrefixes: [
        0: "10.32.0.0/20"
      ]
      properties.subnets: [
        0:

          location:                 "West Europe"
          name:                     "snet-shared-private-we-001"
          properties.addressPrefix: "10.32.1.0/24"

        1:

          location:                 "West Europe"
          name:                     "snet-shared-public-we-001"
          properties.addressPrefix: "10.32.15.0/24"

      ]
      tags.Application:         "Infra"
      tags.Environment:         "Prod"
      tags.Location:            "WestEurope"
      type:                     "Microsoft.Network/virtualNetworks"

  + Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001/subnets/snet-shared-private-we-001 [2020-05-01]

      apiVersion:               "2020-05-01"
      id:                       "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001/providers/Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001/subnets/snet-shared-private-we-001"
      location:                 "West Europe"
      name:                     "snet-shared-private-we-001"
      properties.addressPrefix: "10.32.1.0/24"
      type:                     "Microsoft.Network/virtualNetworks/subnets"

  + Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001/subnets/snet-shared-public-we-001 [2020-05-01]

      apiVersion:               "2020-05-01"
      id:                       "/subscriptions/a2434dbe-10cc-4342-b4e6-4adc25a7f8cc/resourceGroups/rg-shared-prod-we-001/providers/Microsoft.Network/virtualNetworks/vnet-shared-prod-we-001/subnets/snet-shared-public-we-001"
      location:                 "West Europe"
      name:                     "snet-shared-public-we-001"
      properties.addressPrefix: "10.32.15.0/24"
      type:                     "Microsoft.Network/virtualNetworks/subnets"

Resource changes: 3 to create.





