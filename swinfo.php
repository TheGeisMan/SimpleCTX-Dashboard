<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
</head>
<body>
<?php
session_start();
$con=mysqli_connect("127.0.0.1","dbuser","dbpass");mysqli_select_db($con,"farm_monitor");

// Connection test

if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }


 $swinfo = mysqli_query($con,"SELECT * FROM software_info");
 
?>
	  <div id="pager4" class="pager4" align="center">
   <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="7">7</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
<table id="tables4" border =1 class="t1">
	<thead>
	<tr class="sortable-row">
	<th>Hostname</th>
	<th>IE Version Check</th>
	<th>WSUS Group Check</th>
	<th>IMA Service Check</th>
	<th>KNTCMA Service Check</th>
	<th>TLM Agent Service Check</th>
	<th>Smart Auditor Service Check</th>
	<th>CCM Service Check</th>
	<th>KB2799035</th>
	<th>KB2878424</th>
	</tr>
	</thead>
	<tbody>
		<?php
		while($row = mysqli_fetch_array($swinfo))
	{
		echo "<tr>";
		echo "<td>" . $row['hostname'] . "</td>";
		
		if(preg_match ("/ok/i",$row['ieversion'])) {
		echo "<td>" . $row['ieversion'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['ieversion'] . "</td>";
		}
		
		if(preg_match ("/ok/i",$row['wsus'])) {
		echo "<td>" . $row['wsus'] . "</td>";
		} else {
		echo "<td bgcolor='#FF0000'>" . $row['wsus'] . "</td>";
		}
		
	    if(preg_match ("/not/i",$row['ima'])) {
		echo "<td bgcolor='#FF0000'>" . $row['ima'] . "</td>";
		} else {
		echo "<td>" . $row['ima'] . "</td>";
		}
		
		if(preg_match ("/not/i",$row['kntcma'])) {
		echo "<td bgcolor='#FF0000'>" . $row['kntcma'] . "</td>";
		} else {
		echo "<td>" . $row['kntcma'] . "</td>";
		}
		
		if(preg_match ("/not/i",$row['tlm'])) {
		echo "<td bgcolor='#FF0000'>" . $row['tlm'] . "</td>";
		} else {
		echo "<td>" . $row['tlm'] . "</td>";
		}
		if(preg_match ("/not installed/i",$row['smaud'])) {
		echo "<td bgcolor='#FF0000'>" . $row['smaud'] . "</td>";
		} else {
		echo "<td>" . $row['smaud'] . "</td>";
		}
		
		if(preg_match ("/not/i",$row['ccm'])) {
		echo "<td bgcolor='#FF0000'>" . $row['ccm'] . "</td>";
		} else {
		echo "<td>" . $row['ccm'] . "</td>";
		}
		
		if(preg_match ("/not/i",$row['kb2799035'])) {
		echo "<td bgcolor='#FF0000'>" . $row['kb2799035'] . "</td>";
		} else {
		echo "<td>" . $row['kb2799035'] . "</td>";
		}
		
		if(preg_match ("/not/i",$row['kb2878424'])) {
		echo "<td bgcolor='#FF0000'>" . $row['kb2878424'] . "</td>";
		} else {
		echo "<td>" . $row['kb2878424'] . "</td>";
		echo "</tr>";
		}
	}
		?>
	</tbody>
	</table>
	  <div id="pager4" class="pager4" align="center">
   <form>
			<img src="/images/first.png" class="first"/>
			<img src="/images/last.png" class="last"/>
			<span class="pagedisplay"></span>
			<img src="/images/prev.png" class="prev"/>
			<img src="/images/next.png" class="next"/>
			<select class="pagesize">
				<option selected="selected" value="7">7</option>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="2000">All</option>
			</select>
	</form>
</div>
	<script>
  $(function(){
  $('#tables4').tablesorter({widthFixed: true,
                            widgets: ['pager'],
							widgetOptions: {pager_size: 7,
											pager_selectors: {
											container   : '.pager4',       
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
    var anchor_top = $("#tables4").offset().top;
    var anchor_bottom = $("#bottom_anchor4").offset().top;
    if (scroll>anchor_top && scroll<anchor_bottom) {
    clone_table = $("#clone");
    if(clone_table.length == 0){
        clone_table = $("#tables4").clone();
        clone_table.attr('id', 'clone');
        clone_table.css({position:'fixed',
                 'pointer-events': 'none',
                 top:0});
        clone_table.width($("#tables4").width());
        $("#tables4").append(clone_table);
        $("#clone").css({visibility:'hidden'});
        $("#clone thead").css({visibility:'visible', 'pointer-events':'auto'});
    }
    } else {
    $("#clone").remove();
    }
}
$(window).scroll(moveScroll);
  </script>
  <div id="bottom_anchor4"></div>
</body>
</html>