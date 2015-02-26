# This script will pull metrics from a Netscaler HA pair using the NITRO API



# Pre req

Function Connect-MySQL {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)]$hostname,
	  [Parameter(Mandatory=$True)]$username,
	  [Parameter(Mandatory=$True)]$pass,
	  [Parameter(Mandatory=$True)]$database
	  )
  # Load MySQL .NET Connector Objects
  [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data")
 
  # Open Connection
  $connStr = "server=" + $hostname + ";port=3306;uid=" + $username + ";pwd=" + $pass + ";database="+$database+";Pooling=FALSE"
  $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
  $conn.Open()
  $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand("USE $database", $conn)
  return $conn
 
}

function WriteMySQLQuery {
[CmdletBinding()]
Param ($conn, 

[string]$query)
 
  $command = $conn.CreateCommand()
  $command.CommandText = $query
  $RowsInserted = $command.ExecuteNonQuery()
  $command.Dispose()
  if ($RowsInserted) {
    return $RowInserted
  } else {
    return $false
  }
}

$user = 'nsroot'
$pass = 'nspass' | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $user,$pass
$today = Get-Date -UFormat %m-%d-%y

# Find out who is active

$HAStatsURL = "http://prd.dmz.company.com/nitro/v1/stat/hanode"
$NitroRequest = $HAStatsURL
$HAStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json
$HAStatus = $HAStats.hanode.hacurmasterstate

IF ($HAStatus -like "Primary") {
$PrimaryNode = "FBT"
$NetscalerURL = "http://prd.dmz.company.com"
} ELSE {
$PrimaryNode = "SHY"
$NetscalerURL = "http://dr.dmz.company.com"
}


# Collection of netscaler metrics

$AAAStatsURL = "$NetscalerURL/nitro/v1/stat/aaa"
$NitroRequest = $AAAStatsURL
$VPNStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json

$SystemStatsURL = "$NetscalerURL/nitro/v1/stat/system"
$NitroRequest = $SystemStatsURL
$NSStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json

$LBStatsURL = "$NetscalerURL/nitro/v1/stat/lbvserver"
$NitroRequest = $LBStatsURL
$LBStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json

$SSLStatsURL = "$NetscalerURL/nitro/v1/stat/ssl"
$NitroRequest = $SSLStatsURL
$SSLStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json

$NetStatsURL = "$NetscalerURL/nitro/v1/stat/interface"
$NitroRequest = $NetStatsURL
$NetStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json

$CertStatsURL = "$NetscalerURL/nitro/v1/config/sslcertkey"
$NitroRequest = $CertStatsURL
$CertStats = Invoke-WebRequest -UseBasicParsing -Credential $credential -URI $NitroRequest | ConvertFrom-Json


$SSLCards = ($SSLStats.ssl.sslcards / $SSLStats.ssl.sslnumcardsup)

$VPNStatsSummary = New-Object psobject
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name CurrentSessions -Value $VPNStats.aaa.aaacursessions
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name ActiveNode -Value $PrimaryNode
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name AuthSuccess -Value $VPNStats.aaa.aaaauthsuccess
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name AuthFail -Value $VPNStats.aaa.aaaauthfail
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name FlashAvail -Value $NSStats.system.disk0avail
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name HDDAvail -Value $NSStats.system.disk1avail
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name PktCPU -Value $NSStats.system.pktcpuusagepcnt
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name MgmtCPU -Value $NSStats.system.mgmtcpuusagepcnt
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name RAMAvail -Value $NSStats.system.memusagepcnt
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name PSU1Stat -Value $NSStats.system.powersupply1status
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name PSU2Stat -Value $NSStats.system.powersupply2status
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name InetTrafficRX -Value $NetStats.Interface[6].rxbytesrate
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name InetTrafficTX -Value $NetStats.Interface[6].txbytesrate
$VPNStatsSummary | Add-Member -MemberType NoteProperty -Name SSLCardsHealth -Value $SSLCards

$Vserver1 = New-Object psobject
$Vserver1 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[3].name
$Vserver1 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[3].primaryipaddress
$Vserver1 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[3].state
$Vserver1 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[3].vslbhealth
$Vserver1 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[3].hitsrate

$Vserver2 = New-Object psobject
$Vserver2 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[4].name
$Vserver2 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[4].state
$Vserver2 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[4].primaryipaddress
$Vserver2 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[4].vslbhealth
$Vserver2 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[4].hitsrate

$Vserver3 = New-Object psobject
$Vserver3 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[5].name
$Vserver3 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[5].state
$Vserver3 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[5].primaryipaddress
$Vserver3 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[5].vslbhealth
$Vserver3 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[5].hitsrate

$Vserver4 = New-Object psobject
$Vserver4 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[6].name
$Vserver4 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[6].state
$Vserver4 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[6].primaryipaddress
$Vserver4 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[6].vslbhealth
$Vserver4 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[6].hitsrate

$Vserver5 = New-Object psobject
$Vserver5 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[7].name
$Vserver5 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[7].state
$Vserver5 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[7].primaryipaddress
$Vserver5 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[7].vslbhealth
$Vserver5 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[7].hitsrate

$Vserver6 = New-Object psobject
$Vserver6 | Add-Member -MemberType NoteProperty -Name Name -Value $LBStats.lbvserver[9].name
$Vserver6 | Add-Member -MemberType NoteProperty -Name state -Value $LBStats.lbvserver[9].state
$Vserver6 | Add-Member -MemberType NoteProperty -Name ip -Value $LBStats.lbvserver[9].primaryipaddress
$Vserver6 | Add-Member -MemberType NoteProperty -Name health -Value $LBStats.lbvserver[9].vslbhealth
$Vserver6 | Add-Member -MemberType NoteProperty -Name hits -Value $LBStats.lbvserver[9].hitsrate




# SQL routine

$conn = Connect-MySQL -hostname mysqlHost -username DBUser -pass DBpass -database farm_monitor
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE netscaler_info"
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE vserver_info"
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE sslcert_info"


$query = $null
$query2 = $null
$query3 = $null
$query4 = $null
$query5 = $null
$query6 = $null
$query7 = $null
[String]$query = "INSERT INTO netscaler_info (current_aaa,active_node,auth_success,auth_fail,flash_avail,hdd_avail,pkt_cpu,mgmt_cpu,ram_avail,psu1stat,psu2stat,inetrx,inettx,sslcard_health) VALUES (" + '"' + $VPNStatsSummary.CurrentSessions + '","' + $PrimaryNode + '","' + $VPNStatsSummary.AuthSuccess + '","' + $VPNStatsSummary.AuthFail + '","' + $VPNStatsSummary.FlashAvail + '","' + $VPNStatsSummary.HDDAvail + '","' + $VPNStatsSummary.PktCPU + '","' + $VPNStatsSummary.MgmtCPU + '","' + $VPNStatsSummary.RAMAvail + '","' + $VPNStatsSummary.PSU1Stat + '","' + $VPNStatsSummary.PSU2Stat + '","' + $VPNStatsSummary.InetTrafficRX + '","' + $VPNStatsSummary.InetTrafficTX + '","' + $SSLCards + '");'
[String]$query2 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $Vserver1.Name + '","' + $Vserver1.health + '","' + $Vserver1.state + '","' + $Vserver1.ip + '","' + $Vserver1.hits + '");'
[String]$query3 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $vserver2.Name + '","' + $vserver2.health + '","' + $vserver2.state + '","' + $vserver2.ip + '","' + $vserver2.hits + '");'
[String]$query4 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $vserver3.Name + '","' + $vserver3.health + '","' + $vserver3.state + '","' + $vserver3.ip + '","' + $vserver3.hits + '");'
[String]$query5 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $vserver4.Name + '","' + $vserver4.health + '","' + $vserver4.state + '","' + $vserver4.ip + '","' + $vserver4.hits + '");'
[String]$query6 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $vserver5.Name + '","' + $vserver5.health + '","' + $vserver5.state + '","' + $vserver5.ip + '","' + $vserver5.hits + '");'
[String]$query7 = "INSERT INTO vserver_info (vserver,vserver_health,vserver_state,vserver_ip,vserver_hits) VALUES (" + '"' + $vserver6.Name + '","' + $vserver6.health + '","' + $vserver6.state + '","' + $vserver6.ip + '","' + $vserver6.hits + '");'

$i = $null
[int]$i = "-1"
Foreach ($Cert in $CertStats.sslcertkey.certkey) {
$i++
$query8 = $null
[String]$query8 = "INSERT INTO sslcert_info (certname,expirydate,status) VALUES (" + '"' + $CertStats.sslcertkey.certkey[$i] + '","' + $CertStats.sslcertkey.daystoexpiration[$i] + '","' + $CertStats.sslcertkey.status[$i] + '");'
WriteMySQLQuery -conn $conn -query $query8
}

WriteMySQLQuery -conn $conn -query $query
WriteMySQLQuery -conn $conn -query $query2
WriteMySQLQuery -conn $conn -query $query3
WriteMySQLQuery -conn $conn -query $query4
WriteMySQLQuery -conn $conn -query $query5
WriteMySQLQuery -conn $conn -query $query6
WriteMySQLQuery -conn $conn -query $query7

exit 4