<#
.Synopsis
   Invoke Cypher
.DESCRIPTION
   Post Cypher Query to BloodHound REST API
.EXAMPLE
    Cypher "MATCH (x:User) RETURN x"
.EXAMPLE
    $Query="MATCH (n:User) RETURN n"
    Invoke-Cypher $Query -Expand $Null
#>
function Invoke-Cypher{
    [CmdletBinding()]
    [Alias('Cypher')]
    Param(
        [Parameter(Mandatory=1)][string]$Query,
        [Parameter(Mandatory=0)][Hashtable]$Params,
        [Parameter(Mandatory=0)][Alias('x')][String[]]$Expand=@('data','data')
        )
    # Uri 
    $Uri = "http://localhost:7474/db/data/cypher"
    # Header
    $Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
    # Body
    if($Params){$Body = @{params=$Params; query=$Query}|Convertto-Json}
    else{$Body = @{query=$Query}|Convertto-Json}
    # Call
    Write-Verbose "[$(Get-date -f h:m:s)] $Query"
    $Reply = Try{Invoke-RestMethod -Uri $Uri -Method Post -Headers $Header -Body $Body -verbose:$false}Catch{$Oops = $Error[0].ErrorDetails.Message}
    # Format obj
    if($Oops){Write-Warning "$((ConvertFrom-Json $Oops).message)";Return}
    if($Expand){$Expand | %{$Reply = $Reply.$_}} 
    # Output Reply
    if($Reply){Return $Reply}
    }
#End