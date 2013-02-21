var bubblevine = function(element, username) {
	$.get('/create_realtime_subscription?user_id='+username);
	$.get('/photo?user_id='+username, function(responseText) {
		element.style.background = 'url(' + responseText + ')';
	});
	var pusher = new Pusher('ce71ccbe68d44c4b14c7');
	var channel = pusher.subscribe(username);
	channel.bind('new-photo', function(data) {
			element.style.background = 'url(' + data.message + ')';
	});
};
