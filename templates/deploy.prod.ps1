# Configure Development Environment Sub/Resource Group/Location
$subscriptionId = "Enter your Azure Subscription ID"
$resourcGroup = "Enter your Resource Group Name: rg-<project>-<envionment>-<location>-<sequence> format assumed in DevOps pipelines"
$location = "northeurope"

#Login
az login

#set subscription
az account set --subscription $subscriptionId     

#show current account subscriptions and resource groups and prompt before continuing
az account list --output table
az group list --output table

Read-Host -Prompt "Press ENTER key to continue or CTRL+C to quit" 

#create resource group and deploy resources
az group create --name $resourcGroup --location $location
az deployment group create --resource-group $resourcGroup  --template-file main.bicep --parameters params.pre.json
