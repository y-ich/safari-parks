javascript:{
    var d = document;
    var w = d.getSelection().toString();
    var s = d.createElement('script');
    function cb(j) {
	d.body.removeChild(s);
	alert(((j.length == 0) ? w + 'は見つかりませんでした' : j))
    }
    if (w.length == 0) {
	w = prompt('単語を入力');
	if (w == null) return
    }
    s.type = 'text/javascript';
    s.src = 'http://safari-parks.heroku.com/dic?Word=' +
	w.replace(/^\s+/, '').replace(/\s+$/, '') + 
	'&_callback=cb';
    d.body.appendChild(s)
}
