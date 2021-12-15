# Connect-MgGraph -Scopes Policy.Read.All

$namedLocationObjects = @()
$namedLocationObjects =  Get-MgIdentityConditionalAccessNamedLocation -All | Select-Object *

$output = @()

foreach ($location in $namedLocationObjects)
{

    $data = @()

    $data = @{

        countries = $location.AdditionalProperties.countriesAndRegions -join '; '
        ranges = $location.AdditionalProperties.ipRanges.cidrAddress -join '; '
        isTrusted = $location.AdditionalProperties.isTrusted
        displayName = $location.DisplayName
        Id = $location.Id

    }

    $output += New-Object psobject -Property $data

}

$output | export-csv -Path .\TrustedLocationOutput.csv -NoTypeInformation -UseQuotes Always