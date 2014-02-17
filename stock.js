$(document).ready(function() {
	$('#predict-button').click(function() {
		var previous = $('#previous').val();
		var future = $('#future').val();
		var symbol = $('#symbol').val();
		var url = "stock.pl?symbol="+symbol+"&previous="+previous+"&future="+future+"&type=future";
		$('#future-plot').html('<img src="'+url+'">');
		/*
		$.get(url, function(data) {
  			var img = $(data).find('img');
  			$('#future-plot').append(img);
		});
*/
	});
});	