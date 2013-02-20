var bubblevine = function(element, username) {
	$.get('/photo', function(responseText) {
		element.style.background = 'url(' + responseText + ')';
	});
	var pusher = new Pusher('ce71ccbe68d44c4b14c7');
	var channel = pusher.subscribe(username);
	channel.bind('new-photo', function(data) {
			alert('Received my-event with message: ' + data.message);
	});
};
