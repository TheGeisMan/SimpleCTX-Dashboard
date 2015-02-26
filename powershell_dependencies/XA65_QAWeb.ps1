# This script will check for server metrics and upload to MySQL

# Runtime Switches for script
Param(
[Parameter(Mandatory=$True)][String]$QAServer
)

# Import QA Toolkit
Import-Module ".\XA65_QAv01.psm1" -ErrorAction SilentlyContinue
Add-PSSnapin Citrix* -ErrorAction SilentlyContinue
# Define variables
$Global:QAInfo = @{}
$SCheck = New-Object PSObject
$KB = @()



# Collect system information

Get-QABasicInfo -ServerName $QAServer



# odd/even logic if needed (gets last digit of server name and stores as int)
[Int]$QAInt = $QAServer.Substring(($QAServer.Length - 1))

[String]$WSUSResult = Get-WSUSMembership1 -ServerName $QAServer

$SCheck | Add-Member NoteProperty WSUS_Result $WSUSResult


# Internet Explorer version
[String]$IEResult = Get-IEVersion -ServerName $QAServer

$SCheck | Add-Member NoteProperty IE_Result $IEResult

# Check for proper patches
# Microsoft (special KB's for RDS hosts)

$KB += Get-KB -ServerName $QAServer -KBNum KB2799035
$KB += Get-KB -ServerName $QAServer -KBNum KB2878424
# $KB += Get-KB -ServerName $QAServer -KBNum KB000FAIL # Test failure

#Citrix RO patches

$KB += Get-CtxPatch -ServerName $QAServer -CtxKB XA650W2K8R2X64R04


# Check for services

# Primary CTX service
$Services = (Get-Services -ServerName $QAServer -Service IMAService) + ","

# Tivoli tools (if needed)
$Services += (Get-Services -ServerName $QAServer -Service KNTCMA_Primary) + ","

# Citrix smart auditor service (if used)
$Services += (Get-Services -ServerName $QAServer -Service CitrixSmAudAgent) + ","

# Microsoft system center service (if used)
$Services += Get-Services -ServerName $QAServer -Service ccmexec

$Services = $Services.Split(',')
$SCheck | Add-Member NoteProperty Svc_Result $Services -Force

# Check Citrix farm membership (mostly self explanatory)

$CtxInfo = Get-XAServer -ServerName $QAServer
$CtxInfo2 = Get-XAWorkerGroup -ServerName $QAServer | Select -Property WorkerGroupName
$CtxInfo3 = Get-XALoadEvaluator -ServerName $QAServer | Select -Property LoadEvaluatorName

# You can put servers in multiple worker groups so we extract the first WG and remove empty space
IF ($CtxInfo2.Count -gt 1){
$WG = ($CtxInfo2.WorkerGroupName[0]).Trim() | Out-String
} Else {
$WG = ($CtxInfo2.WorkerGroupName).Trim() | Out-String
}

# Preparation for SQL query 
$SQLPayload = $null
$SQLPayload += $QAInfo 
$SQLPayload += $CtxInfo | ConvertTo-HashTable
$SQLPayload += $CtxInfo2 | ConvertTo-HashTable
$SQLPayload += $CtxInfo3 | ConvertTo-HashTable
$SQLPayload += $Scheck | ConvertTo-HashTable

$conn = Connect-MySQL -hostname mysqlHost -username DBUser -pass DBpass -database farm_monitor

$query = $null
$query2 = $null
$query3 = $null
$query4 = $null

[String]$query = "INSERT INTO system_info (hostname,domain,uptime,os_ver) VALUES (" + '"' + $SQLPayload.ComputerName + '","' + $SQLPayload.Domain + '","' + $SQLPayload.Uptime + '","' + $SQLPayload.OS + '");'
[String]$query2 = "INSERT INTO hardware_info (hostname,cpu,hdd,ip,nictype,ram,vmtools,vmversion,vmserial) VALUES (" + '"' + $SQLPayload.ComputerName + '","' + $SQLPayload.CPU + '","' + $SQLPayload.HDDSize + '","' + $SQLPayload.Ipv4 + '","' + $SQLPayload.NIC + '","' + $SQLPayload.RAM + '","' + $SQLPayload.VMTools + '","' + $SQLPayload.VMVersion + '","' + $SQLPayload.VMSerial + '");'
[String]$query3 = "INSERT INTO ctx_info (hostname,ctxversion,installdate,zone,folderpath,r03,le,wg) VALUES (" + '"' + $SQLPayload.ServerName + '","' + $SQLPayload.CitrixVersion + '","' + $SQLPayload.CitrixInstallDate + '","' + $SQLPayload.ZoneName + '","' + $SQLPayload.FolderPath + '","' + $KB.Installed[2] + '","' + $SQLPayload.LoadEvaluatorName + '","' + $WG + '");'
[String]$query4 = "INSERT INTO software_info (hostname,ieversion,wsus,ima,kntcma,tlm,smaud,ccm,kb2799035,kb2878424) VALUES (" + '"' + $SQLPayload.ComputerName + '","' + $SQLPayload.IE_Result + '","' + $SQLPayload.WSUS_Result + '","' + $SQLPayload.Svc_Result[0] + '","' + $SQLPayload.Svc_Result[1] + '","' + $SQLPayload.Svc_Result[2] + '","' + $SQLPayload.Svc_Result[3] + '","' + $SQLPayload.Svc_Result[4] +  '","' + $KB.Installed[0] + '","' + $KB.Installed[1] + '");'

WriteMySQLQuery -conn $conn -query $query
WriteMySQLQuery -conn $conn -query $query2
WriteMySQLQuery -conn $conn -query $query3
WriteMySQLQuery -conn $conn -query $query4

# HTML Formatting (this script can send email reports instead of SQL queries)
# email preparation is below (for HTML format, tested with Outlook 2013)
# If the SQL code is confusing, this will give you a better idea of what actually goes in the database
# There is also logic below for Pass/Fail depending on certain predetermined thresholds, on the SQL front, this logic is in the PHP doc.
# Most of this is basic HTML/CSS and moving information from one variable to another so I'm not documenting any further
<#

[String]$css = '<style type="text/css">
               table{margin:auto; width:auto;}
               Body{background-color:White; Text-align:Center;}
               th{background-color:Black; color:White;}
               </style>'

[String]$SysInfo = $QAInfo | Select-Object @{ Name = "VM Version" ; Expression = {$_.VMVersion}},
                                   @{ Name = "VM Tools Version" ; Expression = {$_.VMTools}},
                                   @{ Name = "Hostname" ; Expression = {$_.ComputerName}},
                                   @{ Name = "Domain" ; Expression = {$_.Domain}},
                                   @{ Name = "Operating System" ; Expression = {$_.OS}},
                                   @{ Name = "System Uptime<br>(D:H:M)" ; Expression = {$_.Uptime}} |
                             ConvertTo-Html -Fragment -As Table -PreContent "<h3>System Information</h3>" | 
                             Out-String

[String]$HWInfo = $QAInfo | Select-Object @{ Name = "# of CPU  " ; Expression = {$_.CPU}},
                                   @{ Name = "Total RAM  " ; Expression = {$_.RAM}},
                                   @{ Name = "Total Disk Space (C:)  " ; Expression = {$_.HDDSize}},
                                   @{ Name = "NIC Type  " ; Expression = {$_.NIC}},
                                   @{ Name = "IP Address  " ; Expression = {$_.IPv4}} |
                            ConvertTo-Html -Fragment -As Table -PreContent "<h3>Hardware Information</h3>" | 
                            Out-String

[String]$CxReport = $CtxInfo | Select-Object @{ Name = "Citrix Version" ; Expression = {$_.CitrixVersion}},
                                             @{ Name = "Install Date" ; Expression = {$_.CitrixInstallDate}},
                                             @{ Name = "Zone Name" ; Expression = {$_.ZoneName}},
                                             @{ Name = "Farm Folder" ; Expression = {$_.FolderPath}}  | 
                               ConvertTo-Html -Fragment -as Table -PreContent "<h3>Citrix Farm Information</h3>" |
                               Out-String

[String]$IEWSUS_Check = IF (($QAServer -like "*H1PCHT-FV1*") -or ($QAServer -like "*H3PCHT-FV1*") -or ($QAServer -like "*H1SURG-FV1*") -or ($QAServer -like "*H3SURG-FV1*" )){
                        ($SCheck | Select-Object @{ Label = "IE Version Check" ; Expression = {$_.IE_Result}},
                                                 @{ Label = "WSUS Group Check" ; Expression = {$_.WSUS_Result}},
                                                 @{ Label = "IMA Service Check" ; Expression = {$_.Svc_Result[0]}},
                                                 @{ Label = "KNTCMA Service Check" ; Expression = {$_.Svc_Result[1]}},
                                                 @{ Label = "TLM Agent Service Check" ; Expression = {$_.Svc_Result[2]}},
                                                 @{ Label = "Smart Auditor Check" ; Expression = { $_.Svc_Result[3]}},
                                                 @{ Label = "SCCM Service Check" ; Expression = {$_.Svc_Result[4]}} |
                                   ConvertTo-Html -Fragment -as Table -PreContent "<h3>Software Checks</h3>" |
                                   Out-String).tostring()}

[String]$Patches = $KB | Select-Object @{ Name = "Patches (MS and CTX)" ; Expression = {$_.KBNum}},
                                       @{ Name = "Is installed?" ; Expression = {$_.Installed}} |
                         ConvertTo-Html -Fragment -As Table -PreContent '<br><h3>Patch Checks</h3>' |
                         Out-String
                                                                                                                                                                                                                                                                         

[String]$body = ConvertTo-Html -Title "$QAServer" `
        -Head "$css<center><h1>QA Report</h1><br><table><tr><th><strong>Runtime Info</strong></th></tr><tr><td>Executed from: $Env:ComputerName</td></tr><tr><td>Executed by: $Env:Username</td></tr><tr><td>Completed on: $(Get-Date)</td></tr></table></center>" `
        -body "$SysInfo $HWInfo $CxReport $IEWSUS_Check  $Patches"

[String]$body = $body.Replace('<td>Not','<td bgcolor="#FF0000">Not')

[String]$body = $body.Replace('<td>Please','<td bgcolor="#FF0000">Please')

IF ($IEResult -like "*wrong*"){
[String]$body = $body.Replace('<td>' + $IEResult,'<td bgcolor="#FF0000">' + $IEResult)
}

[String]$VMVersion = $QAInfo.VMVersion | Out-String
[Int]$VMVersion = $VMVersion.Replace('v','')
IF ($VMVersion -lt 10) {
[String]$body = $body.Replace('<td>' + $QAInfo.VMVersion,'<td bgcolor="#FF0000">' + $QAInfo.VMVersion)}

[Int]$VMToolsV = $QAInfo.VMTools | Out-String
IF ($VMToolsV -lt 9349){
[String]$body = $body.Replace('<td>' + $QAInfo.VMTools,'<td bgcolor="#FF0000">' + $QAInfo.VMTools)}

Foreach ($email in $DistList){

IF ($body -like "*FF0000*"){
Send-QA-Email -Subject "Server QA Report: $QAServer - FAILED" -ServerName $QAServer -To $email -Body $body.ToString()}
Else{
Send-QA-Email -Subject "Server QA Report: $QAServer - PASS" -ServerName $QAServer -To $email -Body $body.ToString()
}
}
#>