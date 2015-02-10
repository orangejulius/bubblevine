var set_bg_image = function(element, img_url) {
	var img = new Image();
	img.onload = function() {
		element.style.background  = 'url(' + this.src + ')';
		element.style.backgroundSize = '100%';
	};
	img.src = img_url;
};

var bubblevine = function(element, username) {
	username = username.toString();
	$.get('/photo?user_id=' + username, function(responseText) {
		set_bg_image(element, responseText);
	});
	var pusher = new Pusher('f900b3878046db16af98'),
	channel = pusher.subscribe(username);
	channel.bind('new-photo', function(data) {
		set_bg_image(element, data.message);
	});
};
