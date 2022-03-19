
#########################################
#   Freifunk Config Backup Tool (FCBT)  #
# powered by www.freifunk-nordhessen.de #
#########################################


#.\config.macos.ps1
. .\config_example.ps1

# Requirments: 
# Install-module PSExcel

# we need this
Import-Module PSExcel

# clear screen
Clear-Host

# send welcome messange
Write-Host "*******************************************"
Write-Host "Starting Freifunk Config Backup Tool (FCBT)"
Write-Host "*******************************************"
Write-Host ""
Write-Host "Path to Routerfile  = $RouterFile"
Write-Host "Path to Downloads   = $ConfigStorage"
Write-Host "Path to RSA Keyfile = $KeyFile"

$RouterNewFile = $RouterFile


#$Debug = $TRUE

function scp-data-from-server
{
    param 
    (
        [string]$target
    )

    # connect IP via SCP and get files to temp directory
    if ($Debug) 
    {
        # in debug mode we're only parsing the first 5 items
        if ($Index -lt 5) 
        {
            Start-Process $ScpBin -ArgumentList "-6 -o StrictHostKeyChecking=no -o ConnectTimeout=15 -i $KeyFile $target" -RedirectStandardError "$RedirectStandardError" -RedirectStandardOutput "$RedirectStandardOutput" -Wait -NoNewWindow
        }
    }
    else 
    {
        Start-Process $ScpBin -ArgumentList "-6 -o StrictHostKeyChecking=no -o ConnectTimeout=15 -i $KeyFile $target" -RedirectStandardError "$RedirectStandardError" -RedirectStandardOutput "$RedirectStandardOutput" -Wait -NoNewWindow        
    }
}


function get-data-from-file 
{
    param 
    (
        [string]$filename,
        [string]$searchphrase
    )

    if (Test-Path -Path $filename)
    {
        # CHECK FOR HOSTNAME
        # if system file is available, get its content
        $Temp = Get-Content -Path $filename

        $ReplaceString = $searchphrase+' '
        $Result = ''

        # parse system file, looking for hostname
        ForEach ($Line in $Temp)
        {
            if ($Line.Contains($searchphrase))
            {
                $Result = $Line
                $Result = $Result -replace "$ReplaceString",''
                $Result = $Result -replace "\'",''
                $Result = $Result -replace "\s",''
            }
        }    

        Return $Result

    }
    else 
    {
        Return $FALSE    
    }

}


# Import Routerlist
$ExcelFile = Import-XLSX -Path "$RouterFile" -ErrorAction SilentlyContinue

if (!($ExcelFile))
{
    Write-Warning "Access violation, cannot lock $RouterFile"
    Write-Warning "Close file and start again."
    exit
}

# create backup for routerfile
if ($RouterfileBackupStorage)
{
    if (!(Test-Path $RouterfileBackupStorage))
    {
        $NULL = New-Item -ItemType Directory $RouterfileBackupStorage
    }
    
    # when do we've done the backup
    $BackupDatetime = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    $BackupFile = $RouterfileBackupStorage+'\'+$BackupDatetime+'.xlsx'
    Copy-Item -Path $RouterFile -Destination $BackupFile
    
    if (Test-Path -Path $RouterfileBackupStorage)
    {
        Write-Host "Routerfile backup successfully"
    }
    else
    {
        Write-Warning "Routerfile backup failed"
        Write-Warning "Backup target: $RouterfileBackupStorage"
        Write-Warning "Check directory and start again"
        exit
    }

}
else
{
    "Routerfile backup not configured. Skipping..."
    'Define $RouterFileBackupStorage in config file to get routerfile backups' 
}


# in this array we'll store the "new" excel file
$RouterDataArray = New-Object System.Collections.ArrayList

# parse existing excel file
ForEach ($Item in $ExcelFile)
{
    # create one item per excel file line
    $RouterData =  New-Object -TypeName PSObject -Property @{
        DeviceID = [int]$Item.DeviceID
        Type = $Item.Type
        Owner = $Item.Owner
        District = $Item.District
        Location = $Item.Location
        MapLink = $Item.MapLink
        Notes = $Item.Notes
        VLAN = [int]$Item.VLAN
        IP = $Item.IP
        Outdoor = [int]$Item.Outdoor
        Name = $Item.Name
        Backup = $Item.Backup
        Domain = $Item.Domain
        VPNMesh = $Item.VPNMesh
        Speedlimit = $Item.Speedlimit
        Branch = $Item.Branch
        Autoupdater = $Item.Autoupdater
        SSHKeys = $Item.SSHKeys
        Release = $Item.Release
        LocalContactName = $Item.LocalContactName
        LocalContactPhone = $Item.LocalContactPhone
        LocalContactMail = $Item.LocalContactMail

    } | Select-Object DeviceID, 
    Type, 
    Owner, 
    District, 
    Location, 
    LocalContactName,
    LocalContactPhone,
    LocalContactMail,
    Notes,
    Name,
    MapLink, 
    IP, 
    Outdoor, 
    Domain, 
    VPNMesh, 
    Speedlimit, 
    Branch, 
    Autoupdater, 
    SSHKeys, 
    Release,
    VLAN,
    Backup

    $Null = $RouterDataArray.add($RouterData)
}

# Create Download Directory
if (!(Test-Path -Path $ConfigStorage))
{
    $NULL = New-Item -ItemType Directory $ConfigStorage
}

# Create Temp Directory
if (!(Test-Path -Path $TempStorage))
{
    $NULL = New-Item -ItemType Directory $TempStorage
}
else 
{
    if (!($Debug))
    {
        Write-Warning "$TempStorage already exists. Remove directory $TempStorage manually."
        exit    
    }
    else 
    {
        # clear everything in temp
        $DeleteAllFiles = $TempStorage+'/*'
        Remove-Item -Force -Path $DeleteAllFiles       
    }
    
   
}

# parse existing excel file and check reachable IPs
$Index = 0

Write-Host "Parsing IP column in $Routerfile"

ForEach ($Entry in $ExcelFile)
{

    # check Excel File if there is an IP available
    if ($Entry.IP)
    {
        # GET EVERYTHING FROM /ETC/CONFIG
        $Target = $userName+'@['+$Entry.IP+']:/etc/config/* '+$TempStorage
        scp-data-from-server -target "$Target"

        # GET /ETC/DROPBEAR
        $Target = $userName+'@['+$Entry.IP+']:/etc/dropbear/* '+$TempStorage
        scp-data-from-server -target $Target

        # GET /LIB/GLUON/RELEASE
        $Target = $userName+'@['+$Entry.IP+']:/lib/gluon/release '+$TempStorage
        scp-data-from-server -target $Target

        # check if we've got a file called "system"
        $SystemFile = $TempStorage + "/system"
    
        if (Test-Path -Path "$SystemFile")
        {
            # CHECK FOR HOSTNAME
            # if system file is available, get its content
            $Temp = Get-Content -Path $SystemFile

            # when do we've done the backup
            $BackupDatetime = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
            $RouterDataArray[$Index].Backup = $BackupDatetime

            $SystemFile = $TempStorage + "/system"
            $Hostname = get-data-from-file -filename "$SystemFile" -searchphrase "option hostname"
            if (!($Hostname)) {$Hostname="unknown"}
            $RouterDataArray[$Index].Name = $Hostname

            $SystemFile = $TempStorage + "/gluon"
            $RouterDataArray[$Index].Outdoor = [int](get-data-from-file -filename "$SystemFile" -searchphrase "option outdoor")
            $RouterDataArray[$Index].Domain = [string](get-data-from-file -filename "$SystemFile" -searchphrase "option domain")
            $RouterDataArray[$Index].VPNMesh = [int](get-data-from-file -filename "$SystemFile" -searchphrase "option enabled")
            $RouterDataArray[$Index].Speedlimit = [int](get-data-from-file -filename "$SystemFile" -searchphrase "option limit_enabled")
            
            $SystemFile = $TempStorage + "/autoupdater"
            $RouterDataArray[$Index].Branch = [string](get-data-from-file -filename "$SystemFile" -searchphrase "option branch")
            $RouterDataArray[$Index].Autoupdater = [int](get-data-from-file -filename "$SystemFile" -searchphrase "option enabled")

            $SystemFile = $TempStorage + "/release"
            $RouterDataArray[$Index].Release = [string](get-data-from-file -filename "$SystemFile" -searchphrase "")
            
            # Count SSH Keys
            $SystemFile = $TempStorage + "/authorized_keys"
            $AuthorizedKeys = Get-Content "$SystemFile"
            $Keys = Select-String -InputObject $AuthorizedKeys -Pattern "ssh-rsa" -AllMatches
            $RouterDataArray[$Index].SSHKeys = $Keys.Matches.Count

            # set final storage directory, that's the place we're putting the configs for this router
            $FinalStorage = $ConfigStorage+"/$Hostname/$BackupDatetime"

            # check if hostname is already a directory
            if (!(Test-Path -Path ($ConfigStorage+"/$Hostname")))
            {
                $NULL = New-Item -ItemType Directory -Path $FinalStorage
            }

            # if path is not available, we're creating it
            if (!(Test-Path -Path $FinalStorage))
            {
                $NULL = New-Item -ItemType Directory -Path $FinalStorage
            }

            # we're moving the config files from the temp directory to the final place
            $NULL = Move-Item -Path "$TempStorage/*" -Destination $FinalStorage -Force

            # everything fine
            Write-Host "Router" $Entry.DeviceID "available, $Hostname successfuly saved"
           
        }
        else 
        {
            # give some hint if we can't reach a host
            Write-Host "Router" $Entry.DeviceID "not available"
        }
    }

    $Index=$Index+1
}

# Export new Excel
$RouterDataArray | Export-XLSX -Path "$RouterNewFile" -Force -Table -WorksheetName "Freifunk Router"

# Remove Temp Directory
Remove-Item $TempStorage -Force

# Fully done
Write-Host "Router Backup Task completed"
