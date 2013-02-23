var bubblevine = function(element, username) {
	username = username.toString();
	$.get('/create_realtime_subscription?user_id='+username);
	$.get('/photo?user_id='+username, function(responseText) {
		set_bg_image(element, responseText);
	});
	var pusher = new Pusher('ce71ccbe68d44c4b14c7');
	var channel = pusher.subscribe(username);
	channel.bind('new-photo', function(data) {
		set_bg_image(element, data.message);
	});
};

var set_bg_image = function(element, img_url) {
	var img = new Image();
	img.onload = function() {
		element.style.background  = 'url(' +this.src +')';
		element.style.backgroundSize = '100%';
	};
	img.src = img_url;
};
