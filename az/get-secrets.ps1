# Ejecutar
# ./secretos.ps1 -SubscriptionName "ejemplo-subcripción-nombre" -KeyVaultName "ejemplo-nombre-keyVault"

Param(
    [ValidateNotNullOrEmpty()] [Parameter(Mandatory)] $SubscriptionName,
    [ValidateNotNullOrEmpty()] [Parameter(Mandatory)] $KeyVaultName
)

# ---

function Date-Time-Name()
{
    return (Get-Date -UFormat "%Y-%m-%d_%I-%M-%S_%p").tostring()
}

# ---

$fileName = "secreto_$(Date-Time-Name).csv"

Write-Host "[+] Estableciendo Subscripción $SubscriptionName"
az account set --subscription $SubscriptionName


Write-Host "[+] Creando Archivo $fileName"
New-Item $fileName | Out-Null
echo "key,secretvalue" > $fileName

Write-Host "[+] Obteniedo Ids de todos los secretos del key vault $KeyVaultName"
$keyVaultEntries = (az keyvault secret list --vault-name $keyVaultName | ConvertFrom-Json) | Select-Object id, name

Write-Host "| key        |   secret value    |"
Write-Host "| ---------- | ----------------- |"

foreach($entry in $keyVaultEntries)
{
    $secretValue = (az keyvault secret show --id $entry.id | ConvertFrom-Json) | Select-Object name, value
    #Write-Host $secretValue.name "|" $secretValue.value
    echo "$($secretValue.name) | $($secretValue.value)"
    echo "$($secretValue.name),$($secretValue.value)"  >> $fileName
}