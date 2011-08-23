javascript:{
    var d = document;
    var w = window;
    var e = d.createElement('button');
    function cb(j) {
	d.body.removeChild(d.getElementById('dic_jsonp'));
	alert((j.length ? j : (w + 'は見つかりませんでした')));
    }
    e.id = 'dicButton';
    e.type = 'button';
    e.style.position = 'absolute';
    e.appendChild(d.createTextNode('J->E'));
    e.onclick = function () {
	var w = d.getSelection().toString();
	var s = d.createElement('script');
	if (w.length == 0) {
	    var fs = window.frames;
	    for (var i = 0; (i < fs.length) && (w.length == 0); i++) {
		if (fs[i].getSelection != null)
		    w = fs[i].getSelection().toString();
	    }
	    if (w.length == 0) w = prompt('単語を入力');
	}
	if (w != null) {
	    s.id = 'dic_jsonp';
	    s.type = 'text/javascript';
	    s.src = 'http://safari-park.herokuapp.com/dic/search?Word=' +
		w.replace(/^\s+/, '').replace(/\s+$/, '') + 
		'&_callback=cb&twitter_id=';
	    d.body.appendChild(s);
	}
    };
    d.body.appendChild(e);
    w.onscroll = function () {
	var b = d.getElementById('dicButton');
	b.style.top = (w.pageYOffset + w.innerHeight - 24) + 'px';
	b.style.left = (w.pageXOffset + w.innerWidth - 56) + 'px';
    };
}
