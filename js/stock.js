$(document).ready(function() {
	$('#predict-button').click(function() {
		var previous = $('#previous').val();
		var future = $('#future').val();
		var symbol = $('#symbol').val();
		var url = "stock.pl?symbol="+symbol+"&previous="+previous+"&future="+future+"&type=future";
		var currentheight = $('#future-div').height();
		$('#future-div').height(currentheight);
		$('#future-plot').fadeOut(300, function() {
			$(this).attr('src', url).bind('onreadystatechange load', function(){
				if (this.complete) $(this).fadeIn(300);
			});
		});
	});
	$('#submit-button').click(function() {
		var start = $('#start').val();
		var end = $('#end').val();
		var symbol = $('#symbol').val();
		var url = "stock.pl?symbol="+symbol+"&start="+start+"&end="+end+"&type=past";
		var currentheight = $('#past-div').height();
		$('#past-div').height(currentheight);
		$('#past-plot').fadeOut(300, function() {
			$(this).attr('src', url).bind('onreadystatechange load', function(){
				if (this.complete) $(this).fadeIn(300);
			});
		});
	});	
});	