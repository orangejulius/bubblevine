var bubblevine = function(element, username) {
	$.get('/photo', function(responseText) {
		element.style.background = 'url(' + responseText + ')';
	});
	var channel = pusher.subscribe('my-channel');
	channel.bind('my-event', function(data) {
			alert('Received my-event with message: ' + data.message);
	});
};
