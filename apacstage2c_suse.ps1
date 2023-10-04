#How to execute this script .\apacstage2c_suse.ps1 "vCentrename"  and pop up will apper the enter"Username@emea.corpdir.net" "password"
#populate apacstage2c_suse_input.csv file with all the details before execution.  
#variables

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

$vcenter= "saai1m111001.inedc.corpintra.net"
$creden = Get-Credential -Message "Enter your Vcenter credentials"

$currentDate = Get-Date -Format "dd-MMM-yyyy"
$LogPath = "$ScriptDir\STAGE2"
$log = "$LogPath\apacstage2c_$currentDate.html"


If(!(test-path $LogPath))
{
      New-Item -ItemType Directory -Force -Path $LogPath
}


ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  Connecting to vcenter  ---------------------------------------------</b> " | Out-File $log -Append

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#Connect-VIServer -Server $vcenter -User "$vname" -Password "$vpass" -Verbose

$connect=Connect-VIserver -Server $vcenter -credential $creden


if ($connect -imatch $vcenter)
{

ConvertTo-Html -Body "<br><font color=green> $(Get-Date):Connected to VCenter $vcenter </font>" | Out-File $log -Append
write-host "Connected to VCenter $vcenter Successfully" -ForegroundColor Green

Foreach($Line in (Import-Csv "./apacstage2c_suse_input.csv")){

$vm=$Line.VM
$server = Get-VM -Name $vm

if($server -imatch $vm )
{

$vm=$Line.VM
$Root_user= $Line.User
$Root_Password=$line.Password

$ip=(Get-VM $vm | Get-View).Guest.IpAddress

#Pass throught credential of local admin to secure string
$secure_password=ConvertTo-SecureString "$Root_Password" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential($Root_user,$secure_password)

ConvertTo-Html -Body "<br><br><b><font color=blue>$(Get-Date)---------------------------------------------  Process for $vm Started  ---------------------------------------------</font></b>" | Out-File $log -Append
Write-Host "Process for $vm started" -ForegroundColor Green


ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Validating Splunk Package on $vm ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Validating Splunk Package on $vm" -ForegroundColor Green

$splunk = "sudo rpm -qa |grep salm-agent"
$Invokesplunk =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk  -Verbose -GuestCredential $cred

$invokesplunks=$Invokesplunk.Split()[0]

if($Invokesplunk.scriptoutput -imatch 'salm-agent')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Splunk Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Splunk Installed/Running already on $vm" -ForegroundColor Green

$rmsplunk = "sudo zypper remove -y $invokesplunks"
$Invokermsplunk =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmsplunk  -Verbose -GuestCredential $cred

$splunk1 = "sudo rpm -qa |grep salm-agent"
$Invokesplunk1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $splunk1  -Verbose -GuestCredential $cred

if($Invokesplunk1.scriptoutput -imatch 'salm-agent')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> failed to Uninstall Splunk</font>"| Out-File $log -Append
    write-host "Failed to Uninstall Splunk" -ForegroundColor red

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Splunk Package successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled Splunk Package Successfully on $vm" -ForegroundColor green

}
}
else{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> Splunk Package is not present on $vm </font>"| Out-File $log -Append
    write-host "Splunk Package is not present on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Validating Crowdstrike Package on $vm ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Validating CrowdStrike Package on $vm" -ForegroundColor Green

$crowd = "sudo rpm -qa |grep falcon-sensor"
$Invokecrowd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $crowd  -Verbose -GuestCredential $cred

$invokecrowds=$Invokecrowd.Split()[0]

if($Invokecrowd.scriptoutput -imatch 'falcon-sensor')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> CrowdStrike Package Installed already on $vm </font>"| out-file $log -Append
    write-host "CrowdStrike Installed/Running already on $vm" -ForegroundColor Green

$rmcrowd = "sudo zypper remove -y $invokecrowds"
$Invokermcrowd =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmcrowd  -Verbose -GuestCredential $cred

$crowd1 = "sudo rpm -qa |grep falcon-sensor"
$Invokecrowd1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $crowd1  -Verbose -GuestCredential $cred

if($Invokecrowd1.scriptoutput -imatch 'falcon-sensor')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Failed to Uninstall CrowdStrike Package on $vm</font>"| Out-File $log -Append
    write-host "Failed to Uninstall CrowdStrike Package on $vm" -ForegroundColor red

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled CrowdStrike Package Successfully on $vm</font>"| Out-File $log -Append
    write-host "Uninstalled CrowdStrike Package Successfully on $vm" -ForegroundColor green

}
}
else{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> CrowdStrike Package is not present on $vm</font>"| Out-File $log -Append
    write-host "CrowdStrike Package is not present on $vm" -ForegroundColor green

}


ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Validating Salt Package on $vm ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Validating Salt Package on $vm" -ForegroundColor Green

$salt = "sudo rpm -qa |grep salt"
$Invokesalt =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt  -Verbose -GuestCredential $cred

$invokesalts=$Invokesalt.Split()[0]

if($Invokesalt -imatch 'salt-minion' -or $Invokesalt -imatch 'salt')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Salt Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Salt Installed/Running already on $vm" -ForegroundColor Green

$rmsalt= @"
sudo zypper remove -y salt-minion salt venv-salt-minion
"@
$Invokermsalt =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmsalt  -Verbose -GuestCredential $cred


$salt1 = "sudo rpm -qa |grep salt"
$Invokesalt1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $salt1  -Verbose -GuestCredential $cred

if($Invokesalt1.scriptoutput -imatch 'salt-minion')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> failed to Uninstall Salt Package on $vm</font>"| Out-File $log -Append
    write-host "Failed to Uninstall Salt Package on $vm" -ForegroundColor red

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Salt Package successfully on $vm </font>"| Out-File $log -Append
    write-host "Uninstalled Salt Package successfully on $vm" -ForegroundColor green

}
}
else{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> Salt Package is not present on $vm </font>"| Out-File $log -Append
    write-host "Salt package is not present on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Validating Qualys Package on $vm  ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Validating Qualys Package on $vm" -ForegroundColor Green

$qualys = "sudo rpm -qa |grep qualys-cloud-agent"
$Invokequalys =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qualys  -Verbose -GuestCredential $cred

$invokequalyss=$Invokequalys.Split()[0]

if($Invokequalys.scriptoutput -imatch 'qualys-cloud-agent')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Qualys Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Qualys Installed/Running already on $vm" -ForegroundColor Green


$rmqualys = "sudo zypper remove -y $invokequalyss"
$Invokermqualys =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmqualys  -Verbose -GuestCredential $cred


$qualys1 = "sudo rpm -qa |grep qualys-cloud-agent"
$Invokequalys1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $qualys1  -Verbose -GuestCredential $cred

if($Invokequalys1.scriptoutput -imatch 'qualys-cloud-agent')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> failed to Uninstall Qualys Package on $vm</font>"| Out-File $log -Append
    write-host "Failed to Uninstall Qualys Package on $vm" -ForegroundColor red

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Qualys Package successfully on $vm </font>"| Out-File $log -Append
    write-host "Uninstalled Qualys Package successfully on $vm" -ForegroundColor green

}
}
else{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> Qualys Package is not present on $vm </font>"| Out-File $log -Append
    write-host "Qualys package is not present on $vm" -ForegroundColor green
}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)--------------------------------------------- Uninstalling Solarwind Package on $vm ---------------------------------------------</b>" | Out-File $log -Append
Write-Host "Validating Solarwind Package on $vm" -ForegroundColor Green

$solar = "sudo rpm -qa |grep swiagent"
$Invokesolar =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $solar  -Verbose -GuestCredential $cred

$invokesolars=$Invokesolar.Split()[0]

if($Invokesolar.scriptoutput -imatch 'swiagent')
{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> Solarwind Package Installed already on $vm </font>"| out-file $log -Append
    write-host "Solarwind Installed/Running already on $vm" -ForegroundColor Green


$rmsolar = "sudo zypper remove -y swiagent"
$Invokermsolar =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $rmsolar  -Verbose -GuestCredential $cred


$solar1 = "sudo rpm -qa |grep swiagent"
$Invoksolar1 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $solar1  -Verbose -GuestCredential $cred

if($Invoksolar1.scriptoutput -imatch 'swiagent')
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=red> failed to Uninstall Solarwind Package on $vm</font>"| Out-File $log -Append
    write-host "Failed to Uninstall Solarwind Package on $vm" -ForegroundColor red

}
else
{
    ConvertTo-Html -Body "<br>$(Get-Date)<font color=green> Uninstalled Solarwind Package successfully on $vm </font>"| Out-File $log -Append
    write-host "Uninstalled Solarwind Package successfully on $vm" -ForegroundColor green

}
}
else{

    ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> Solarwind Package is not present on $vm </font>"| Out-File $log -Append
    write-host "Solarwind package is not present on $vm" -ForegroundColor green

}

ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  Cleanup Started on $vm ---------------------------------------------</b> " | Out-File $log -Append
Write-Host "SUMA Clean-up started.." -ForegroundColor Green

$cleanup = @"
sudo rm -rf /var/cache/salt /etc/salt
sudo rm -rf /etc/machine-id
sudo rm -rf /var/lib/dbus/machine-id
sudo dbus-uuidgen --ensure
sudo systemd-machine-id-setup
"@
$Invokeclean=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $cleanup  -Verbose -GuestCredential $cred
Write-Host "SUMA Clean-up done.." -ForegroundColor Green



ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  Moving FMO Packages on $vm ---------------------------------------------</b> " | Out-File $log -Append
Write-Host "Moving FMO Packages for tools Installation.." -ForegroundColor Green


$dir = @"
sudo mkdir /opt/repositories/
sudo chmod 777 /opt/repositories/
"@
$Invokedir=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $dir  -Verbose -GuestCredential $cred
Write-Host "/opt/repositories directory created.." -ForegroundColor Green

$tools = "$ScriptDir\tools\*"
Get-Item $tools | Copy-VMGuestFile -Destination "/opt/repositories/" -Force -VM $vm -LocalToGuest -GuestCredential $cred -Verbose

ConvertTo-Html -Body "<br>$(Get-Date)<font color=Green> FMO Packages Copied on $vm /opt/repositories/ Path </font>"| Out-File $log -Append
write-host "FMO Packages Copied on $vm /opt/repositories/ Path" -ForegroundColor green



ConvertTo-Html -Body "<br><br><b>$(Get-Date)---------------------------------------------  SUMA Registration  ---------------------------------------------</b> " | Out-File $log -Append
Write-Host "SUMA Registration started.." -ForegroundColor Green

$port1="sudo nc -zv sashsm000011.adc-apac.corpintra.net 443"
$Invokport1=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port1  -Verbose -GuestCredential $cred

$port2="nc -zv sashsm000011.adc-apac.corpintra.net 80"
$Invokport2=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $port2  -Verbose -GuestCredential $cred

if($Invokport1.scriptoutput -imatch  "succeeded" )
{
        write-Host "SUMA Ports Connection  Succeeded" -ForegroundColor Green
        ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA Ports Connection  Succeeded</font>"| Out-File $log -Append
}


$awk="sudo hostnamectl | grep sles | awk '{print "+'$' + "3,"+'$'+ "4}'"
$InvokeS2=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $awk  -Verbose -GuestCredential $cred

$backuprepo=@"
sudo mkdir -p /opt/repositories/oldrepos
sudo mv /etc/zypp/repos.d/* /opt/repositories/oldrepos/
"@
$Invokebackup=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $backuprepo  -Verbose -GuestCredential $cred

$clean="sudo zypper clean"
$Invokeclean=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $clean  -Verbose -GuestCredential $cred

############################################################################################################

$env=$vm.ToCharArray()[0]           ##env variable is for 1st character prod/dev/int/QA/test
$service1=$vm.ToCharArray()[3]      ##service1 variable is for 4th character (SAP/nonsap)
write-host $env
write-host $service1


if ($InvokeS2 -imatch "sles:15")
{
    if ($service1 -match "[gG]")  ##4th character of hostname SAP test
    {
        if ($env -match "[dD]" -or $env -match "[qQ]" -or $env -match "[tT]") 
        {

write-host "Running SAP(DEV/QA/TEST)" -ForegroundColor Green
$curl1= @"
sudo touch /var/tmp/suma1.sh
sudo chmod 777 /var/tmp/suma1.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma1.sh
sudo echo 'sudo -i' >> /var/tmp/suma1.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_SAP_VCT_dev_apac_x86_64.sh | bash' >> /var/tmp/suma1.sh
sudo sed -i 's/\r$//' /var/tmp/suma1.sh
sudo sh /var/tmp/suma1.sh 
"@
	    $Invokecurl1=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl1  -Verbose -GuestCredential $cred

            if($Invokecurl1.scriptoutput -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }
	    }
	    elseif ($env -match "[Ss]")
	    {

write-host "Running SAP(PROD)" -ForegroundColor Green
$curl2= @"
sudo touch /var/tmp/suma2.sh
sudo chmod 777 /var/tmp/suma2.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma2.sh
sudo echo 'sudo -i' >> /suma2.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_SAP_VCT_prod_apac_x86_64.sh | bash' >> /var/tmp/suma2.sh
sudo sed -i 's/\r$//' /var/tmp/suma2.sh
sudo sh /var/tmp/suma2.sh
"@
        $Invokecurl2=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl2  -Verbose -GuestCredential $cred

            if($Invokecurl2 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }
	    }
	    elseif ($env -match "[Ii]")
	    {
write-host "Running SAP(INT)" -ForegroundColor Green
$curl3= @"
sudo touch /var/tmp/suma3.sh
sudo chmod 777 /var/tmp/suma3.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma3.sh
sudo echo 'sudo -i' >> /var/tmp/suma3.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_SAP_VCT_int_apac_x86_64.sh | bash' >> /var/tmp/suma3.sh
sudo sed -i 's/\r$//' /var/tmp/suma3.sh
sudo sh /var/tmp/suma3.sh
"@
        $Invokecurl3=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl3  -Verbose -GuestCredential $cred

            if($Invokecurl3 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }
	    }
	    else
 	    {
	    Write-Host "Hostname $vm is not either Prod/Dev/Test/Int for SLES15" -ForegroundColor red
        ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Hostname $vm is not either Prod/Dev/Int for SLES15 <br></font>"| Out-File $log -Append
	    }
    }
    elseif($service1 -match "[cCfFmMwWdDaAbBkK]")
    {
     	if($env -match "[Dd]" -or $env -match "[Qq]" -or $env -match "[Tt]")
	    {

Write-Host "Running NONSAP(DEV/QA/TEST)" -ForegroundColor Green
$curl4= @"
sudo touch /var/tmp/suma4.sh
sudo chmod 777 /var/tmp/suma4.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma4.sh
sudo echo 'sudo -i' >> /var/tmp/suma4.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_VCT_dev_apac_x86_64.sh | bash' >> /var/tmp/suma4.sh
sudo sed -i 's/\r$//' /var/tmp/suma4.sh
sudo sh /var/tmp/suma4.sh 
"@
        $Invokecurl4=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl4  -Verbose -GuestCredential $cred

            if($Invokecurl4 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }

	    }
	    elseif ($env -match "[Ss]")
	    {
write-host "Running NONSAP(PROD)" -ForegroundColor Green

$curl5= @"
sudo touch /var/tmp/suma5.sh
sudo chmod 777 /var/tmp/suma5.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma5.sh
sudo echo 'sudo -i' >> /var/tmp/suma5.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_VCT_prod_apac_x86_64.sh | bash' >> /var/tmp/suma5.sh
sudo sed -i 's/\r$//' /var/tmp/suma5.sh
sudo sh /var/tmp/suma5.sh 
"@
        $Invokecurl5=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl5  -Verbose -GuestCredential $cred

            if($Invokecurl5 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }
        }
	    elseif ($env -match "[Ii]")
	    {
write-host "Running NONSAP(INT)" -ForegroundColor Green

$curl6= @"
sudo touch /var/tmp/suma6.sh
sudo chmod 777 /var/tmp/suma6.sh
sudo echo '#!/bin/bash' >  /var/tmp/suma6.sh
sudo echo 'sudo -i' >> /var/tmp/suma6.sh
sudo echo 'curl -Sks https://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/SLES15_SP3_VCT_int_apac_x86_64.sh | bash' >> /var/tmp/suma6.sh
sudo sed -i 's/\r$//' /var/tmp/suma6.sh
sudo sh /var/tmp/suma6.sh 
"@
        $Invokecurl6=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl6  -Verbose -GuestCredential $cred

            if($Invokecurl6 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }

	    }
	    else
 	    {
	        Write-Host "Hostname $vm is not either Prod/Dev/Int for SLES15" -ForegroundColor red
            ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Hostname $vm is not either Prod/Dev/Int for SLES15 <br></font>"| Out-File $log -Append
	    }
    }
    else
    {
      Write-Host "Unknonw Application from Hostname for SLES15" -ForegroundColor red
      ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unknonw Application from Hostname For SLES15 <br></font>"| Out-File $log -Append
    }
}
elseif ($InvokeS2 -imatch "sles:12")
{
   if ($service1 -match "[gG]")  ##4th character of hostname SAP test
    {
	    if ($env -match "[dD]" -or $env -match "[qQ]" -or $env -match "[tT]" -or $env -match "[Ss]" -or $env -match "[Ii]")
        {

write-host "Running SLES:12 NONSAP SAP SUMA..." -ForegroundColor Green

$curl7= @"
sudo touch /var/tmp/suma7.sh
sudo chmod 777 /var/tmp/suma7.sh
sudo echo '#!/bin/bash' >  /suma7.sh
sudo echo 'sudo -i' >> /var/tmp/suma7.sh
sudo echo 'curl -Sks http://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/APAC-SLES12SP5SAPx8664-SP5-202302-vm-base.sh | bash' >> /var/tmp/suma7.sh
sudo sed -i 's/\r$//' /var/tmp/suma7.sh
sudo sh /var/tmp/suma7.sh 
"@
        $Invokecurl7=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl7  -Verbose -GuestCredential $cred

            if($Invokecurl7 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }

	    }
	    else
	    {
	        Write-Host "Hostname $vm is not either Prod/Dev/QA/Test/Int for SLES12"-ForegroundColor red
            ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Hostname $vm is not either Prod/Dev/QA/Test/Int for SLES12 <br></font>"| Out-File $log -Append
	    }
    }
    elseif($service1 -match "[cCfFmMwWdDaAbBkK]")
    {
	    if($env -match "[Dd]" -or $env -match "[Qq]" -or $env -match "[Tt]" -or $env -match "[Ss]" -or $env -match "[Ii]")
	    {

write-host "Running SLES:12 NONSAP Prod/DEV/QA/Test/Int SUMA..." -ForegroundColor Green

$curl7 =@"
sudo touch /var/tmp/suma8.sh
sudo chmod 777 /var/tmp/suma8.sh
sudo echo '#!/bin/bash' >  /suma8.sh
sudo echo 'sudo -i' >> /var/tmp/suma8.sh
sudo echo 'curl -Sks http://sashsm000011.adc-apac.corpintra.net/pub/bootstrap/APAC-SLES12SP5x8664-SP5-202302-vm-base.sh | bash' >> /var/tmp/suma8.sh
sudo sed -i 's/\r$//' /var/tmp/suma8.sh
sudo sh /var/tmp/suma8.sh 
"@
        $Invokecurl7 =Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $curl7  -Verbose -GuestCredential $cred

            if($Invokecurl7 -imatch "bootstrap complete")
            {
                write-Host "SUMA registered Successfully" -ForegroundColor Green
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>SUMA registered Sucessfully</font>"| Out-File $log -Append
            }
            else
            {
                write-Host "Unable to register SUMA" -ForegroundColor red
                ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unable to register SUMA</font>"| Out-File $log -Append
            }
	    }
        else
	    {
	        Write-Host "Hostname $vm is not either Prod/Dev/Int for SLES12" -ForegroundColor red
            ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Hostname $vm is not either Prod/Dev/Int for SLES12 <br></font>"| Out-File $log -Append
	    }
    }
    else
    {
        Write-Host "Unknonw Application from Hostname for SLES12" -ForegroundColor red
        ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Unknonw Application from Hostname for SLES12<br></font>"| Out-File $log -Append
    }
}
else
{
Write-Host "Neither Sles12 nor sles15" -ForegroundColor red
ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Neither Sles12 nor sles15 <br>$Invokelr</font>"| Out-File $log -Append
}



########################################################################################################
##delay command
Write-Host "1 minutes delay..."
Start-Sleep -Seconds 60

$zypperlr="sudo zypper lr"
$Invokezypperlr=Invoke-VMScript -VM $vm -ScriptType bash -ScriptText $zypperlr  -Verbose -GuestCredential $cred
  
$Invokelr=$Invokezypperlr.Split()[0]
Write-Host "Zypper lr: $Invokezypperlr" -ForegroundColor Green
ConvertTo-Html -Body "<br>$(Get-Date)<font color=green>Zypper lr : <br>$Invokelr</font>"| Out-File $log -Append


$rm=@"
sudo rm -rf /var/tmp/suma1.sh
sudo rm -rf /var/tmp/suma2.sh
sudo rm -rf /var/tmp/suma3.sh
sudo rm -rf /var/tmp/suma4.sh
sudo rm -rf /var/tmp/suma5.sh
sudo rm -rf /var/tmp/suma6.sh
sudo rm -rf /var/tmp/suma7.sh
sudo rm -rf /var/tmp/suma8.sh
"@
$Invokerm=Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $rm -Verbose -GuestCredential $cred


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
