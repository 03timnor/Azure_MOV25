#!/usr/bin/env bash
# Loads portal users and properties from CSV files into the storage tables.
#   ./V41_seed_users.sh V41_users.csv V41_properties.csv
#
# Needs: az login, the deploying identity must have "Storage Table Data Contributor"
# (granted by Bicep via callerObjectId), and allowedIpAddress must be set to your
# current public IP, because the storage account is otherwise not reachable.
set -euo pipefail

USERS_CSV="${1:-V41_users.csv}"
PROPS_CSV="${2:-V41_properties.csv}"
ENV_TYPE="${ENVIRONMENT_TYPE:-prod}"
RG="${RESOURCE_GROUP:-rg-nordvik-${ENV_TYPE}}"
SA=$(az storage account list -g "$RG" --query "[0].name" -o tsv)

# users: upn,roll,namn,fastighet,enhet,fastigheter   (fastigheter separated by ';')
tail -n +2 "$USERS_CSV" | tr -d '\r' | while IFS=, read -r upn roll namn fastighet enhet fastigheter || [ -n "$upn" ]; do
  [ -z "$upn" ] && continue
  az storage entity insert --account-name "$SA" --table-name Anvandare --auth-mode login \
    --if-exists replace --only-show-errors -o none --entity \
    PartitionKey=anvandare "RowKey=$(echo "$upn" | tr 'A-Z' 'a-z')" \
    "roll=$roll" "namn=$namn" "mail=$upn" "fastighet=$fastighet" "enhet=$enhet" \
    "fastigheter=${fastigheter//;/,}"
  echo "user: $upn ($roll)"
done

# properties: id,namn,forvaltarMail
tail -n +2 "$PROPS_CSV" | tr -d '\r' | while IFS=, read -r id namn mail || [ -n "$id" ]; do
  [ -z "$id" ] && continue
  az storage entity insert --account-name "$SA" --table-name Fastigheter --auth-mode login \
    --if-exists replace --only-show-errors -o none --entity \
    PartitionKey=fastighet "RowKey=$id" "namn=$namn" "forvaltarMail=$mail"
  echo "property: $id ($namn)"
done
