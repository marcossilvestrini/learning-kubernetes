<#
.Synopsis
   Up lab for learning
.DESCRIPTION 
   Set Vagrantfile for kubernetes server
   Set folder of virtualbox VM's
   Create a semafore for vagrant up
   Copy public key for vagrant shared folder
   This script is used for create a new lab with vagrant.
   Create all VM's in Vagrantfile  
   Copy all private key of VM's for F:\Projetos\vagrant_pk folder   
.EXAMPLE
   & vagrant_up_windows.ps1
#>

#Execute script as Administrator
# if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
#    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
#    Start-Process -Wait powershell -Verb runAs -WindowStyle Minimized -ArgumentList $arguments
#    Break
# }

# Clear screen
Clear-Host

#Stop vagrant process
Get-Process -Name *vagrant* | Stop-Process -Force
Get-Process -Name *ruby* | Stop-Process -Force

# Semafore for vagrant process
$scriptPath = $PSScriptRoot
$semafore = "$scriptPath\vagrant-up.silvestrini"
New-Item -ItemType File -Path $semafore -Force >$null

# SSH
$ssh_path = "$( (($scriptPath | Split-Path -Parent)| Split-Path -Parent) | Split-Path -Parent)\security"
Copy-Item -Force "$env:USERPROFILE\.ssh\id_ecdsa.pub" -Destination $ssh_path

# Define environment for labs(notebook, desktop)
switch ($(hostname)) {
   "silvestrini" {
      # Variables
      $virtualboxFolder = "E:\Apps\VirtualBox"
      $virtualboxVMFolder = "E:\Servers\VirtualBox"       
      $vagrant = "E:\Apps\Vagrant\bin\vagrant.exe"
      $vagrantHome = "E:\Apps\Vagrant\vagrant.d"  
      $baseProject = "F:\Projetos\learning-kubernetes"          
      $baseVagrantfile = "$baseProject\vagrant\linux"                  
      $vagrantPK = "F:\Projetos\vagrant-pk"      
   }
   "silvestrini2" {      
      # Variables
      $virtualboxFolder = "C:\Program Files\Oracle\VirtualBox"
      $virtualboxVMFolder = "D:\Cloud\VirtualBox"          
      $vagrant = "D:\Cloud\Vagrant\bin\vagrant.exe"
      $vagrantHome = "D:\Cloud\Vagrant\.vagrant.d"             
      $baseProject = "F:\Projetos\learning-kubernetes"                
      $baseVagrantfile = "$baseProject\vagrant\linux"         
      $vagrantPK = "F:\Projetos\vagrant-pk"      
      
   }
   Default { Write-Host "This hostname is not available for execution this script!!!"; exit 1 }
}

# VirtualBox home directory.
Start-Process -Wait -NoNewWindow -FilePath "$virtualboxFolder\VBoxManage.exe" `
   -ArgumentList  @("setproperty", "machinefolder", "$virtualboxVMFolder")

# Vagrant home directory for downloadad boxes.
setx VAGRANT_HOME "$vagrantHome" >$null

# Copy app files
Copy-Item -Force "$baseProject\index.html" -Destination "$baseProject\apps\app-silvestrini"
Copy-Item -Force -Recurse "$baseProject\images" -Destination "$baseProject\apps\app-silvestrini"

# Fix linux scripts


# Up kubernetes stack
$kubernetes = "$baseVagrantfile"
Set-Location $kubernetes
vagrant up --provision
Copy-Item .\.vagrant\machines\infra-server01\virtualbox\private_key $vagrantPK\infra-server01
Copy-Item .\.vagrant\machines\load-balance\virtualbox\private_key $vagrantPK\load-balance
Copy-Item .\.vagrant\machines\managment\virtualbox\private_key $vagrantPK\managment
Copy-Item .\.vagrant\machines\control-plane01\virtualbox\private_key $vagrantPK\control-plane01
Copy-Item .\.vagrant\machines\control-plane02\virtualbox\private_key $vagrantPK\control-plane02
Copy-Item .\.vagrant\machines\control-plane03\virtualbox\private_key $vagrantPK\control-plane03
Copy-Item .\.vagrant\machines\worker01\virtualbox\private_key $vagrantPK\worker01
Copy-Item .\.vagrant\machines\worker02\virtualbox\private_key $vagrantPK\worker02
Copy-Item .\.vagrant\machines\worker03\virtualbox\private_key $vagrantPK\worker03

# Deployment kubernetes applications
#vagrant ssh control-plane01  -c 'sudo ./scripts/k8s/deployments.sh'

# Copy kubeconfig to G:\
Copy-Item -Force  "$baseProject\configs\linux\kubeconfig\rancher-skynet-local.yaml" "G:\Projetos\learning-kubernetes\configs\linux\kubeconfig\rancher-skynet-local.yaml"

# Copy security to G:\
Copy-Item -Force  "$baseProject\security\*" "G:\Projetos\learning-kubernetes\security"


# Fix powershell error
$Env:VAGRANT_PREFER_SYSTEM_BIN += 0

#Remove Semafore
Remove-Item -Force $semafore

