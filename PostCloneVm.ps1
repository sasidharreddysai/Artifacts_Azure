#Running script in Administrator mode......

$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$testadmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($testadmin -eq $false) {
Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
exit $LASTEXITCODE
}

[CmdletBinding()]
param(
    [string] $hostName
)

#Write-Host "For example, sdxma is the host name in Https://sdxma.devdemo.hexagonppm.com"
#$hostName = Read-Host -Prompt 'Enter New Host Name'

function postCloneVmStepsInConfigFiles
{

    #....
    #param ([string] $currentHostName)
    $filePath="C:\SmartPlant Foundation Server Files\Web_Sites\SDxServer\web.config"

    [xml]$file = Get-Content $filePath
    $issuerUrl="https://" + $hostName + ".devdemo.hexagonppm.com/sdxconfigsvc/spfauthentication/oauth"
    $file.configuration.'intergraph.webApi'.security.oauth.SetAttribute("issuer",$issuerUrl)
    $file.Save($filePath)

    #.....
    $filePath2="C:\SmartPlant Foundation Server Files\Web_Sites\SDxServer\SPFConfigService\SPFSharedSettings\SPFAppServer.config"

    [xml]$file2 = Get-Content $filePath2
    $defaultSPFServerUrl="https://" + $hostName + ".devdemo.hexagonppm.com/SDxServer"
    $notificationHostName= $hostName + ".devdemo.hexagonppm.com"
    $bravaStamps= "https://" + $hostName + ".devdemo.hexagonppm.com/sdx/content/stamps/stamps.json"
    $bravaSymbols="https://" + $hostName + ".devdemo.hexagonppm.com/sdx/content/symbols/symbols.json"

    #....
    $file2.SelectSingleNode("configuration/appSettings/add[@key='DefaultSPFServerURL']").setAttribute("value",$defaultSPFServerUrl)
    $file2.SelectSingleNode("configuration/appSettings/add[@key='NotificationHostName']").setAttribute("value",$notificationHostName)
    if(($null -ne $file2.SelectSingleNode("configuration/appSettings/add[@key='BravaStamps']")))
    {
        $file2.SelectSingleNode("configuration/appSettings/add[@key='BravaStamps']").setAttribute("value",$bravaStamps)
    }
    if(($null -ne $file2.SelectSingleNode("configuration/appSettings/add[@key='BravaSymbols']")))
    {
        $file2.SelectSingleNode("configuration/appSettings/add[@key='BravaSymbols']").setAttribute("value",$bravaSymbols)
    }
    $file2.Save($filePath2)

    #.....
    $rootUrl="https://" + $hostName  + ".devdemo.hexagonppm.com/sdx/content/symbols"
    $pathSymbols="C:\SmartPlant Foundation Server Files\SPFWebClient_Sites\SDX\content\symbols\symbols.json"

    if(Test-Path $pathSymbols -PathType leaf)
    {
      $fileSymbols = Get-Content -Path $pathSymbols -Raw | ConvertFrom-Json
      $fileSymbols.PSObject.Properties.Remove('rootUrl')
      $fileSymbols | Add-Member -Type NoteProperty -Name 'rootUrl' -Value $rootUrl
      $fileSymbols | ConvertTo-Json -Depth 100 | Out-File $pathSymbols -Force
    }

    #.....
    $pathSettings="C:\SmartPlant Foundation Server Files\SPFWebClient_Sites\SDX\settings.js"
    
    $regex='.devdemo.hexagonppm.com'

    foreach($line in Get-Content $pathSettings) {
        if($line -match $regex){
         #Write-Host $line 
         break
        }
    }
    $pattern = "https://(.*).devdemo.(.*)"
    $currentHostName = [regex]::match($line, $pattern).Groups[1].Value

    $fileSettings= Get-Content -Path $pathSettings -Raw
    $fileSettings.Replace($currentHostName,$hostName) | Out-File $pathSettings -Force


}

function postCloneVmStepsInSDFFile
{

    ### changes in sdf file for Change to the STS for machine name 


    [Reflection.Assembly]::LoadFile(“C:\SmartPlant Foundation Server Files\Web_Sites\SDxServer\SPFConfigService\SPFAuthentication\bin\System.Data.SqlServerCe.dll”)

    #sdf file location is set here......

    $connString = "Data Source=C:\SmartPlant Foundation Server Files\Web_Sites\SDxServer\SPFConfigService\SPFAuthentication\App_Data\Security.sdf"
    $cn = new-object "System.Data.SqlServerCe.SqlCeConnection" $connString
    $cmd = new-object "System.Data.SqlServerCe.SqlCeCommand"
    $cmd.CommandType = [System.Data.CommandType]"Text"

     #ClientPostLogoutRedirectUris

    $sdx1= "https://"+ $hostName +".devdemo.hexagonppm.com/sdx/"

    $cmd.CommandText = "UPDATE ClientPostLogoutRedirectUris set Uri='"+ $sdx1 +"' where Uri like 'https://%.devdemo.hexagonppm.com/sdx/' or Uri like 'https://%.devdemo.hexagonppm.com/sdx'"
    $cmd.Connection = $cn
    #get the data
    $dt = new-object "System.Data.DataTable"
    $cn.Open()
    $rdr = $cmd.ExecuteReader()
    $dt.Load($rdr)
    $cn.Close()

    #ClientRedirectUris

    $cmd.CommandText = "UPDATE ClientRedirectUris set Uri='"+ $sdx1 +"' where Uri like 'https://%.devdemo.hexagonppm.com/sdx/' or Uri like 'https://%.devdemo.hexagonppm.com/sdx/'"
    $cmd.Connection = $cn
    #get the data
    $dt = new-object "System.Data.DataTable"
    $cn.Open()
    $rdr = $cmd.ExecuteReader()
    $dt.Load($rdr)
    $cn.Close()
    $dt.IssuerUri | Out-Default | Format-Table

    #
    $sdx2="https://"+ $hostName +".devdemo.hexagonppm.com/sdx/_session.html"

    $cmd.CommandText = "UPDATE ClientRedirectUris set Uri='"+ $sdx2 +"' where Uri like 'https://%.devdemo.hexagonppm.com/sdx/_session.html/' or Uri like 'https://%.devdemo.hexagonppm.com/sdx/_session.html'"
    $cmd.Connection = $cn
    #get the data
    $dt = new-object "System.Data.DataTable"
    $cn.Open()
    $rdr = $cmd.ExecuteReader()
    $dt.Load($rdr)
    $cn.Close()
    $dt.IssuerUri | Out-Default | Format-Table

    #


    $sdx4="https://" +$hostName + ".devdemo.hexagonppm.com/_session.html/"

    $cmd.CommandText = "UPDATE ClientRedirectUris set Uri='"+ $sdx4 +"' where Uri like 'https://%.devdemo.hexagonppm.com/_session.html/' or Uri like 'https://%.devdemo.hexagonppm.com/_session.html'"
    $cmd.Connection = $cn
    #get the data
    $dt = new-object "System.Data.DataTable"
    $cn.Open()
    $rdr = $cmd.ExecuteReader()
    $dt.Load($rdr)
    $cn.Close()
    $dt.IssuerUri | Out-Default | Format-Table

    #ServerConfigurations

    $sdx3=$hostName + ".devdemo.hexagonppm.com,sdxserver"
    $cmd.CommandText = "UPDATE ServerConfigurations set IssuerUri='"+ $sdx1 +"', UserServiceInitializationString='"+ $sdx3 +"', SessionHandlerInitializationString='"+ $sdx3 +"' where IssuerUri like '%https://%.devdemo.hexagonppm.com/sdx/' or IssuerUri like '%https://%.devdemo.hexagonppm.com/sdx'"
    $cmd.Connection = $cn
    #get the data
    $dt = new-object "System.Data.DataTable"
    $cn.Open()
    $rdr = $cmd.ExecuteReader()
    $dt.Load($rdr)
    $cn.Close()
    $dt.IssuerUri | Out-Default | Format-Table
}

function postCLoneVmStepsforHostinSqldb
{
   $sqlServerInstance = "sdxdemoapp1\MSSQL2017"
   $siteDb = "SDX_DemoData"

   $hostNamePPMUrl= $hostName + ".devdemo.hexagonppm.com"
   $hostNameAzureUrl=$hostName + ".westeurope.cloudapp.azure.com"

   #creating sql commands to change the current host object and its name to new host name

   $schemaObjHostPPM= "update SCHEMAOBJ set OBJNAME ='"+ $hostNamePPMUrl+"' where OBID='6I3B000A'"
   $schemaObjHostAzure="update SCHEMAOBJ set OBJNAME='"+ $hostNameAzureUrl+"' where OBID='6IXS000A'"

   $schemaObjPrHostPPM=" update SCHEMAOBJPR set STRVALUE ='"+ $hostNamePPMUrl+"' where OBID='78GZ009A'"
   $schemaObjPrHostazure="update SCHEMAOBJPR set STRVALUE='"+ $hostNameAzureUrl+"' where OBID='7P7O009A'"

   #Executing the commands

   Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Database $siteDb -Query $schemaObjHostPPM
   Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Database $siteDb -Query $schemaObjHostAzure
   Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Database $siteDb -Query $schemaObjPrHostPPM
   Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Database $siteDb -Query $schemaObjPrHostazure
}

postCloneVmStepsInConfigFiles
postCloneVmStepsInSDFFile
postCLoneVmStepsforHostinSqldb
Write-Host "Executing 'iisreset' command...."
#invoke-command -scriptblock {iisreset}
exit