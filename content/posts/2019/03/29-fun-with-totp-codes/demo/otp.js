function updateCodes() {
	$('div[data-token]').each(function() {
		var algo = $(this).attr('data-algo');
		var token = $(this).attr('data-token');
		var period = $(this).attr('data-period');

		if (algo === false || algo === undefined) { algo = 'SHA1'; }
		if (period === false || period === undefined) { period = 30; }

		var time = Math.round(new Date().getTime() / 1000.0)
		var updating = period - (time % period);

		$('progress', $(this)).attr('value', updating);
		$('progress', $(this)).attr('max', period);
		$('span.seconds', $(this)).text(updating);

		var totp = new OTPAuth.TOTP({
			label: token + ' - ' + algo,
			algorithm: algo,
			digits: 6,
			period: period,
			secret: OTPAuth.Secret.fromB32(token)
		});

		var qrDiv = $('div.qr', $(this));

		if (qrDiv.attr('data-qr') === false || qrDiv.attr('data-qr') === undefined) {
			$('h3', $(this)).text(token + ' - ' + algo);
			qrDiv.qrcode({width: 200, height: 200, text: totp.toString()});

			qrDiv.attr('data-qr', totp.toString());
		}

		$('span.code', $(this)).text(totp.generate({'timestamp': time * 1000}));
	});
}


// We need to wait for jquery to load later in the page...
function defer(method) {
	if (window.jQuery) {
		method();
	} else {
		setTimeout(function() { defer(method) }, 50);
	}
}

// Horrible code to load our js files..
defer(function() {
	$(function() {
		$.getScript("otpauth.min.js").done(function() {
			$.getScript("qrcode.js").done(function() {
				$.getScript("jquery.qrcode.js").done(function() {
					updateCodes();
					setInterval(updateCodes, 1000);
				});
			});
		});
	});
});
