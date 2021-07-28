# Freifunk-Config-Backup-Tool
Remote backup for the local config files on Gluon based #Freifunk Routers

Freifunk-Config-Backup-Tool is written in Powershell v7. It's tested under macOS 11.
This script is designed to...
- check a list of IPv6 adresses within an Excel-File
- connect each of this adresses with an SSH key
- do a remote backup of the most important local config files
- and write down some technical specs back in your excel file

The Excel file template is provided within this repository. You might customize this file for your own needs.

Excel header description:
The Excel header is some kind of awful german-english mix, so let's have a deeper look.

This field is madatory to be filled by you:
- IP (device IPv4 address)

These fields may be filled by you:
- Gerätenummer (device ID)
- Typ (device type)
- Träger (device owner)
- Ortsteil (device city)
- Standort (device location)
- Bemerkung (remark)
- Karte (https-Link on your Freifunk Map)
- VLAN (what VLAN ID did you set for this device?

These fields will be filled/updated by the FCBT script:
- Name: what name is setted up on the router?
- Outdoor: is this device running in gluon outdoor mode?
- Domain: to which domain does this router belong to?
- VPNMesh: is this router allowed to do VPN mesh?
- Speedlimit: is a speedlimit set on this router?
- Branch: stable, experimental or something else inside the routers firmware?
- Autoupdater: may the router update automatically?
- SSH Keys: how many Keys are deployed on this router?
- Release: what firmware version is deployed on this router?
- Backup: timestamp of the last successful backup via FCBT

Prerequisits:
- Before starting FCBT, make sure your powershell installation is able to handle Microsoft Excel files. Yeah, you're reading right. Excel, not csv. Welcome to the 21st century ;-)
- to get a proper Excel handler, just do this command: Install-module PSExcel
- provide a ssh key to FCBT to allow scp/ssh logins for the script
- open fcbt.ps1 and check the other initiale paths provided at the top of the script
- next, fill in some IPv6 addresses in that excel template


Start the FCBT script:
- when all paths are set, start FCBT
- start the script: pwsh ./fcbt.ps1
- keep an eye on the output
