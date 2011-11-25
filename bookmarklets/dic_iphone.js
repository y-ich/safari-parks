javascript:{
    var d = document;
    var wi = window;
    var e = d.createElement('button');
    function cb(o) {
		d.body.removeChild(d.getElementById('dic_jsonp'));
		if (o.text.length) {
			alert(o.text);
			window.sp_pronounce = o.wav_us;
		}
		else {
			alert(w + 'は見つかりませんでした');
		}
    }
    e.id = 'dicButton';
    e.type = 'button';
    e.style.position = 'absolute';
	e.style.top = (wi.pageYOffset + wi.innerHeight - 24) + 'px';
	e.style.left = (wi.pageXOffset + wi.innerWidth - 56) + 'px';
    e.appendChild(d.createTextNode('E->J'));
	e.ontouchstart = function () {
		wi.sp_t = new Date().getTime();
		wi.sp_w = d.getSelection().toString();
	};
    e.ontouchend = function () {
		if (new Date().getTime() - wi.sp_t < 500) {
			var w = wi.sp_w;
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
				s.src = 'SERVER_DOMAIN/dic/search?Word=' +
					w.replace(/^\s+/, '').replace(/\s+$/, '') + 
					'&_callback=cb&twitter_id=&v=2';
				d.body.appendChild(s);
			}
		}
		else {
			if (typeof window.sp_pronounce !== 'undefined' && window.sp_pronounce !== null)
				(new Audio(window.sp_pronounce)).play();
			else alert('先に単語を調べてください。');
		}			
    };
    d.body.appendChild(e);
    wi.addEventListener('scroll', function () {
							var b = d.getElementById('dicButton');
							b.style.top = (wi.pageYOffset + wi.innerHeight - 24) + 'px';
							b.style.left = (wi.pageXOffset + wi.innerWidth - 56) + 'px';
						}, false);
}
