    # use the excel template provided at https://github.com/andreaswditze/Freifunk-Config-Backup-Tool
    [string]$RouterFile = "~/FF/routerfile.xlsx"
    
    # use default openssh private key without password
    [string]$KeyFile = "~/.ssh/my_secret_freifunk_key"
    
    # mostly fine
    [string]$userName = "root"
    
    # Hint for Windows10 users: just type 'scp' in here
    [string]$ScpBin = '/usr/bin/scp'
  
    # that's where the backups are stored
    [string]$ConfigStorage = "~/FF/routerbackups"
    
    # this directory just for temporary usage
    [string]$TempStorage = "~/FF/temp"

    # directory for routerfile backups
    # empty variable means: no backup
    [string]$RouterfileBackupStorage = "~/FF/excelbackups"

    # where to find any errors logged by this script
    [string]$RedirectStandardError = "~/FF/error.log"
    
    # where to move some noisy console output
    [string]$RedirectStandardOutput = "~/FF/output.log"
