javascript:{
    var d = document;
    var w = d.getSelection().toString();
    var s = d.createElement('script');
    function cb(o) {
		d.body.removeChild(s);
		if (o.text.length) {
			alert(o.text);
			window.sp_pronounce = o.wav_us;
		}
		else {
			alert(w + 'は見つかりませんでした');
		}
    }
    if (w.length == 0) {
	var fs = window.frames;
	for (var i = 0; (i < fs.length) && (w.length == 0); i++) {
	    if (fs[i].getSelection != null)
		w = fs[i].getSelection().toString();
	}
	if (w.length == 0) w = prompt('単語を入力');
    }
    if (w != null) {
	s.type = 'text/javascript';
	s.src = 'http://safari-park.herokuapp.com/dic/search?Word=' +
/*	s.src = 'http://192.168.1.8:9292/dic/search?Word=' + */
	    w.replace(/^\s+/, '').replace(/\s+$/, '') + 
	    '&_callback=cb&twitter_id=&v=2';
	d.body.appendChild(s);
    }
}
