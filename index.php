<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Server QA Dashboard</title>
  <link rel="icon" type="image/x-icon" href="favicon.ico" />
  <link rel="stylesheet" href="css/jqueryui.css">
  <link rel="stylesheet" href="css/page.css">
  <script src="js/jquery-1.10.2.min.js"></script>
  <script src="js/jquery-ui.min.js"></script>
  <script src="js/newTS/jquery.tablesorter.min.js"></script>
  <script src="js/newTS/jquery.tablesorter.widgets.min.js"></script>
  <script src="js/newTS/widget-pager.js"></script>
  <script src="js/jquery.flot.js"></script>
  <script src="js/jquery.csv.min.js"></script>
  <script>
  $(function() {
    $( "#tabs" ).tabs({
      beforeLoad: function( event, ui ) {
        ui.jqXHR.error(function() {
          ui.panel.html(
            "Unable to load tab, bad PHP/JS syntax." );
        });
      }
    });
  });
</script>
</head>
<body>
<div id="banner">
<img src="logo.png"></img><h1>Citrix XA6.5 PRD<br>QA Dashboard</h1>
</div>
 <?php
 header("X-Powered-By: TheGeisMan");
 session_start();
 
$con=mysqli_connect("127.0.0.1","dbuser","dbpass");mysqli_select_db($con,"farm_monitor");

// Connection test

if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

 $sysinfo = mysqli_query($con,"SELECT * FROM system_info");
 
?>

<div id="tabs">
 
   <ul>
    <li><a href="#tabs-1">System Info</a></li>
    <li><a id="#tab2" href="hwinfo.php">Hardware Info</a></li>
    <li><a id="#tab3" href="ctxinfo.php">Citrix Info</a></li>
    <li><a id="#tab4" href="swinfo.php">Software Checks</a></li>
	<li><a id="#tab5" href="nsinfo.php">Netscaler Dash</a></li>
   </ul>
  <div id="tabs-1">
	<div id="pager" class="pager" align="center">
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
    <table id="tables" border=1 class="t1" data-sortlist="[[3,1]]">
	<thead>
	<tr>
	<th>Hostname</th>
	<th>Domain</th>
	<th>Operating System</th>
	<th>System Uptime <br> (D:H:M)</th>
	</tr>
	</thead>
	 	<tbody>
			<?php
			$cputh = 85;
			$ramth = 1024;
			$hddth = 10;
			while($row = mysqli_fetch_array($sysinfo))
	{
		echo "<tr>";
		echo "<td>" . $row['hostname'] . "</td>";
		echo "<td>" . $row['domain'] . "</td>";
		echo "<td>" . $row['os_ver'] . "</td>";
		echo "<td>" . $row['uptime'] . "</td>";
		echo "</tr>";
	}
			?>
  </tbody>
  </table>
  <div id="pager" class="pager" align="center">
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
  $(document).ready(function(){
  $('#tables').tablesorter({widthFixed: true,
							sortList: [[3,1]],
                            widgets: ['pager'],
							widgetOptions: {pager_size: 20,
											pager_selectors: {
											container   : '.pager',       
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
    var anchor_top = $("#tables").offset().top;
    var anchor_bottom = $("#bottom_anchor").offset().top;
    if (scroll>anchor_top && scroll<anchor_bottom) {
    clone_table = $("#clone");
    if(clone_table.length == 0){
        clone_table = $("#tables").clone();
        clone_table.attr('id', 'clone');
        clone_table.css({position:'fixed',
                 'pointer-events': 'none',
                 top:0});
        clone_table.width($("#tables").width());
        $("#tables").append(clone_table);
        $("#clone").css({visibility:'hidden'});
        $("#clone thead").css({visibility:'visible', 'pointer-events':'auto'});
    }
    } else {
    $("#clone").remove();
    }
}
$(window).scroll(moveScroll);
  </script>
  <div id="bottom_anchor"></div>
</body>
</html>