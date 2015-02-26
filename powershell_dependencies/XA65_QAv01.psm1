<#
 .Synopsis
 A collection of functions that check Citrix ESXi virtual servers for required components

 .Description
 This is basically a tool kit that makes Citrix farms a little easier to monitor
 #>

 
 # This function collects basic info (Hostname,OS Version,Domain,IPv4,NIC,RAM,CPU,Uptime,HDD)
 # $QAInfo = @{} #Remove this once this script is converted into a module
 
 Function Get-QABasicInfo {
 [CmdletBinding()]
 Param (
       [Parameter(Mandatory=$True)][string]$ServerName)
            
                      
            [String[]]$QAInfo.ComputerName = $ServerName
                      $QAInfo.OS = Get-WmiObject -ComputerName $ServerName -Class Win32_OperatingSystem | 
                                   Select-Object -Property Caption | ft -HideTableHeaders | Out-String
                              $RAM = Get-WmiObject -ComputerName $ServerName -Class Win32_ComputerSystem |
                                    Select-Object -Property TotalPhysicalMemory | 
                                    Ft -HideTableHeaders | Out-String
                              $RAM = ([Math]::Round($RAM / 1GB,0)).ToString()
            [String[]]$QAInfo.RAM = $RAM + "GB"
                      $QAInfo.CPU = Get-WmiObject -ComputerName $ServerName -Class Win32_ComputerSystem |
                                    Select-Object -Property NumberOfLogicalProcessors | ft -HideTableHeaders | Out-String
            [String[]]$QAInfo.CPU = (($QAInfo.CPU) -replace '\s+','') + " Cores"
                      $QAInfo.Domain = Get-WmiObject -ComputerName $ServerName -Class Win32_ComputerSystem |
                                       Select-Object -Property Domain | ft -HideTableHeaders | Out-String
            [String[]]$QAInfo.NIC = (Get-WmiObject -ComputerName $ServerName Win32_NetworkAdapterConfiguration -Namespace "root\CIMV2" | 
                                      Where{$_.IPEnabled -eq $True}).ServiceName | Ft -HideTableHeaders | Out-String          
                      
                      $QAInfo.IPv4 = (Get-WmiObject -ComputerName $ServerName Win32_NetworkAdapterConfiguration -Namespace "root\CIMV2" | 
                                      Where{$_.IPEnabled -eq $True}).IpAddress[0]
                              $HDS = $null
                              $HDS = Get-WMIObject -ComputerName $ServerName -ClassName Win32_LogicalDisk | 
                                        Where-Object {$_.DeviceID -like "C:"}| 
                                        Select -Property Size | Ft -HideTableHeaders | Out-String
                              $HDS = ([Math]::round($HDS / 1GB,0)).ToString()
            [String[]]$QAInfo.HDDSize = $HDS + "GB"
                              $UT = $null
                              $UT = Get-WMIObject -ComputerName $ServerName -ClassName Win32_OperatingSystem | select LastBootUpTime
                              $UT = ([Management.ManagementDateTimeConverter]::ToDateTime($UT.LastBootUpTime))
                              $UT = ((New-TimeSpan -Start $UT -End (Get-Date).DateTime))
            [String[]]$QAInfo.Uptime = $UT.DAys.ToString() + ":" + $UT.Hours.ToString() + ":" + $UT.Minutes.ToString()
            [String[]]$QAInfo.VMVersion = Get-VMVersion -ServerName $ServerName | Out-String
            [String[]]$QAInfo.VMTools = Get-VMTools -ServerName $ServerName | Out-String
            [String[]]$QAInfo.VMSerial = (Get-WmiObject -class Win32_BIOS).SerialNumber | Out-String
}


# Checks for two different IE versions depending on Silo
Function Get-IEVersion {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName)
$IEVer = Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer'} | 
               Select -Property Version | Ft -HideTableHeaders | Out-String
[String]$IEVer = $IEVer.Trim()
IF (([String]$IEVer -like "9.0.8112.16421") -OR ($ServerName -like "*IE8Silo*" -and [String]$IEVer -like "8.0.7601.17514")){
 Return "$IEVer OK"
 }
 ElseIf (($IEVer -like "9.10.9200*") -or ($IEVer -like "9.11.9600.17280")) { #IE10 & 11 moved reg key version number is stored in
$IEVer = Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-ItemProperty 'HKLM:\Software\Microsoft\Internet Explorer'} |
                Select -Property svcVersion | Ft -HideTableHeaders | Out-String }
[String]$IEVer = $IEVer.Trim()
Return "$IEVer Wrong version"
 Else{
 Return "$IEVer Wrong version"
 }
                       }


# Checks for exclusive KB patches from Microsoft
Function Get-KB {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName,
      [Parameter(Mandatory=$True)][String]$KBNum
      )
If ((Get-HotFix -ComputerName $ServerName -ID $KBNum -ErrorAction SilentlyContinue) -eq $null){
$KBResult = $null
$KBResult = New-Object psobject | 
Add-Member -type NoteProperty -Name Installed -Value "Not Installed" -PassThru | 
Add-Member -type NoteProperty -Name KBNum -Value $KBNum -PassThru 
return $KBResult
}
Else{
$KBResult = $null
$KBResult = New-Object psobject | 
Add-Member -Type NoteProperty -Name Installed -Value "Installed" -PassThru | 
Add-Member -Type NoteProperty -Name KBNum -Value $KBNum -PassThru
return $KBResult   
    }
}


# Used to check for the existence of required services
Function Get-Services {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName,
      [Parameter(Mandatory=$True)][String]$Service
)
IF ((Get-Service -ComputerName $ServerName -ServiceName $Service -ErrorAction SilentlyContinue) -eq $null){
Return "Not Installed"}
Else{
Return "Installed"
    }
}

# Used to check farm members for required patch level
Function Get-CtxPatch {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName,
      [Parameter(Mandatory=$true)][String]$CtxKB
)
IF ((Get-XAServerHotfix -ServerName $ServerName | Where-Object {$_.HotfixName -like $CtxKB}) -eq $null){
$KBResult = New-Object psobject | 
Add-Member -type NoteProperty -Name Installed -Value "Not Installed" -PassThru | 
Add-Member -type NoteProperty -Name KBNum -Value $CtxKB -PassThru
return $KBResult
}
Else{
$KBResult = New-Object psobject | 
Add-Member -Type NoteProperty -Name Installed -Value "Installed" -PassThru | 
Add-Member -Type NoteProperty -Name KBNum -Value $CtxKB -PassThru
return $KBResult
    }
}

# Checks computer account (adds) for WSUS membership for proper patching
Function Get-WSUSMembership {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName
      )
IF ((Get-ADGroupMember 'WSUS - Group - 1' -Recursive | Where-Object {$_.Name -eq $ServerName} -ErrorAction SilentlyContinue)  -eq $Null){
Return "Please make $ServerName a member of WSUS - Group - 1"}
Else {
Return "WSUS - Group - 1: Membership OK"
    }
}

# function to make email easier (tailor to your environment)
Function Send-QA-Email{
[CmdletBinding()]
Param (
      
      [String]$SMTPSrv = "smtp.company.com",
      [Parameter(Mandatory=$True)][String]$ServerName,
      [String]$From = "SendAs@company.com",
      [Parameter(Mandatory=$True)][String]$To = "ReceiveAs@company.com",
      [String]$Subject = "Server QA Report: " + $ServerName,
      [Parameter(Mandatory=$True)][String]$Body
      )
    Send-MailMessage -SmtpServer $SMTPSrv -From $From -To $To -Subject $Subject -BodyAsHtml $Body
}

# Simple logic for checking odd/even integers (very useful if odd/even servers have differing configurations)
Function Check-Even {
[CmdletBinding()]
param (
      [Parameter(Mandatory=$True)][Int]$int
)
[bool]!($int%2)
}

# function for getting VM hardware version from ESXi environment (contains logic for DR vs. PRD environments)
Function Get-VMVersion {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName
)
Add-PSSnapin Vmware* -ErrorAction SilentlyContinue
IF ($ServerName -like "*DR*"){
$null = Connect-VIServer -Server dr.vcenter.net
                               }
Else{
$null = Connect-VIServer -Server prd.vcenter.net
    }
$VMV = (Get-VM -Name $ServerName).Version
$null = Disconnect-VIServer -Confirm:$false
Return $VMV
                        }

# Function checks for vmtools version if VM (contains logic for DR vs. PRD env)
Function Get-VMTools {
[CmdletBinding()]
Param (
      [Parameter(Mandatory=$True)][String]$ServerName
)
Add-PSSnapin Vmware* -ErrorAction SilentlyContinue
IF ($ServerName -like "*DR*"){
$null = Connect-VIServer -Server dr.vcenter.net
                               }
Else{
$null = Connect-VIServer -Server prd.vcenter.net
    }
$null = New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force
$VMTools = (Get-VM -Name $ServerName).ToolsVersion
$null = Disconnect-VIServer -Confirm:$false
Return $VMTools
                     }
					 
# function for MySQL DB connection (REQUIRES MySQL .net classes to be installed on script host)					 
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

# function for MySQL DB queries (REQUIRES MySQL .net classes to be installed on script host)	
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

# pretty self explanatory (found on stack exchange, well documented below)
Function ConvertTo-HashTable {
[cmdletbinding()]

Param(
[Parameter(Position=0,Mandatory=$True,
HelpMessage="Please specify an object",ValueFromPipeline=$True)]
[ValidateNotNullorEmpty()]
[object]$InputObject,
[switch]$NoEmpty,
[string[]]$Exclude
)

Process {
    #get type using the [Type] class because deserialized objects won't have
    #a GetType() method which is what we would normally use.

    $TypeName = [system.type]::GetTypeArray($InputObject).name
    Write-Verbose "Converting an object of type $TypeName"
    
    #get property names using Get-Member
    $names = $InputObject | Get-Member -MemberType properties | 
    Select-Object -ExpandProperty name 

    #define an empty hash table
    $hash = @{}
    
    #go through the list of names and add each property and value to the hash table
    $names | ForEach-Object {
        #only add properties that haven't been excluded
        if ($Exclude -notcontains $_) {
            #only add if -NoEmpty is not called and property has a value
            if ($NoEmpty -AND -Not ($inputobject.$_)) {
                Write-Verbose "Skipping $_ as empty"
            }
            else {
                Write-Verbose "Adding property $_"
                $hash.Add($_,$inputobject.$_)
        }
        } #if exclude notcontains
        else {
            Write-Verbose "Excluding $_"
        }
    } #foreach
        Write-Verbose "Writing the result to the pipeline"
        Write-Output $hash
 }#close process

}#end function	  