#!/usr/bin/env bash
# Automated configuration of Novatrix web server

set -e

RESOURCE_GROUP="rg-novatrix"
LOCATION="swedencentral"
VM_NAME="VM-Novatrix-Web"
VM_SIZE="Standard_B2ats_v2"

VNET_NAME="vnet-novatrix"
VNET_PREFIX="10.0.0.0/16"
SUBNET_WEB_NAME="snet-web"
SUBNET_WEB_PREFIX="10.0.1.0/24"
SUBNET_DB_NAME="snet-db"
SUBNET_DB_PREFIX="10.0.2.0/24"
SUBNET_BASTION_NAME="AzureBastionSubnet"
SUBNET_BASTION_PREFIX="10.0.3.0/26"

NSG_WEB_NAME="nsg-web"

BASTION_NAME="bastion-novatrix"
BASTION_PIP_NAME="pip-bastion-novatrix"

echo "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Creating VNet with snet-web subnet..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefix "$VNET_PREFIX" \
  --subnet-name "$SUBNET_WEB_NAME" \
  --subnet-prefix "$SUBNET_WEB_PREFIX"

echo "Creating snet-db subnet..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_DB_NAME" \
  --address-prefix "$SUBNET_DB_PREFIX"

echo "Creating AzureBastionSubnet..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_BASTION_NAME" \
  --address-prefix "$SUBNET_BASTION_PREFIX"

echo "Creating NSG nsg-web..."
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG_WEB_NAME"

echo "Adding rule to allow HTTP (80) from the internet..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_WEB_NAME" \
  --name "Allow-HTTP" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80

echo "Adding rule to allow HTTPS (443) from the internet..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_WEB_NAME" \
  --name "Allow-HTTPS" \
  --priority 150 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

echo "Associating nsg-web with snet-web..."
az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_WEB_NAME" \
  --network-security-group "$NSG_WEB_NAME"

echo "Creating public IP for Azure Bastion..."
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$BASTION_PIP_NAME" \
  --sku Standard \
  --location "$LOCATION"

echo "Creating Azure Bastion host (Standard SKU with native client support, this can take several minutes)..."
az network bastion create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$BASTION_NAME" \
  --vnet-name "$VNET_NAME" \
  --public-ip-address "$BASTION_PIP_NAME" \
  --location "$LOCATION" \
  --sku Standard \
  --enable-tunneling true

echo "Creating virtual machine with cloud-init..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size "$VM_SIZE" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init.yaml \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_WEB_NAME" \
  --public-ip-sku Standard

echo "Done! Public IP:"
az vm show -d \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query publicIps -o tsv

echo "To connect via Bastion from your local terminal, run:"
echo "az network bastion ssh --name $BASTION_NAME --resource-group $RESOURCE_GROUP --target-resource-id \$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query id -o tsv) --auth-type ssh-key --username azureuser --ssh-key ~/.ssh/id_rsa"