var bubblevine = function(element) {
	$.get('/photo', function(responseText) {
		element.style.background = 'url(' + responseText + ')';
	});
};
