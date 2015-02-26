<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
</head>
<body>
<?php
$con=mysqli_connect("127.0.0.1","dbuser","dbpass");mysqli_select_db($con,"farm_monitor");

// Connection test

if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }


 $hwinfo = mysqli_query($con,"SELECT * FROM hardware_info");
 
?>
<div id="pager2" class="pager2" align="center">
  <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="20">20</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
<table id="tables3" border =1 class="t1">
	<thead>
	<tr>
	<th>Hostname</th>
	<th>IPv4 Address</th>
	<th>CPU Count</th>
	<th>Total RAM</th>
	<th>Total Disk Space</th>
	<th>NIC Type</th>
	<th>VMTools Version</th>
	<th>VM HW Version</th>
	<th>VM Serial #</th>
	</tr>
	</thead>
	<tbody>
		<?php
		while($row = mysqli_fetch_array($hwinfo))
	{
		echo "<tr>";
		echo "<td>" . $row['hostname'] . "</td>";
		echo "<td>" . $row['ip'] . "</td>";
		echo "<td>" . $row['cpu'] . "</td>";
		echo "<td>" . $row['ram'] . "</td>";
		echo "<td>" . $row['hdd'] . "</td>";
		if(preg_match ("/vmxnet3ndis6/i",$row['nictype'])) {
		echo "<td>" . $row['nictype'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['nictype'] . "</td>";
		}
		if(preg_match ("/9349/i",$row['vmtools'])) {
		echo "<td>" . $row['vmtools'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['vmtools'] . "</td>";
		}
		if(preg_match ("/v10/i",$row['vmversion'])) {
		echo "<td>" . $row['vmversion'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['vmversion'] . "</td>";
		}
		echo "<td>" . $row['vmserial'] . "</td>";
		echo "</tr>";
		
	}
		?>
	</tbody>
	</table>
	   <div id="pager2" class="pager2" align="center">
  <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="20">20</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
	<script>
  $(function(){
  $('#tables3').tablesorter({widthFixed: true,
                            widgets: ['pager'],
							widgetOptions: {pager_size: 20,
											pager_selectors: {
											container   : '.pager2',       
											first       : '.first',       
											prev        : '.prev',        
											next        : '.next',        
											last        : '.last',        
											goto        : '.gotoPage',    
											pageDisplay : '.pagedisplay', 
											pageSize    : '.pagesize'
											}
						    
											}
							})})
  </script>
  <script>
   function moveScroll(){
    var scroll = $(window).scrollTop();
    var anchor_top = $("#tables3").offset().top;
    var anchor_bottom = $("#bottom_anchor2").offset().top;
    if (scroll>anchor_top && scroll<anchor_bottom) {
    clone_table = $("#clone");
    if(clone_table.length == 0){
        clone_table = $("#tables3").clone();
        clone_table.attr('id', 'clone');
        clone_table.css({position:'fixed',
                 'pointer-events': 'none',
                 top:0});
        clone_table.width($("#tables3").width());
        $("#tables3").append(clone_table);
        $("#clone").css({visibility:'hidden'});
        $("#clone thead").css({visibility:'visible', 'pointer-events':'auto'});
    }
    } else {
    $("#clone").remove();
    }
}
$(window).scroll(moveScroll);
  </script>
  <div id="bottom_anchor2"></div>
</body>
</html>