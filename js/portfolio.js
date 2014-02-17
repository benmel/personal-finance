$(document).ready(function() {
	function getportfolio() {
		var portfolio = $('#portfolio').val();
		if (portfolio !== "select holder") {
			var url = "portfolio.pl?act=base&run=1&portfolio=" + portfolio;
			$.get(url, function(data) {
  				var new_portfolio = $(data).find('#portfolio-info').html();
  				$('#portfolio-info').html(new_portfolio);
  				$('#current-portfolio').val(portfolio);
			});
		}
	}
	
	getportfolio();
	
	$('#portfolio').change(function() {
		getportfolio();
	});
	$('#portfolio-button').click(function() {
		var value = $('#portfolio-name').val();
		$('#portfolio-name').val('');
		var url = "portfolio.pl?act=newportfolio&run=1&portfolio=" + value;
		$.get(url, function(data) {
  			var new_select = $(data).find('#portfolio').html();
  			$('#portfolio').html(new_select);
		});
	});
	$('.row').on('click','#deposit-button',function() {
		var value = $('#deposit-input').val();
		$('#deposit-input').val('');
		var portfolio = $('#current-portfolio').val();
		var url = "portfolio.pl?act=deposit&run=1&deposit=" + value + "&portfolio=" + portfolio;
		$.get(url, function(data) {
  			var new_balance = $(data).find('#balance').text();
  			$('#balance').text(new_balance);
		});
	});
	$('.row').on('click','#withdraw-button',function() {
		var value = $('#withdraw-input').val();
		$('#withdraw-input').val('');
		var portfolio = $('#current-portfolio').val();
		var url = "portfolio.pl?act=withdraw&run=1&withdraw=" + value + "&portfolio=" + portfolio;
		$.get(url, function(data) {
  			var new_balance = $(data).find('#balance').text();
  			$('#balance').text(new_balance);
		});
	});
	$('.row').on('click','#buy-button',function() {
		var symbol = $('#buy-symbol').val();
		var quantity = $('#buy-quantity').val();
		$('#buy-symbol').val('');
		$('#buy-quantity').val('');
		var portfolio = $('#current-portfolio').val();
		var url = "portfolio.pl?act=buy&run=1&symbol=" + symbol + "&quantity=" + quantity + "&portfolio=" + portfolio;
		$.get(url, function(data) {
  			var new_portfolio = $(data).find('#portfolio-info').html();
  			$('#portfolio-info').html(new_portfolio);
		});
	});
	$('.row').on('click','#sell-button',function() {
		var symbol = $('#sell-symbol').val();
		var quantity = $('#sell-quantity').val();
		$('#sell-symbol').val('');
		$('#sell-quantity').val('');
		var portfolio = $('#current-portfolio').val();
		var url = "portfolio.pl?act=sell&run=1&symbol=" + symbol + "&quantity=" + quantity + "&portfolio=" + portfolio;
		$.get(url, function(data) {
  			var new_portfolio = $(data).find('#portfolio-info').html();
  			$('#portfolio-info').html(new_portfolio);
		});
	});
	$('.row').on('click','#new-button',function() {
		var symbol = $('#new-symbol').val();
		var open = $('#open-price').val();
		var close = $('#close-price').val();
		var low = $('#low-price').val();
		var high = $('#high-price').val();
		var volume = $('#volume').val();
		var portfolio = $('#current-portfolio').val();
		var timestamp = $('#timestamp').val();
		$('#new-symbol').val('');
		$('#open-price').val('');
		$('#close-price').val('');
		$('#low-price').val('');
		$('#high-price').val('');
		$('#volume').val('');
		var url = "portfolio.pl?act=new&run=1&symbol=" + symbol + "&open=" + open + "&close=" + close + "&low=" + low + "&high=" + high + "&volume=" + volume + "&timestamp=" + timestamp + "&portfolio=" + portfolio;
		$.get(url, function(data) {
			var new_tbody = $(data).find('#stocks-table > tbody').html();
  			$('#stocks-table > tbody').html(new_tbody);
		});
	});
	$('.row').on('click','#auto-button',function() {
		var symbol = $('#auto-symbol :selected').val();
		var start = $('#start-date').val();
		var end = $('#end-date').val();
		var amount = $('#auto-amount').val();
		var tradingcost = $('#trading-cost').val();
		var url = "stock.pl?type=auto&symbol="+symbol+"&start="+start+"&end="+end+"&amount="+amount+"&tradingcost="+tradingcost;
		$.get(url, function(data) {
  			var results = $(data).find('#results').html();
  			$('#auto-stats').html(results);
		});
	});
	$('.row').on('click','#cov-button',function() {
		var symbol1 = $('#symbol1').val();
		var symbol2 = $('#symbol2').val();
		var url = "stock.pl?type=cov&symbol1="+symbol1+"&symbol2="+symbol2;
		window.location = url;
	});
	/*
	$('.row').on('click','#cov-button',function() {
		if (!($('#covariance').is(":visible"))) {
			var stocks = Array();
			$('#stocks-table td:first-child').each(function() {
				stocks.push($(this).text());
			});
			for (var i = 0; i < stocks.length; i++) {
				for (var j = 0; j < stocks.length; j++) {
					if (i==j) {
						continue;
					}
					var url = "stock.pl?type=cov&symbol1="+stocks[i]+"&symbol2="+stocks[j];
					$.get(url, function(data) {
  						$(data).find('#results').appendTo($('#cov-data'));
					});
				}
			}
		}	
		$('#covariance').toggle();
	});
*/

});

