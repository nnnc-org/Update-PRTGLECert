<#
.SYNOPSIS
This is a simple Powershell script to update PRTG SSL certificate with a LetsEncrypt cert

.DESCRIPTION
This script uses the Posh-Acme module to RENEW a LetsEncrypt certificate, and then applies it to PRTG. This is designed to be ran consistently, and will not update the cert if Posh-Acme hasn't been setup previously.

.EXAMPLE
./Update-PRTGLECert.ps1 -MainDomain prtg.example.com

.NOTES
This requires Posh-Acme to be preconfigured. The easiest way to do so is with the following command:
    New-PACertificate -Domain fg.example.com,fgt.example.com,vpn.example.com -AcceptTOS -Contact me@example.com -DnsPlugin Cloudflare -PluginArgs @{CFAuthEmail="me@example.com";CFAuthKey='xxx'}

.LINK
https://github.com/northeastnebraskanetworkconsortium/Update-PRTGLECert
#>

Param(
    [string]$MainDomain,
    [switch]$UseExisting,
    [switch]$ForceRenew
)

function Logging {
    param([string]$Message)
    Write-Host $Message
    $Message >> $LogFile
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module PKI
Import-Module Posh-Acme
Import-Module WebAdministration
$LogFile = '.\UpdatePRTG.log'
Get-Date | Out-File $LogFile -Append
if($UseExisting) {
    Logging -Message "Using Existing Certificate"
    $cert = get-pacertificate -MainDomain $MainDomain
}
else {
    if($ForceRenew) {
        Logging -Message "Starting Forced Certificate Renewal"
        $cert = Submit-Renewal -MainDomain $MainDomain -Force
    }
    else {
        Logging -Message "Starting Certificate Renewal"
        $cert = Submit-Renewal -MainDomain $MainDomain
    }
    Logging -Message "...Renew Complete!"
}

if($cert){
    Logging -Message "Importing certificate to Cert:\LocalMachine\My"
    Import-PfxCertificate -FilePath $cert.PfxFullChain -CertStoreLocation Cert:\LocalMachine\My -Password ('poshacme' | ConvertTo-SecureString -AsPlainText -Force)
    
    Logging -Message "Remove previous old cert information"
    Remove-Item 'C:\Program Files (x86)\PRTG Network Monitor\cert\*original*.*'
    
    Logging -Message "Rename previous cert to old"
    Rename-Item 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.crt' 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg-original.crt'
    Rename-Item 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.key' 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg-original.key'
    Rename-Item 'C:\Program Files (x86)\PRTG Network Monitor\cert\root.pem' 'C:\Program Files (x86)\PRTG Network Monitor\cert\root-original.pem'
    
    Logging -Message "Copy new cert info to PRTG"
    Copy-Item 'C:\Users\PRTG\AppData\Local\Posh-ACME\acme-v02.api.letsencrypt.org\101341045\outsideprtg.nnnc.org\cert.cer' 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.crt'
    Copy-Item 'C:\Users\PRTG\AppData\Local\Posh-ACME\acme-v02.api.letsencrypt.org\101341045\outsideprtg.nnnc.org\cert.key' 'C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.key'
    Copy-Item 'C:\Users\PRTG\AppData\Local\Posh-ACME\acme-v02.api.letsencrypt.org\101341045\outsideprtg.nnnc.org\fullchain.cer' 'C:\Program Files (x86)\PRTG Network Monitor\cert\root.pem'    

    Logging -Message "Restarting PRTG"
    Restart-Service PRTGCoreService
    
    # Remove old certs
    ls Cert:\LocalMachine\My | ? Subject -eq "CN=$MainDomain" | ? NotAfter -lt $(get-date) | remove-item -Force
}else{
    Logging -Message "No need to update PRTG certifcate" 
}

