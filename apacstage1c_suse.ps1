#How to execute this script .\apacstage1c_suse.ps1 "vCentrename" and a pop-up will apper then enter "Username@apac.corpdir.net" "password"
#populate apacstage1c_suse_input.CSV file with all the details before execution.  
#variables

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

$vcenter= "saai1m111001.inedc.corpintra.net"
$creden = Get-Credential -Message "Enter your Vcenter credentials"

$currentDate = Get-Date -Format "dd-MMM-yyyy"
$LogPath = "$ScriptDir\STAGE1"
$log = "$LogPath\apacstage1c_$currentDate.html"


If(!(test-path $LogPath))
{
      New-Item -ItemType Directory -Force -Path $LogPath
}


ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  Connecting to vcenter  ---------------------------------------------</b> " | Out-File $log -Append

########################..........................Connect to vCenter...............................######################
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$connect=Connect-VIserver -Server $vcenter -credential $creden

if ($connect -imatch $vcenter)
{
#Connect-VIServer -Server $vcenter -User "$vname" -Password "$vpass" -Verbose
#Connect-VIserver -Server $vcenter -credential $creden

ConvertTo-Html -Body "<br><font color=green> $(Get-Date):Connected to VCenter $vcenter </font>" | Out-File $log -Append
write-host "Connected to VCenter $vcenter Successfully" -ForegroundColor Green

Foreach($Line in (Import-Csv ".\apacstage1c_suse_input.csv")){
$vm=$Line.VM
$server = Get-VM -Name $vm

if($server -imatch $vm)
{
#$SuccessCSV = @()

$spec = New-Object VMware.Vim.VirtualMachineConfigSpec #to validate Hot-add

$Root_user= $Line.User
$Root_Password=$line.Password
$vm=$Line.VM
$ip = $Line.IP
$fqdn = $Line.FQDN
$route = $ip.Split(".")[0]+"."+$ip.Split(".")[1]+"."+$ip.Split(".")[2]+".1"

#$OldGateway=$old_ipaddress.Split(".")[0]+"."+$old_ipaddress.Split(".")[1]+"."+$old_ipaddress.Split(".")[2]+".1"
#$ip=(Get-VM $vm | Get-View).Guest.IpAddress

$secure_password=ConvertTo-SecureString "$Root_Password" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential($Root_user,$secure_password)



ConvertTo-Html -Body "<br><br><b>$(Get-Date)<font color=blue>--------------------------------------------- STAGE1 PROCESS FOR $vm STARTED  ---------------------------------------------</font></b>" | Out-File $log -Append

$state = Get-VMGUEST -VM $vm | Select-Object -ExpandProperty state 
if ($state -ne "Running"){

ConvertTo-Html -Body "<br><br><b>$(Get-Date).....................................POWER ON SERVER FOR $vm.........................................</b> " | Out-File $log -Append
Write-Host "Power ON server" -ForegroundColor Green

$newvm = Get-VM -name $vm
Start-VM -VM $newvm -Confirm:$False
    
Start-Sleep -s 120
ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> $newvm is powered on</font>"| out-file $log -Append
write-host "VM is powered on"
}


$state = Get-VMGUEST -VM $vm | Select-Object -ExpandProperty state
if ($state -eq "Running"){
ConvertTo-Html -Body "<br><br><b>$(Get-Date)<font color=green>.....................................SERVER $vm RUNNING.........................................</b> " | Out-File $log -Append
ConvertTo-Html -Body "<br><br><b>$(Get-Date)...................................VALIDATE IF HOT ADD ENABLED FOR $vm..............................................</b>" | Out-File $log -Append
Write-Host "Validate if Hot-Add Enabled" -ForegroundColor Green


if($newvm.ExtensionData.Config.cpuHotAddEnabled -or $newvm.ExtensionData.Config.memoryHotAddEnabled)
{
    $newvm.ExtensionData.ReconfigVM($spec)
    Add-Content -Path .\Out_HotAdd.txt -Value "$vm Hot_Add_enabled" -PassThru
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Hot_Add_enabled Sucessfully</font>"| Out-File $log -Append
    Write-Host "Hot_Add enabled Sucessfully" -ForegroundColor Green
}
else
{
    Add-Content -Path .\Out_HotAdd.txt -Value "$vm Hot_Add_already_enabled" -PassThru
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Hot_Add_already_enabled</font>"| Out-File $log -Append
    Write-Host "Hot_Add already enabled" -ForegroundColor Green
}


ConvertTo-Html -Body "<br><br><b>$(Get-Date)......................................HOSTNAME CHANGE FOR $vm..........................................</b>" | Out-File $log -Append
write-host "VALIDATING HOSTNAME for $vm" -ForegroundColor green

$hostfilename = "cat /etc/hostname"
$Invokehostfilename =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $hostfilename -Verbose -GuestCredential $cred

if ($Invokehostfilename.scriptoutput -imatch "$vm" -or $Invokehostfilename.scriptoutput -imatch "$fqdn")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> hostname already updated for $vm</font>"| Out-File $log -Append
    write-host "Server hostname already updated" -ForegroundColor Green
}

else
{
$hostname = @"
sudo hostnamectl set-hostname $vm
"@
$Invokehostnamechange =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $hostname -Verbose -GuestCredential $cred

if($Invokehostnamechange.ExitCode.Equals(0))
{
  ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> hostname changed to $vm</font>"| Out-File $log -Append
  write-host "hostname changed sucessfully"
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> failed to change Hostname </font>"| Out-File $log -Append
    write-Host "failed to change hostname" 
}
}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)......................................HOSTS FILE MODIFICATION FOR $vm..........................................</b>" | Out-File $log -Append

Write-Host "Validating hosts file..." -ForegroundColor Green

$hostfile = "cat /etc/hosts | grep -i $ip"
$Invokehostfile =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $hostfile -Verbose -GuestCredential $cred

if ($Invokehostfile.scriptoutput -imatch "$ip" -or $Invokehostfile.scriptoutput -imatch "$fqdn")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> hosts file already updated to $vm</font>"| Out-File $log -Append
    write-host "/etc/hosts file already updated" -ForegroundColor Green
}

else
{
$host1 = @"
sudo echo "$ip  $fqdn  $vm" >> /etc/hosts
"@
$Invokehosts =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $host1 -Verbose -GuestCredential $cred

if($Invokehosts.ExitCode.Equals(0))
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> $ip $fqdn $vm added in /etc/hosts file </font>"| out-file $log -Append
    write-host "/etc/hosts file updated"
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to update /etc/hosts file</font>"| out-file $log -Append
    write-Host "failed to update /etc/hosts files"
}
}


ConvertTo-Html -Body "<br><br><b>$(Get-Date).................................IP-ADDRESS CHANGE FOR $vm...........................................</b> " | Out-File $log -Append
Write-Host "Validating IP Address for $vm" -ForegroundColor Green

$ipfilename = "cat /etc/sysconfig/network/ifcfg-eth0 | grep -i $ip"
$Invokeipfilename =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $ipfilename -Verbose -GuestCredential $cred

if ($Invokeipfilename.scriptoutput -imatch "$ip" -or $Invokeipfilename.scriptoutput -imatch "$route")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> IP address $ip already updated for $vm</font>"| Out-File $log -Append
    write-host "Server IP address $ip already updated" -ForegroundColor Green
}

else
{
$cmd3 = @"
sudo cat /dev/null > /etc/sysconfig/network/ifcfg-eth0
sudo echo "DEVICE=eth0" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "USERCONTROL=no" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "BOOTPROTO=static" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "STARTMODE=auto" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "IPADDR=$ip/24" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "PREFIXLEN=24" >> /etc/sysconfig/network/ifcfg-eth0
sudo echo "SERVER_LINK_READY=10" >> /etc/sysconfig/network/ifcfg-eth0
"@
$Invokecmd3 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $cmd3 -Verbose -GuestCredential $cred

if($Invokecmd3.ExitCode.Equals(0))
{
 ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>IP ADDRESS $ip updated Sucessfully </font>"| out-file $log -Append
 write-host "IP ADRESS $ip MODIFIED SUCCESSFULLY" -foreground green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> IP Address Failed to update  </font>"| out-file $log -Append
    write-Host "Failed to update ip address"  -foreground red
}
}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)...............................GATEWAY MODIFICATION FOR $vm..........................................</b> " | Out-File $log -Append
Write-Host "Validating Route Gateway started" -ForegroundColor Green
Write-Host "New gateway is $route" -ForegroundColor Green

$routefilename = "cat /etc/sysconfig/network/routes"
$Invokeroutefilename =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $routefilename -Verbose -GuestCredential $cred

if ($Invokeroutefilename.scriptoutput -imatch "$route" -or $Invokeroutefilename.scriptoutput -imatch "$ip")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> ROUTE'S $route already updated for $vm</font>"| Out-File $log -Append
    write-host "Server Route's $route already updated" -ForegroundColor Green
}

else
{
$routes = @"
sudo cat /dev/null > /etc/sysconfig/network/routes
sudo echo "default $route - -" >> /etc/sysconfig/network/routes
"@
$Invokenewgateway1 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $routes -Verbose -GuestCredential $cred

if($Invokenewgateway1.ExitCode.Equals(0))
{
 ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>ROUTES $route MODIFIED SUCESSFULLY FOR $vm </font>"| out-file $log -Append
 write-host "Gateway MODIFIED SUCCESSFULLY" -foreground green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to update Gateway  </font>"| out-file $log -Append
    write-Host "Failed to update Gateway"  -foreground red
}
}

############################################################################
ConvertTo-Html -Body "<br><br><b>$(Get-Date)..........................DNS ENTRIES FOR $vm...............................</b> " | Out-File $log -Append
Write-Host "Validating DNS Entries file for $vm" -ForegroundColor Green

$dnsfile1 = "sudo cat /etc/resolv.conf"
$Invokednsfile1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $dnsfile1 -Verbose -GuestCredential $cred

$dnsfile2 = "sudo cat /etc/sysconfig/network/config |grep DNS_STATIC"
$Invokednsfile2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $dnsfile2 -Verbose -GuestCredential $cred

if ($Invokednsfile1.scriptoutput -imatch "53.150.6.254" -or $Invokednsfile1.scriptoutput -imatch "53.150.9.254")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> DNS Entries already updated to $vm</font>"| Out-File $log -Append
    write-host "DNS Entries already updated" -ForegroundColor Green
}
elseif ($Invokednsfile2.scriptoutput -imatch "53.150.6.254" -or $Invokednsfile2.scriptoutput -imatch "53.150.9.254" -or $Invokednsfile2.scriptoutput -imatch "corpintra.net")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> DNS Entries already updated to $vm</font>"| Out-File $log -Append
    write-host "DNS Entries already updated" -ForegroundColor Green
}

else
{
$dns1 = @"
sudo sed -i 's/NETCONFIG_DNS_POLICY="auto"/NETCONFIG_DNS_POLICY="STATIC *"/' /etc/sysconfig/network/config
sudo sed -i 's/NETCONFIG_DNS_STATIC_SEARCHLIST=""/NETCONFIG_DNS_STATIC_SEARCHLIST="inedc.corpintra.net"/' /etc/sysconfig/network/config
sudo sed -i 's/NETCONFIG_DNS_STATIC_SERVERS=""/NETCONFIG_DNS_STATIC_SERVERS="53.150.6.254 53.150.9.254"/' /etc/sysconfig/network/config
"@
$Invokednsfile3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $dns1 -Verbose -GuestCredential $cred

if($Invokednsfile3.ExitCode.Equals(0))
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> DNS Entries added Sucessfully </font>"| out-file $log -Append
    write-host "/etc/hosts file updated"
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> DNS Entries Failed to Update</font>"| out-file $log -Append
    write-Host "failed to update /etc/hosts files"
}
}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)..........................NTP ENTRIES FOR $vm...............................</b> " | Out-File $log -Append

write-host "Validating NTP/Chrony For $vm"  -foreground green
$awk = "sudo hostnamectl | grep sles | awk '{print "+'$' + "3,"+'$'+ "4}'"
$Invokeawk = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $awk  -Verbose -GuestCredential $cred

if ($Invokeawk.scriptoutput -imatch "sles:12")
{

$ntpfile1 = "cat /etc/ntp.conf |grep server"
$Invokentpfile1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $ntpfile1 -Verbose -GuestCredential $cred

if ($Invokentpfile1.scriptoutput -imatch "53.150.6.254" -or $Invokentpfile1.scriptoutput -imatch "53.150.9.254")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> NTP Entries already updated for $vm</font>"| Out-File $log -Append
    write-host "NTP Entries already updated" -ForegroundColor Green
}
else
{
$ntp2 = @"
sudo echo "server 53.150.6.254 prefer" >> /etc/ntp.conf
sudo echo "server 53.150.9.254" >> /etc/ntp.conf
sudo systemctl enable ntpd.service
"@
$Invokentpfile2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $ntp2 -Verbose -GuestCredential $cred

$ntp3 = @"
sudo systemctl start ntpd.service
"@
$Invokentpfile3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $ntp3 -Verbose -GuestCredential $cred

if($Invokentpfile3.ExitCode.Equals(0))
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> NTP Entries added Sucessfully For $vm</font>"| out-file $log -Append
    write-host "NTP Entries added Sucessfully For $vm" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> NTP Entries Failed to Update For $vm</font>"| out-file $log -Append
    write-Host "failed to update NTP Entries For $vm" -ForegroundColor Green
}
}
}
elseif ($Invokeawk.scriptoutput -imatch "sles:15")
{
$chronyfile1 = "cat /etc/chrony.conf |grep server"
$Invokechronyfile1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $chronyfile1 -Verbose -GuestCredential $cred

if ($Invokechronyfile1.scriptoutput -imatch "53.150.6.254" -or $Invokechronyfile1.scriptoutput -imatch "53.150.9.254")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Chrony Entries already updated for $vm</font>"| Out-File $log -Append
    write-host "Chrony Entries already updated" -ForegroundColor Green
}
else
{
$chrony2 = @"
sudo echo "server 53.150.6.254 prefer" >> /etc/chrony.conf
sudo echo "server 53.150.9.254" >> /etc/chrony.conf
sudo systemctl stop ntpd.service
sudo systemctl disable ntpd.service
sudo systemctl enable chronyd.service
"@
$Invokechronyfile2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $chrony2 -Verbose -GuestCredential $cred

$chrony3 = @"
sudo systemctl start chronyd.service
"@
$Invokechronyfile3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $chrony3 -Verbose -GuestCredential $cred

if($Invokechronyfile3.ExitCode.Equals(0))
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Chrony Entries added Sucessfully For $vm</font>"| out-file $log -Append
    write-host "Chrony Entries added Sucessfully For $vm" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Chrony Entries Failed to Update For $vm</font>"| out-file $log -Append
    write-Host "Chrony Entries Failed to Update For $vm" -ForegroundColor Green
}
}
}
else
{
write-host "Neither sles12 nor sles15" -foreground red
}

#################################################################################

ConvertTo-Html -Body "<br><br><b>$(Get-Date)..........................NETWORK RESTART FOR $vm...............................</b> " | Out-File $log -Append
write-host "Network Restart Started" -ForegroundColor Green

write-host "RESTARTING NETWORK" -foregroundcolor Green
$restart = @"
sudo systemctl restart network
sudo systemctl status network
"@
$Invokerestart = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $restart -Verbose -GuestCredential $cred


if($Invokerestart.ExitCode.Equals(0))
{
 ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Systemctl Restarted Network successfully for: $vm  </font>"| out-file $log -Append
 write-host "NETWORK RESTARTED SUCESSFULLY" -foreground green
}
else
{
    write-host "FAILED TO NETWORK RESTARTED " -foreground green
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> failed to restart: $vm  </font>"| out-file $log -Append
}



ConvertTo-Html -Body "<br><br><b>$(Get-Date)..........................RESTART THE SSH SERVICE FOR $vm...............................</b> " | Out-File $log -Append
Write-Host "SSH service Started" -ForegroundColor Green

$restartvm2="sudo systemctl restart sshd.service"
$restartvm3="sudo systemctl status sshd.service"

$Invokerestart2 = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $restartvm2 -Verbose -GuestCredential $cred
$Invokerestart3 = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $restartvm3 -Verbose -GuestCredential $cred

if($Invokerestart2.ExitCode.Equals(0))
{
 ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Systemctl Restarted the ssh service successfully</font>"| out-file $log -Append
 write-host "Systemctl Restarted the ssh service successfully "
}
else
{
    write-Host "failed to restart ssh service" -foregroundcolor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> failed to restart ssh service </font>"| out-file $log -Append
}
#####################################################

####################################################
}
}

else
{
    write-host "The $vm is not present in vcenter provided" -foregroundcolor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> the $vm is not present in vcenter $vcenter provided"| out-file $log -Append
}
}

}
else
{
    write-host "Cannot connect to vcenter due to wrong credentials" -foregroundcolor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Cannot connect to vcenter due to wrong credentials $vcenter"| out-file $log -Append
}