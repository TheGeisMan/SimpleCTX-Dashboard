# This will grab all servers from your Citrix farm and only process the odd numbered servers

Add-PSSnapin Citrix* -ErrorAction SilentlyContinue
Import-Module ".\XA65_QAv01.psm1" -ErrorAction SilentlyContinue -Global
$farmServers = (Get-XAServer *).ServerName
$farmServers = $farmServers | sort
Foreach ($server in $farmServers) {
$Int = $server.Substring(($server.Length - 1))
IF ((Check-Even -int $int) -eq $false){
.\QAFarmMetrics.ps1 -EvalServer $server
}}