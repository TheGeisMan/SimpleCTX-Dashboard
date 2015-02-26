<!doctype html>
<html lang="en">
<body>
<?php
// Execute powershell: flushes netscaler table and retrieves fresh metrics from Nitro
// 
// This script refreshes Netscaler metrics on every doc load
system('powershell.exe -file Path:\to\netscaler_mon.ps1 > NUL');


$con=mysqli_connect("127.0.0.1","dbuser","dbpass");mysqli_select_db($con,"farm_monitor");

// Connection test

if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }


 $nsinfo = mysqli_query($con,"SELECT * FROM netscaler_info");
 $vsinfo = mysqli_query($con,"SELECT * FROM vserver_info");
 $crtinfo = mysqli_query($con,"SELECT * FROM sslcert_info");
 ?>
 
<table id="tables6" border =1 class="t1">
	<center><h3>System Information</h3></center>
	<thead>
	<tr>
	<th>Active Node</th>
	<th>VPN Sessions</th>
	<th>Internet RX Rate</th>
	<th>Internet TX Rate</th>
	<th>Successful Logins</th>
	<th>Unsuccessful Logins</th>
	<th>Available Flash</th>
	<th>Available HDD</th>
	<th>Packet CPU %</th>
	<th>Management CPU %</th>
	<th>Available RAM %</th>
	<th>SSL Card Health</th>
	<th>PSU 1 Health</th>
	<th>PSU 2 Health</th>
	</tr>
	</thead>
	<tbody>
		<?php
		while($row = mysqli_fetch_array($nsinfo))
	{
		echo "<tr>";
		if ($row['active_node'] == "SHY") {
		echo '<td><br><a href="https://nsprdshy.dmz.upmc.edu" target="_blank">' . $row['active_node'] . "</a></td>";
		}else{
		echo '<td><br><a href="https://nsprdft.dmz.upmc.edu" target="_blank">' . $row['active_node'] . "</a></td>";
		}
		echo "<td><br>" . $row['current_aaa'] . "</td>";
		echo "<td><br>" . (round((($row['inetrx']*8)/1048576),2) . "Mbps</td>");
		echo "<td><br>" . (round((($row['inettx']*8)/1048576),2) . "Mbps</td>");
		echo "<td><br>" . $row['auth_success'] . "</td>";
		echo "<td><br>" . $row['auth_fail'] . "</td>";
		echo "<td><br>" . (round(($row['flash_avail']/1024),2) . "GB</td>");
		echo "<td><br>" . (round(($row['hdd_avail']/1024),2) . "GB</td>");
		echo "<td><br>" . (round($row['pkt_cpu'],2) . "%</td>");
		echo "<td><br>" . (round($row['mgmt_cpu'],2) . "%</td>");
		echo "<td><br>" . (round((100 - $row['ram_avail']),2) . "%</td>");
		echo "<td><br>" . 100/$row['sslcard_health'] . "%</td>";
		echo "<td><br>" . $row['psu1stat'] . "</td>";
		echo "<td><br>" . $row['psu2stat'] . "</td>";
		echo "</tr>";
		
	}
		?>
	</tbody>
	</table>
	<br>
	<div id="wrapper">
	<div id="row">
	<div id="first">
	<table id="tables5" border="1" class="t1">
	<center><h3>vServer Stats</h3></center>
		<thead>
			<tr>
			<th>vServer Name</th>
			<th>vServer IP</th>
			<th>% Nodes Available</th>
			<th>State</th>
			<th>Hits</th>
		</thead>
		<tbody>
		<?php
		while($row = mysqli_fetch_array($vsinfo))
		{
		echo "<tr>";
		echo "<td>" . $row['vserver'] . "</td>";
		echo "<td>" . $row['vserver_ip'] . "</td>";
		echo "<td>" . $row['vserver_health'] . "</td>";
		echo "<td>" . $row['vserver_state'] . "</td>";
		echo "<td>" . $row['vserver_hits'] . "</td>";
		echo "</tr>";
		
	}
		?>
	</tbody>
	</table>
	</div>
	<div id="third"></div>
	<div id="second">
	<table id="tables7" border =1 class="t1">
	<center><h3>Certificate Stats</h3></center>
		<thead>
			<tr>
			<th>Certificate Name</th>
			<th>Expiration Date</th>
			<th>Status</th>
		</thead>
		<tbody>
	<?php
	$Today=date('m-d-y');
		while($row = mysqli_fetch_array($crtinfo))
		{
		echo "<tr>";
		echo "<td>" . $row['certname'] . "</td>";
		echo "<td>" . date('m-d-Y' , strtotime("+" . $row['expirydate'] . "days") . "</td>");
		echo "<td>" . $row['status'] . "</td>";
		echo "</tr>";
		}
		?>
	</tbody>
	</table>
	</div>
	</div>
	</div>
 <script>
 $(document).ready(function(){
  $('#tables5').tablesorter({widthFixed: false,
							 sortList: [[0,0]]
  })
  $('#tables7').tablesorter({widthFixed: false,
							 sortList: [[1,0]]
  })
 })
 </script>
  <div id="bottom_anchor2"></div>
</body>
</html>