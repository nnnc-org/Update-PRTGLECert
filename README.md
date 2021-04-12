# Update-PRTGLECert
This script uses Posh-ACME and Let's Encrypt to update the SSL certificate used in PRTG
## How To Use:

### First Time Setup

If running Windows 2012 / Windows 2012 R2, you must first install PowerShell 5.1, available at [https://aka.ms/WMF5Download](https://aka.ms/WMF5Download). Also make sure .NET Framework 4.7.1 or greater is installed (available at [https://www.microsoft.com/en-us/download/details.aspx?id=56116](https://www.microsoft.com/en-us/download/details.aspx?id=56116)).  If installed, a reboot is required.

For Windows 2012 R2 and Windows 2016, set TLS to 1.2.  
Run command 
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

#### PowerShell version

This script is designed to run on PowerShell 5.1 or greater.  There have been issues on some PowerShell Core, so it is recommended not to use PowerShell Core at this time.  

#### Install Posh-ACME module

Run command to install Posh-ACME:
```powershell
Install-Module -Name Posh-ACME -Scope AllUsers -AcceptLicense
```

#### Request initial certificate
The script is designed to handle the renewals automatically, so you need to request the initial certificate manually.  In PowerShell:

```powershell
New-PACertificate -Domain sts.example.com -AcceptTOS -Contact me@example.com -DnsPlugin Cloudflare -PluginArgs @{CFAuthEmail="me@example.com";CFAuthKey='xxx'}

# After the above completes, run the following
$MainDomain = 'www.example.com'

# the '-UseExisting' flag is useful when the certifcate is not yet expired
./Update-PRTGLECert.ps1 -MainDomain $MainDomain -UseExisting
```
### Normal Use
To normally run it:

```powershell
./Update-PRTGLECert.ps1 -MainDomain $MainDomain
```

### Force Renewals

You can force a renewal with the '-ForceRenew' switch:

```powershell
./Update-PRTGLECert.ps1 -MainDomain $MainDomain -ForceRenew
```
### Other Notes

#### Switch Mutual Exclusivity

The '-ForceRenew' and '-UseExisting' switches are mutually exclusive, with '-UseExisting' superceeding '-ForceRenew'.

#### Logging

This script is set to automatically log the process and create a persistent log file in the same directory the script is located.  The name of the log file is UpdatePRTG.log

### PRTG-LetsEncrypt-Renewal.xml

This XML file is a sample scheduled task that can be imported into the Windows Task Scheduler to handle the automatic renewal process.  There are a few modifications that will need to be made following the import:
- General Tab
    - Change User or Group
        - Use administrator account, either local or domain
- Triggers
    - Change date / time (optional)
- Actions
    - Edit Task
        - Add arguments
            - Change sts.example.com to FQDN of ADFS server
        - Start in
            - Replace with path of actual location of the script

