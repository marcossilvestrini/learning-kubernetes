<#
.Synopsis
   Up lab for learning kubernetes
.DESCRIPTION 
   Set vagrant provider for machines
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
Get-Process -Name vagrant -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name *ruby* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# # Restart vmware utility
# net.exe stop vagrant-vmware-utility 
# Start-Sleep 2
# net.exe start vagrant-vmware-utility 

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
      $vagrantHome = "E:\Apps\Vagrant\vagrant.d"  
      $baseProject = "F:\Projetos\learning-kubernetes"          
      $baseVagrantfile = "$baseProject\vagrant\linux"                  
      $vagrantPK = "F:\Projetos\vagrant-pk"      
   }
   "silvestrini2" {      
      # Variables
      $virtualboxFolder = "C:\Program Files\Oracle\VirtualBox"
      $virtualboxVMFolder = "D:\Cloud\VirtualBox"                
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

# Select provider
$menu=@"
|------------------------------------------------|
|Providers for Provisioning Kubernetes Cluster   |
|------------------------------------------------|
|1 - VMWare
|2 - Virtualbox
|------------------------------------------------|
"@
$menu
$option=Read-Host "Switch Provider"
switch ($option) {
   1 {
      Write-Host "Provider: VMWare OS: Rocky9"
      $provider="vmware_desktop"
      Copy-Item -Path "$baseVagrantfile\Vagrantfile_vmware" -Destination "$baseVagrantfile\Vagrantfile"
   }
   2 {
      Write-Host "Provider: Virtualbox OS: ol9"
      $provider="virtualbox"
      Copy-Item -Path "$baseVagrantfile\Vagrantfile_virtualbox" -Destination "$baseVagrantfile\Vagrantfile"
   }
   Default {Write-Host "Provider not found";exit 1}
}

# Set workdir
Set-Location $baseVagrantfile

# Clear old files
If(Test-Path "$baseVagrantfile\.vagrant"){Remove-Item -Recurse -Force "$baseVagrantfile\.vagrant"}

# Up kubernetes stack
vagrant up


Copy-Item .\.vagrant\machines\infra-server01\$provider\private_key $vagrantPK\infra-server01
Copy-Item .\.vagrant\machines\load-balance\$provider\private_key $vagrantPK\load-balance
Copy-Item .\.vagrant\machines\managment\$provider\private_key $vagrantPK\managment
Copy-Item .\.vagrant\machines\control-plane01\$provider\private_key $vagrantPK\control-plane01
Copy-Item .\.vagrant\machines\control-plane02\$provider\private_key $vagrantPK\control-plane02
Copy-Item .\.vagrant\machines\control-plane03\$provider\private_key $vagrantPK\control-plane03
Copy-Item .\.vagrant\machines\worker01\$provider\private_key $vagrantPK\worker01
Copy-Item .\.vagrant\machines\worker02\$provider\private_key $vagrantPK\worker02
Copy-Item .\.vagrant\machines\worker03\$provider\private_key $vagrantPK\worker03


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
