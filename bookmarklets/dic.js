javascript:{
    var d = document;
    var w = d.getSelection().toString();
    var s = d.createElement('script');
    function cb(j) {
	d.body.removeChild(s);
	alert(((j.length == 0) ? w + 'は見つかりませんでした' : j));
    }
    if (w.length == 0) {
	var fs = window.frames;
	for (var i = 0; (i < fs.length) && (w.length == 0); i++) {
	    if (fs[i].getSelection != null)
		w = fs[i].getSelection().toString();
	}
	console.log(w.length);
	if (w.length == 0) w = prompt('単語を入力');
    }
    if (w != null) {
	s.type = 'text/javascript';
	s.src = 'http://safari-park.heroku.com/dic/search?Word=' +
	    w.replace(/^\s+/, '').replace(/\s+$/, '') + 
	    '&_callback=cb&twitter_id=<screen_name>';
	d.body.appendChild(s);
    }
}
