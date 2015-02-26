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


 $ctxinfo = mysqli_query($con,"SELECT * FROM ctx_info");
// $farminfo = mysqli_query($con,"SELECT * FROM farm_info");
 ?>
 
<div id="pager3" class="pager3" align="center">
  <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="12">12</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
<table id="tables2" border =1 class="t1">
    <thead>
	<tr>
	<th>Hostname</th>
	<th>Citrix Version</th>
	<th>Install Date</th>
	<th>Zone</th>
	<th>Worker Group</th>
	<th>Load Evaluator</th>
	<th>Farm Folder Path</th>
	<th>XA650W2K8R2X64R04</th>
	</tr>
	</thead>
	<tbody>
		<?php
		$ctxth = 10000;
		while($row = mysqli_fetch_array($ctxinfo))
	{
		echo "<tr>";
		echo "<td>" . $row['hostname'] . "</td>";
		echo "<td>" . $row['ctxversion'] . "</td>";
		echo "<td>" . $row['installdate'] . "</td>";
		if(((fnmatch('CX*-SV*',$row['hostname']) && ($row['zone'] == 'SHY')) || (fnmatch('CX*-FV*',$row['hostname']) && ($row['zone'] == 'FBT')))) {
		echo "<td>" . $row['zone'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['zone'] . "</td>";
		}
		echo "<td>" . $row['wg'] . "</td>";
		echo "<td>" . $row['le'] . "</td>";
		echo "<td>" . $row['folderpath'] . "</td>";
		if(preg_match ("/not/i",$row['r03'])) {
		echo "<td bgcolor='#FF0000'>" . $row['r03'] . "</td>";
		} else {
		echo "<td>" . $row['r03'] . "</td>";
		}
		echo "</tr>";
	}
		?>
	</tbody>
	</table>
<div id="pager3" class="pager3" align="center">
  <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="12">12</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
	<script>
  $(function(){
  $('#tables2').tablesorter({widthFixed: true,
                            widgets: ['pager'],
							widgetOptions: {pager_size: 12,
											pager_selectors: {
											container   : '.pager3',       
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
    var anchor_top = $("#tables2").offset().top;
    var anchor_bottom = $("#bottom_anchor3").offset().top;
    if (scroll>anchor_top && scroll<anchor_bottom) {
    clone_table = $("#clone");
    if(clone_table.length == 0){
        clone_table = $("#tables2").clone();
        clone_table.attr('id', 'clone');
        clone_table.css({position:'fixed',
                 'pointer-events': 'none',
                 top:0});
        clone_table.width($("#tables2").width());
        $("#tables2").append(clone_table);
        $("#clone").css({visibility:'hidden'});
        $("#clone thead").css({visibility:'visible', 'pointer-events':'auto'});
    }
    } else {
    $("#clone").remove();
    }
}
$(window).scroll(moveScroll);
  </script>
  <div id="bottom_anchor3"></div>
</body>
</html>