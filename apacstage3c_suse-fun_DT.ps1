#How to execute this script .\apacstage3c_suse.ps1 "vCentrename" "Username@emea.corpdir.net" "password"
#populate apacstage3c_suse_input.csv file with all the details before execution.  
#variables

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

$vcenter= "saai1m111001.inedc.corpintra.net"  #$args[0]
$creden = Get-Credential -Message "Enter your Vcenter credentials"

$currentDate = Get-Date -Format "dd-MMM-yyyy"
$LogPath = "$ScriptDir\STAGE3"
$log = "$LogPath\apacstage3c_$currentDate.html"


If(!(test-path $LogPath))
{
      New-Item -ItemType Directory -Force -Path $LogPath
}

Function Connect() {
ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  Connect to vcenter  ---------------------------------------------</b> " | Out-File $log -Append

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$connect=Connect-VIserver -Server $vcenter -credential $creden

if ($connect -imatch $vcenter)
{

ConvertTo-Html -Body "<br><font color=green> $(Get-Date):Connected to VCenter $vcenter </font>" | Out-File $log -Append
write-host "Connected to VCenter $vcenter Successfully" -ForegroundColor Green

}
else
{

    write-host "Cannot connect to vcenter due to wrong credentials" -foregroundcolor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Cannot connect to vcenter due to wrong credentials $vcenter"| out-file $log -Append
    exit

}
}


Function FMO_APAC() {
Foreach($Line in (Import-Csv ".\apacstage3c_suse_input.csv"))
{

$vm=$Line.VM
$server = Get-VM -Name $vm

if($server -imatch $vm)
{
#$SuccessCSV = @()

$spec = New-Object VMware.Vim.VirtualMachineConfigSpec #to validate Hot-add

$Root_user= $Line.User
$Root_Password=$line.Password
$vm=$Line.VM

#Pass throught credential of local admin to secure string
$secure_password=ConvertTo-SecureString "$Root_Password" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential($Root_user,$secure_password)

$ip=(Get-VM $vm | Get-View).Guest.IpAddress



ConvertTo-Html -Body "<br><br><b>$(Get-Date)<font color=blue>--------------------------------------------- Stage 3 Process for $vm Started  ---------------------------------------------</font></b>" | Out-File $log -Append
#################################
Function Crowdstrike()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing  Crowdstrike Package on $vm ---------------------------------------------</b>" | Out-File $log -Append

$port1 ="sudo nc -zv 53.244.194.32 3128"
$Invokport1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port1  -Verbose -GuestCredential $cred

if($Invokport1.scriptoutput -imatch  "succeeded")
{
        write-Host "CrowdStrike Ports Connection Succeeded" -ForegroundColor Green
        ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>CrowdStrike Ports Connection Succeeded</font>"| Out-File $log -Append

## Validating Crowdstrike installation ## 

$crowd = "sudo rpm -qa |grep falcon-sensor"
$Invokecrowd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $crowd  -Verbose -GuestCredential $cred

$invokecrowds=$Invokecrowd.Split()[0]

if($Invokecrowd.scriptoutput -imatch 'falcon-sensor')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> CrowdStrike Package Installed already on $vm </font>"| out-file $log -Append
    write-host "CrowdStrike Installed/Running already on $vm" -ForegroundColor red

$rmcrowd = "sudo zypper remove -y $invokecrowds"
$Invokermcrowd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmcrowd  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled CrowdStrike Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled CrowdStrike Package Successfully on $vm" -ForegroundColor green

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> CrowdStrike Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "CrowdStrike Package Not Installed on $vm" -ForegroundColor green

}

write-host "Installing Crowdstrike Package on $vm.." -ForegroundColor Green

$awk ="sudo hostnamectl | grep sles | awk '{print "+'$' + "3,"+'$'+ "4}'"
$InvokeS2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $awk  -Verbose -GuestCredential $cred

if($InvokeS2.scriptoutput -imatch "sles:12")
{

$chkcrowd1 =@"
sudo ls /opt/repositories/falcon-sensor* |grep suse12
"@
$Invokechkcrowd1 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $chkcrowd1 -Verbose -GuestCredential $cred
#$packagecrowd1 =$Invokechkcrowd1.Split("|")

$installfalcon1= "sudo rpm -ivh $Invokechkcrowd1"
$Invokefalcon1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $installfalcon1 -Verbose -GuestCredential $cred

}
else
{

$chkcrowd2 =@"
sudo ls /opt/repositories/falcon-sensor* |grep suse15
"@
$Invokechkcrowd2 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $chkcrowd2 -Verbose -GuestCredential $cred
#$packagecrowd2 =$Invokechkcrowd2.Split("|")

$installfalcon2 ="sudo rpm -ivh $Invokechkcrowd2"
$Invokefalcon2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $installfalcon2 -Verbose -GuestCredential $cred
}


$installfalcon3="sudo rpm -qa | grep -i falcon-sensor"
$Invokefalcon3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $installfalcon3 -Verbose -GuestCredential $cred


if($Invokefalcon3.scriptoutput -imatch 'falcon-sensor')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Crowdstrike Package installed Successfully </font>"| Out-File $log -Append
    write-host "Crowdstrike installed Successfully" -ForegroundColor Green

write-host "Crowdstrike configuration started...on $vm" -ForegroundColor Green

$CS_cmd1 =@" 
sudo /opt/CrowdStrike/falconctl -s -f --cid=739E95B1C0EC4AF18DD5F48BCE994EE6-46
sudo /opt/CrowdStrike/falconctl -s --aph=sgscaiu0388.inedc.corpintra.net --app=3128
sudo /opt/CrowdStrike/falconctl -g --aph --app
sudo /opt/CrowdStrike/falconctl -s --apd=FALSE
sudo /opt/CrowdStrike/falconctl -s -f --tags="APAC,128"
"@
$InvokeCScmd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $CS_cmd1  -Verbose -GuestCredential $cred

$CS_cmd2 =@" 
rpm -qa falcon-sensor
sudo /opt/CrowdStrike/falconctl -g --tag
sudo /opt/CrowdStrike/falconctl -g --cid
sudo /opt/CrowdStrike/falconctl -g --aph --app
"@
$InvokeCScmd2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $CS_cmd2  -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=black> $InvokeCScmd2</font>"| Out-File $log -Append
write-host "CrowdStrike Configuration Status" -ForegroundColor Green
write-host "$InvokeCScmd2" -ForegroundColor Green

$CS_cmd3 = @" 
sudo systemctl enable falcon-sensor.service
sudo systemctl start falcon-sensor.service
"@
$InvokeCScmd3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $CS_cmd3  -Verbose -GuestCredential $cred


$CS_cmd4 =@"
sudo systemctl status falcon-sensor.service
"@
$Invokestat = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $CS_cmd4  -Verbose -GuestCredential $cred


if($Invokestat -imatch 'running' )
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Crowdstrike Service is running </font>"| Out-File $log -Append
    write-host "Crowdstrike Service is running" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Crowdstrike Status is inactive </font>"| Out-File $log -Append
    write-host "Crowdstrike Status is inactive" -ForegroundColor red
}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Crowdstrike Package on $vm </font>"| Out-File $log -Append
    write-host "Failed to install Crowdstrike Package on $vm" -ForegroundColor red
}
}
else
{
    write-Host "CrowdStrike Ports Connection Failed" -ForegroundColor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red>CrowdStrike Ports Connection Failed</font>"| Out-File $log -Append   
}
}

#######################################
Function Splunk()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing Splunk Package on $vm ---------------------------------------------</b>" | Out-File $log -Append

$port1 ="sudo nc -zv 53.137.129.247 8089"
$Invokport1=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port1  -Verbose -GuestCredential $cred

if($Invokport1.scriptoutput -imatch  "succeeded")
{
        write-Host "Splunk Ports Connection Succeeded" -ForegroundColor Green
        ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Splunk Ports Connection Succeeded</font>"| Out-File $log -Append


## Validating SPlunk installation ## 

$splunk1 ="sudo rpm -qa |grep salm-agent"
$Invokesplunk1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk1  -Verbose -GuestCredential $cred

$invokesplunks =$Invokesplunk1.Split()[0]

if($Invokesplunk1.scriptoutput -imatch 'salm-agent')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Splunk Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Splunk Installed/Running already on $vm" -ForegroundColor red

$rmcrowd = "sudo zypper remove -y $invokesplunks"
$Invokermcrowd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmcrowd  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Splunk Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Splunk Package Successfully on $vm" -ForegroundColor green

}
else
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Splunk Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "Splunk Package Not Installed on $vm" -ForegroundColor green

}

write-host "Installing Splunk Package on $vm.." -ForegroundColor Green

$installsplunk="sudo rpm -ivh /opt/repositories/apac-salm-agent-9.0.1-2.x86_64.rpm"
$Invokesplunk=Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $installsplunk -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Splunk Package installed Successfully</font>" | Out-File $log -Append
write-host "Splunk installed Successfully" -foreground green

$splunk1 ="sudo rpm -qa | grep -i salm-agent"
$Installsplunk1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk1 -Verbose -GuestCredential $cred

if($Installsplunk1 -imatch 'salm-agent')
{

write-host "Splunk configuration started...on $vm" -ForegroundColor Green

$splunk_cmd1 = @" 
sudo /opt/standards/splunkforwarder/bin/splunk set deploy-poll 53.137.129.247:8089
sudo /opt/standards/splunkforwarder/bin/splunk restart
sudo /opt/standards/splunkforwarder/bin/splunk status
"@
$Invokespcmd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk_cmd1  -Verbose -GuestCredential $cred

$splunk_cmd2=@"
sudo /opt/standards/splunkforwarder/bin/splunk stop
sudo touch /var/tmp/splunk1.sh
sudo chmod 777 /var/tmp/splunk1.sh
sudo echo "#!/bin/bash" > /var/tmp/splunk1.sh
sudo echo "sudo -i" >> /var/tmp/splunk1.sh
sudo echo "touch /opt/standards/splunkforwarder/etc/apps/zz_tss_lw_uf_global_deployment_server/default/deploymentclient.conf" >> /var/tmp/splunk1.sh
sudo echo "echo "[target-broker:deploymentServer]" > /opt/standards/splunkforwarder/etc/apps/zz_tss_lw_uf_global_deployment_server/default/deploymentclient.conf" >> /var/tmp/splunk1.sh
sudo echo "echo "targetUri = splunk-deploy-apac.app.corpintra.net:8089" >> /opt/standards/splunkforwarder/etc/apps/zz_tss_lw_uf_global_deployment_server/default/deploymentclient.conf" >> /var/tmp/splunk1.sh
sudo sed -i 's/\r$//' /var/tmp/splunk1.sh
sudo sh /var/tmp/splunk1.sh
"@
$Invokesplunkcont =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $splunk_cmd2 -Verbose -GuestCredential $cred

$splunk_cmd3 = "ls  /opt/standards/splunkforwarder/etc/system/local/"
$Invokesplunkcmd3 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $splunk_cmd3 -Verbose -GuestCredential $cred

if($Invokesplunkcmd3.scriptoutput -imatch 'server.conf')
{

$splunk_cmd4 = @" 
sudo rm -rf /opt/standards/splunkforwarder/etc/system/local/deploymentclient.conf
sudo sed -i '2s/.*/serverName = $vm/' /opt/standards/splunkforwarder/etc/system/local/server.conf
sudo /opt/standards/splunkforwarder/bin/splunk restart
sudo rm -rf /opt/standards/splunkforwarder/etc/instance.cfg
"@
$Invokesplunkcmd4 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $splunk_cmd4 -Verbose -GuestCredential $cred
}
else
{
   write-host "server.conf file is not present" -foreground red
}

$splunk_cmd5 = @" 
sudo /opt/standards/splunkforwarder/bin/splunk enable boot-start
sudo /opt/standards/splunkforwarder/bin/splunk restart
sudo /opt/standards/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
"@

$Invokesplunkcmd5 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $splunk_cmd5 -Verbose -GuestCredential $cred

$splunk_cmd6 = @"
sudo rm -rf /var/tmp/splunk1.sh
sudo /opt/standards/splunkforwarder/bin/splunk status
"@
$Invokespstat =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk_cmd6  -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=black> $Invokespstat</font>"| Out-File $log -Append
write-host "Splunk Configuration Status" -ForegroundColor Green
write-host "$Invokespstat" -ForegroundColor Green


if($Invokespstat.scriptoutput -imatch 'PID' )
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Splunk Status is running on $vm</font>"| Out-File $log -Append
    write-host "Splunk is running on $vm" -foreground green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Splunk Status is inactive on $vm</font>"| Out-File $log -Append
    write-host "Splunk is inactive on $vm" -foreground red

}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Splunk Package on $vm</font>"| Out-File $log -Append
    write-host "Failed to install Splunk Package on $vm" -foreground red
}
}
else
{
    write-Host "Splunk Ports Connection Failed" -ForegroundColor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red>Splunk Ports Connection Failed</font>"| Out-File $log -Append   

}
}

#######################################################################

Function Qualys()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing Qualys Package on $vm ---------------------------------------------</b>" | Out-File $log -Append

$port1 ="sudo nc -zv 53.244.194.32 3128"
$Invokport1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port1  -Verbose -GuestCredential $cred

$port2 ="sudo curl -x sgscaiu0388.inedc.corpintra.net:3128 https://qagpublic.qg1.apps.qualys.eu"
$Invokport2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port2  -Verbose -GuestCredential $cred

if($Invokport1.scriptoutput -imatch  "succeeded" -and $Invokport2.scriptoutput -imatch  "404")
{
    write-Host "Qualys Ports Connection Succeeded" -ForegroundColor Green
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Qualys Ports Connection Succeeded</font>"| Out-File $log -Append

## Validating Qualys installation ## 

$qual_cmd1 ="sudo rpm -qa |grep qualys-cloud-agent"
$Invokequalcmd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd1  -Verbose -GuestCredential $cred

$invokequalcmds =$Invokequalcmd.Split()[0]

if($Invokequalcmd.scriptoutput -imatch 'qualys-cloud-agent')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Qualys Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Qualys Installed/Running already on $vm" -ForegroundColor Green

$rmqualys ="sudo zypper remove -y $invokequalcmds"
$Invokermqualys =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmqualys  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Qualys Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Qualys Package Successfully on $vm" -ForegroundColor green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Qualys Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "Qualys Package Not Installed on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Installing Qualys Package on $vm.. </font>"| Out-File $log -Append
write-host "Installing Qualys Package on $vm.." -ForegroundColor Green

$qual_cmd2 ="sudo rpm -ivh /opt/repositories/QualysCloudAgent.rpm"
$Invokequals2=Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $qual_cmd2 -Verbose -GuestCredential $cred


$qual_cmd3 ="sudo rpm -qa | grep -i qualys-cloud-agent"
$Invokequals3= Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd3 -Verbose -GuestCredential $cred


if($Invokequals3.scriptoutput -imatch 'qualys-cloud-agent')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Qualys Package installed Successfully </font>"| Out-File $log -Append
    write-host "Qualys installed Successfully" -ForegroundColor Green


ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Qualys Configuration Started on $vm </font>"| Out-File $log -Append
write-host "Qualys configuration started...on $vm" -ForegroundColor Green

$qual_cmd4 = @" 
sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=914dec18-b2b5-4dca-a87c-39e44ce11f55 CustomerId=c5e240f7-adeb-e8d0-834c-a9d9c39b016d
"@
$Invokequals4=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd4  -Verbose -GuestCredential $cred

$qual_cmd5 = @" 
sudo touch /etc/sysconfig/qualys-cloud-agent
sudo echo "https_proxy=https://sgscaiu0388.inedc.corpintra.net:3128" > /etc/sysconfig/qualys-cloud-agent
sudo chmod 600 /etc/sysconfig/qualys-cloud-agent
"@
$Invokequals5 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd5  -Verbose -GuestCredential $cred


$qual_cmd6 =@"
sudo cp /opt/repositories/CloudCerts/Corp-Prj-Root-CA.cer /etc/pki/trust/anchors
sudo cp /opt/repositories/CloudCerts/Corp-Proxy01-G1.cer /etc/pki/trust/anchors
sudo cp /opt/repositories/CloudCerts/DigiCertGlobalRootCA.cer /etc/pki/trust/anchors
sudo cp /opt/repositories/CloudCerts/DigiCertTLSRSASHA2562020CA1-1.cer /etc/pki/trust/anchors
sudo cp /opt/repositories/CloudCerts/qagpublic.qg1.apps.qualys.eu.cer /etc/pki/trust/anchors
sudo cd /etc/pki/trust/anchors
sudo chmod 644 Corp-Prj-Root-CA.cer Corp-Proxy01-G1.cer DigiCertGlobalRootCA.cer DigiCertTLSRSASHA2562020CA1-1.cer qagpublic.qg1.apps.qualys.eu.cer
sudo update-ca-certificates
"@
$Invokequals6 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $qual_cmd6 -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Copied Qualys Certificates successfully </font>"| Out-File $log -Append
write-host "Copied Qualys Certificates successfully..." -ForegroundColor Green

$qual_cmd7 = @" 
sudo cat /etc/sysconfig/qualys-cloud-agent
sudo ls -l /etc/pki/trust/anchors
"@
$Invokequals7 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd7  -Verbose -GuestCredential $cred


ConvertTo-Html -Body "<br>$(Get-Date)<font color=black> $Invokequals7</font>"| Out-File $log -Append
write-host "Qualys Configuration Status" -ForegroundColor Green
write-host "$Invokequals7" -ForegroundColor Green


$qual_cmd8 = @" 
sudo systemctl restart qualys-cloud-agent.service
sudo systemctl status qualys-cloud-agent.service
"@
$Invokequals8 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd8  -Verbose -GuestCredential $cred


$qual_cmd9 = @"
sudo systemctl status qualys-cloud-agent.service
"@
$Invokequals9 = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qual_cmd9 -Verbose -GuestCredential $cred

if($Invokequals9.scriptoutput -imatch 'running' )
{
    ConvertTo-Html -Body "<br><font color=green> Qualys Status is running </font>"| Out-File $log -Append
    write-host "Qualys Status is running" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br><font color=red> Qualys Status is inactive </font>"| Out-File $log -Append
    write-host "Qualys Status is inactive" -ForegroundColor red
}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Qualys Package on $vm </font>"| Out-File $log -Append
    write-host "Failed to install Qualys Package on $vm" -ForegroundColor red
}
}
else
{
    write-Host "Qualys Ports Connection Failed" -ForegroundColor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red>Qualys Ports Connection Failed</font>"| Out-File $log -Append 
}
}

##########################################################

Function Salt()
{ 

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing Salt Minion Package on $vm ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Salt-minion installation started.." -ForegroundColor Green

$sport1 ="sudo nc -zv PGSXSG1SM00004.adc-apac.corpintra.net 4505"
$Invokesport1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $sport1  -Verbose -GuestCredential $cred

$sport2 ="sudo nc -zv PGSXSG1SM00004.adc-apac.corpintra.net 4506"
$Invokesport2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $sport2  -Verbose -GuestCredential $cred

if($Invokesport1.scriptoutput -imatch  "succeeded" -and $Invokesport2.scriptoutput -imatch  "succeeded")
{
    write-Host "Salt Ports Connection Succeeded" -ForegroundColor Green
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Salt Ports Connection Succeeded</font>"| Out-File $log -Append

## Validating Salt installation ## 

$salt_cmd1 ="sudo rpm -qa | grep -i salt"
$Invokesaltcmd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd1  -Verbose -GuestCredential $cred


if($Invokesaltcmd1.scriptoutput -imatch 'salt-minion')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Salt Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Salt Installed/Running already on $vm" -ForegroundColor red

$rmsalt = "sudo zypper remove -y salt-minion salt"
$Invokermsalt =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmsalt  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Splunk Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Splunk Package Successfully on $vm" -ForegroundColor green

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Salt Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "Salt Package Not Installed on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Installing Salt Package on $vm.. </font>"| Out-File $log -Append
write-host "Installing Salt Package on $vm.." -ForegroundColor Green

$salt_cmd2 ="sudo zypper install -y salt-minion salt"
$Invokesaltcmd2 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd2  -Verbose -GuestCredential $cred


$salt_cmd3 ="sudo rpm -qa | grep -i salt"
$Invokesaltcmd3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd3  -Verbose -GuestCredential $cred

if($Invokesaltcmd3 -imatch "salt-minion")
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Salt Minion installed Successfully</font>"| Out-File $log -Append
    write-host "Salt Minion installed Successfully" -ForegroundColor Green

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Salt Configuration Started on $vm </font>"| Out-File $log -Append
write-host "Salt configuration started...on $vm" -ForegroundColor Green


$salt_cmd4 ="sudo mkdir -p /etc/salt-adc /var/log/salt-adc /var/cache/salt-adc /var/run/salt-adc"
$Invokesaltcmd4  = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd4   -Verbose -GuestCredential $cred

$salt_cmd5 ="sudo ls /etc/salt-adc/minion"
$Invokesaltcmd5 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd5  -Verbose -GuestCredential $cred


$salt_cmd6 ="sudo ls /usr/lib/systemd/system/salt-adc-minion.service"
$Invokesaltcmd6 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd6  -Verbose -GuestCredential $cred


if ($Invokesaltcmd5.scriptoutput -imatch  "minion" -and $Invokesaltcmd6.scriptoutput -imatch  "salt-adc-minion")
{

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> /etc/salt-adc/minion file and salt-adc-minion.service file present on $vm </font>"| Out-File $log -Append
write-host "/etc/salt-adc/minion file and salt-adc-minion.service file present on $vm" -ForegroundColor Green

$salt_cmd7 ="sudo cat /etc/salt-adc/minion |grep adc-apac"
$Invokesaltcmd7 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd7  -Verbose -GuestCredential $cred


if ($Invokesaltcmd7.scriptoutput -imatch  "PGSXSG1SM00004" -and $Invokesaltcmd7.scriptoutput -imatch  "PGSXSG1SM00005")
{

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> /etc/salt-adc/minion file validated Successfully on $vm </font>"| Out-File $log -Append
write-host "/etc/salt-adc/minion file Validated Succesfully on $vm $vm" -ForegroundColor Green

}
else
{
ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> /etc/salt-adc/minion file validation Failed on $vm </font>"| Out-File $log -Append
write-host "/etc/salt-adc/minion file Validation Failed on $vm" -ForegroundColor red
}
}
else
{

ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> /etc/salt-adc/minion file and salt-adc-minion.service file Not Present on $vm </font>"| Out-File $log -Append
write-host "/etc/salt-adc/minion file and salt-adc-minion.service file present on $vm" -ForegroundColor red

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Copying /etc/salt-adc/minion file and salt-adc-minion.service file on $vm </font>"| Out-File $log -Append
write-host "Copying /etc/salt-adc/minion file and salt-adc-minion.service file's on $vm" -ForegroundColor green

Get-Item "$ScriptDir\salt.txt" | Copy-VMGuestFile -Destination "/opt/repositories/" -Force -VM $vm -LocalToGuest -Verbose -GuestCredential $cred
Get-Item "$ScriptDir\salt1.txt" | Copy-VMGuestFile -Destination "/opt/repositories/" -Force -VM $vm -LocalToGuest -Verbose -GuestCredential $cred

$salt_cmd9 = @"
sudo touch /etc/salt-adc/minion
sudo touch /usr/lib/systemd/system/salt-adc-minion.service
sudo cat /opt/repositories/salt.txt >  /etc/salt-adc/minion
sudo cat /opt/repositories/salt1.txt > /usr/lib/systemd/system/salt-adc-minion.service
"@
$Invokesaltcmd9 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $salt_cmd9 -Verbose -GuestCredential $cred
    
}

$salt_cmd10 ="sudo ls /etc/salt/minion_id" 
$Invokesaltcmd10  = Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd10  -Verbose -GuestCredential $cred

if($Invokesaltcmd10.ExitCode.Equals(0))
{

$salt_cmd11 ="sudo hostname -f"
$Invokesaltcmd11  =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd11   -Verbose -GuestCredential $cred

$salt_cmd12 ="sudo cat /etc/salt/minion_id" 
$Invokesaltcmd12  =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd12  -Verbose -GuestCredential $cred

if ($Invokesaltcmd11  -imatch $Invokesaltcmd12)
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Minion_id already matched with hostname on $vm </font>"| Out-File $log -Append
    write-host "Minion_id already matched with hostname on $vm" -ForegroundColor Green
}
else
{
    $salt_cmd13 ="sudo hostname -f > /etc/salt/minion_id"
    $Invokesaltcmd13 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd13  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Minion_id updated successfully... on $vm </font>"| Out-File $log -Append
    write-host "Minion_id updated successfully...on $vm" -ForegroundColor Green
}
}
else
{

$salt_cmd14 = @"
sudo touch /etc/salt/minion_id
sudo hostname -f > /etc/salt/minion_id
"@
$Invokesaltcmd14 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $salt_cmd14 -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Minion_id file created and updated successfully... on $vm </font>"| Out-File $log -Append
write-host "Minion_id file created and updated successfully..." -ForegroundColor Green
}

$salt_cmd15 = @" 
sudo systemctl enable salt-adc-minion
sudo systemctl restart salt-adc-minion
sudo systemctl status salt-adc-minion
"@
$Invokesaltcmd15 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt_cmd15  -Verbose -GuestCredential $cred


if($Invokesaltcmd15 -imatch 'running' )
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Salt-minion Status is running</font>"| Out-File $log -Append
    write-host "Salt-minion Status is running" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Salt-minion Status is inactive</font>"| Out-File $log -Append
    write-host "Salt-minion Status is inactive" -ForegroundColor red

}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Salt Minion</font>"| Out-File $log -Append
    write-host "Failed to install Salt Minion" -ForegroundColor red
}
}
else
{
    write-Host "Salt Ports Connection Failed" -ForegroundColor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red>Salt Ports Connection Failed</font>"| Out-File $log -Append 
}
}


#########################################################

Function Postfix()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing Postfix Package on $vm ---------------------------------------------</b>" | Out-File $log -Append

$port1 ="sudo nc -zv 53.18.127.55 25"
$Invokportp1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port1  -Verbose -GuestCredential $cred

if($Invokportp1.scriptoutput -imatch  "succeeded")
{
    write-Host "Post Ports Connection Succeeded" -ForegroundColor Green
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Postfix Ports Connection Succeeded</font>"| Out-File $log -Append

## Validating Postfix installation ## 

$post_cmd1 = "sudo rpm -qa |grep postfix"
$Invokepostcmd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $post_cmd1  -Verbose -GuestCredential $cred

$invokepostcmds=$Invokepostcmd.Split()[0]

if($Invokepostcmd.scriptoutput -imatch $invokepostcmds)
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Postfix Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Postfix Installed/Running already on $vm" -ForegroundColor Green

$rmpostfix = "sudo zypper remove -y $invokepostcmds"
$Invokepostcmd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmpostfix  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Postfix Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Postfix Package Successfully on $vm" -ForegroundColor green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Postfix Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "Postfix Package Not Installed on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Installing Postfix Package on $vm.. </font>"| Out-File $log -Append
write-host "Installing Postfix Package on $vm.." -ForegroundColor Green

$post_cmd2 ="sudo zypper install -y postfix"
$Invokepostcmd2 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $post_cmd2 -Verbose -GuestCredential $cred


$post_cmd3 ="sudo rpm -qa | grep -i postfix"
$Invokepostcmd3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $post_cmd3 -Verbose -GuestCredential $cred


if($Invokepostcmd3.scriptoutput -imatch 'postfix')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Postfix Package installed Successfully </font>"| Out-File $log -Append
    write-host "Postfix installed Successfully" -ForegroundColor Green


ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Postfix Configuration Started on $vm </font>"| Out-File $log -Append
write-host "Postfix configuration started...on $vm" -ForegroundColor Green


$post_cmd4 = @"
sudo sed -i 's/^relayhost =.*/relayhost = mailhost.apac.bg.corpintra.net/' /etc/postfix/main.cf
sudo systemctl restart postfix.service
sudo sed -i 's/^relayhost =.*/relayhost = mailhost.apac.bg.corpintra.net/' /etc/postfix/main.cf
sudo systemctl status postfix.service
"@
$Invokepostcmd4 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $post_cmd4 -Verbose -GuestCredential $cred


$post_cmd6 = "grep -i ^relayhost /etc/postfix/main.cf"
$Invokepostcmd6 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $post_cmd6  -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=black> Postfix Configuration File: $Invokepostcmd6</font>"| Out-File $log -Append
write-host "Postfix Configuration File" -ForegroundColor Green
write-host "$Invokepostcmd6" -ForegroundColor Green

$post_cmd5 = @"
sudo systemctl enable postfix.service 
sudo systemctl restart postfix.service
sudo systemctl status postfix.service
"@
$Invokepostcmd5 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $post_cmd5 -Verbose -GuestCredential $cred


if($Invokepostcmd5.scriptoutput -imatch 'running' )
{
    ConvertTo-Html -Body "<br><font color=green> Postfix Status is running </font>"| Out-File $log -Append
    write-host "Qualys Status is running" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br><font color=red> Postfix Status is inactive </font>"| Out-File $log -Append
    write-host "Postfix Status is inactive" -ForegroundColor red
}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Postfix Package on $vm </font>"| Out-File $log -Append
    write-host "Failed to install Postfix Package on $vm" -ForegroundColor red
}
}
else
{
    write-Host "Postfix Ports Connection Failed" -ForegroundColor red
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red>Postfix Ports Connection Failed</font>"| Out-File $log -Append 
}
}

#####################################################################################
Function Solarwind()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Installing Solarwind Package on $vm ---------------------------------------------</b>" | Out-File $log -Append

## Validating Solarwind installation ## 

$solar_cmd1 = "sudo rpm -qa swiagent"
$Invokesolarcmd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $solar_cmd1  -Verbose -GuestCredential $cred

$invokesolarcmds=$Invokesolarcmd.Split()[0]

if($Invokesolarcmd.scriptoutput -imatch $invokesolarcmds)
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Solarwind Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Solarwind Installed/Running already on $vm" -ForegroundColor Green

$rmSolarwind = "sudo zypper remove -y $invokesolarcmds"
$Invokesolarcmd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmSolarwind  -Verbose -GuestCredential $cred

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Solarwind Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Solarwind Package Successfully on $vm" -ForegroundColor green
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Solarwind Package Not Installed on $vm</font>"| Out-File $log -Append
    write-host "Solarwind Package Not Installed on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Installing Solarwind Package on $vm.. </font>"| Out-File $log -Append
write-host "Installing Solarwind Package on $vm.." -ForegroundColor Green

$solar_cmd2 ="sudo bash +x /opt/repositories/solar_script.sh"
$Invokesolarcmd2 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $solar_cmd2 -Verbose -GuestCredential $cred


$solar_cmd3 ="sudo rpm -qa swiagent"
$Invokesolarcmd3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $solar_cmd3 -Verbose -GuestCredential $cred


if($Invokesolarcmd3.scriptoutput -imatch 'swiagent')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Solarwind Package installed Successfully </font>"| Out-File $log -Append
    write-host "Solarwind installed Successfully" -ForegroundColor Green


$solar_cmd5 = @"
sudo systemctl enable swiagentd.service 
sudo systemctl restart swiagentd.service
sudo systemctl status swiagentd.service
"@
$Invokesolarcmd5 = Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $solar_cmd5 -Verbose -GuestCredential $cred



if($Invokesolarcmd5.scriptoutput -imatch 'running' )
{
    ConvertTo-Html -Body "<br><font color=green> Solarwind Status is running </font>"| Out-File $log -Append
    write-host "Solarwind Status is running" -ForegroundColor Green
}
else
{
    ConvertTo-Html -Body "<br><font color=red> Solarwind Status is inactive </font>"| Out-File $log -Append
    write-host "Solarwind Status is inactive" -ForegroundColor red
}
}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to install Solarwind Package on $vm </font>"| Out-File $log -Append
    write-host "Failed to install Solarwind Package on $vm" -ForegroundColor red
}
}

#######################################################################################

Function Patching()
{

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- OS Patching Started  on $vm ---------------------------------------------</b>" | Out-File $log -Append

## Validating patch installation ## 

$patch_cmd1 ="hostnamectl |grep Kernel"
$Invokepatchcmd1 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $patch_cmd1 -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Current Kernel Version on $vm : $Invokepatchcmd1 </font>"| out-file $log -Append
write-host "Current Kernel Version on $vm : $Invokepatchcmd1" -ForegroundColor Green

$patch_cmd2 ="sudo ls -l /boot/vmlinuz*"
$Invokepatchcmd2 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $patch_cmd2 -Verbose -GuestCredential $cred

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> $Invokepatchcmd2 </font>"| out-file $log -Append
Write-host  "$Invokepatchcmd2" -ForegroundColor Green


$patch_cmd3 =@"
sudo zypper lr
sudo zypper refresh
"@
$Invokepatchcmd3 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $patch_cmd3 -Verbose -GuestCredential $cred

$patch_cmd31 =@"
sudo zypper update -y
"@
$Invokepatchcmd31 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $patch_cmd31 -Verbose -GuestCredential $cred


$patch_cmd4 ="sudo ls -l /boot/vmlinuz*"
$Invokepatchcmd4 =Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $patch_cmd4 -Verbose -GuestCredential $cred


if($Invokepatchcmd2.scriptoutput -imatch $Invokepatchcmd4)
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Server Patching Failed on $vm </font>"| Out-File $log -Append
    write-host "Server Patching on $vm" -ForegroundColor red

}
else
{

    ConvertTo-Html -Body "<br><font color=red> Server Patching Done Successfully </font>"| Out-File $log -Append
    write-host "Server Patching Done Successfully" -ForegroundColor red

ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Current Kernel Versions After Patching on $vm : $Invokepatchcmd4 </font>"| out-file $log -Append
Write-host "Current Kernel Version After Patching on $vm : $Invokepatchcmd4" -ForegroundColor Green

}
}
########################################################################################
Crowdstrike
Splunk
Qualys
Salt
Postfix
Solarwind
Patching

#####################################################################################

}
else
{

write-host "The $vm is not present in vcenter provided" -foregroundcolor red
ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> the $vm is not present in vcenter $vcenter provided"| out-file $log -Append

}
}
}

Connect
FMO_APAC
