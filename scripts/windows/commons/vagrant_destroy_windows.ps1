<#
.Synopsis
   Destroy lab for learning
.DESCRIPTION
   This script is used for destroy lab with vagrant.
   Destroy and delete all VM's in Vagrantfile
   Delete all folders with VM's in Vagrantfile
.EXAMPLE
   & vagrant_destroy_windows.ps1
#>

# Execute script as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process -Wait powershell -Verb runAs -WindowStyle Hidden -ArgumentList $arguments
  Break
}

# Stop vagrant process
Get-Process -Name *vagrant* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name *ruby* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Define variables
switch ($(hostname)) {
    "silvestrini" {       
        $vagrant = "E:\Apps\Vagrant\bin\vagrant.exe"
        $baseVagrantfile="F:\Projetos\learning-kubernetes\vagrant\linux"
        $vagrantHome = "E:\Apps\Vagrant\vagrant.d"      
        $virtualboxFolder = "E:\Apps\VirtualBox"
        $virtualboxVMFolder = "E:\Servers\VirtualBox"         
        $vmwareVMFolder = "E:\Servers\VMware" 
    }
    "silvestrini2" {      
        # Variables
        $vagrant = "D:\Cloud\Vagrant\bin\vagrant.exe"  
        $baseVagrantfile="F:\Projetos\learning-kubernetes\vagrant\linux"        
        $vagrantHome = "D:\Cloud\Vagrant\.vagrant.d"      
        $virtualboxFolder = "C:\Program Files\Oracle\VirtualBox"
        $virtualboxVMFolder = "D:\Cloud\VirtualBox"
        $vmwareVMFolder = "D:\Cloud\VMware"
    }
    Default { Write-Host "This hostname is not available for execution this script!!!"; exit 1 }
}

# Set workdir
Set-Location $baseVagrantfile

# VirtualBox home directory.
Start-Process -Wait -NoNewWindow -FilePath "$virtualboxFolder\VBoxManage.exe" `
    -ArgumentList  @("setproperty", "machinefolder", "$virtualboxVMFolder")

# Vagrant home directory for downloadad boxes.
setx VAGRANT_HOME $vagrantHome >$null

# Destroy lab stack
Start-Process -Wait -WindowStyle Hidden  -FilePath $vagrant -ArgumentList "destroy -f"  -Verb RunAs

# VM name
$vmName= @(
    "infra-server01",
    "load-balance",
    "control-plane01",
    "control-plane02",
    "control-plane03",
    "worker01",
    "worker02",
    "worker03",
    "managment"
)
# Folder vagrant virtualbox machines artefacts
$vmFolders = @(    
    $vmName | ForEach-Object{
        "$virtualboxVMFolder\$($_)"
    }
)

# Folder vagrant vmware machines artefacts
$vmwareFolders = @(    
    $vmName | ForEach-Object{
        "$vmwareVMFolder\$($_)"
    }
)

# Folder vagrant virtualbox machines artefacts
$vmStorageFolders = @(    
    $vmName | ForEach-Object{
        "$virtualboxVMFolder\Storage\$($_)"
    }    
)

# Folder vagrant vmware machines artefacts
$vmwareStorageFolders = @(    
    $vmName | ForEach-Object{
        "$vmwareVMFolder\Storage\$($_)"
    }    
)

# Delete folder virtualbox machines artefacts
$vmFolders | ForEach-Object {
    If (Test-Path $_) {                
        Remove-Item $_ -Recurse -Force                
    }
}

# Delete folder vmware machines artefacts
$vmwareFolders | ForEach-Object {
    If (Test-Path $_) {        
        Remove-Item $_ -Recurse -Force
    }            
}

# Delete folder virtualbox machines storage
$vmStorageFolders | ForEach-Object {
    If (Test-Path $_) {        
        Remove-Item $_ -Recurse -Force                
    }
}

# Delete folder vmware machines storage
$vmwareStorageFolders | ForEach-Object {
    If (Test-Path $_) {        
        Remove-Item $_ -Recurse -Force                
    }
}