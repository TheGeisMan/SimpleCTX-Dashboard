# This will check every server in the Citrix farm for QA metrics (I have it scheduled to run daily, starting at 2am)
# My farm contains over 1000 application hosts, so 2am is early enough that it's done by 6 (start of business)


Add-PSSnapin Citrix* -ErrorAction SilentlyContinue
Import-Module ".\XA65_QAv01.psm1" -ErrorAction SilentlyContinue
$farmServers = (Get-XAServer *).ServerName
$farmServers = $farmServers | sort


# I truncate my tables because most of this stuff is useless beyond a 24h period
$conn = Connect-MySQL -hostname mysqlHost -username DBuser -pass DBpass -database farm_monitor
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE ctx_info"
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE hardware_info"
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE software_info"
WriteMySQLQuery -conn $conn -query "TRUNCATE TABLE system_info"

# pretty self explanatory
Foreach ($server in $farmServers) {
.\XA65_QAWeb.ps1 -QAServer $server
}